# Firebase Push Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire end-to-end FCM push notifications — FCM v1 API, Flutter tap-to-navigate, and daily meal reminder scheduling via pg_cron.

**Architecture:** A new shared Deno module (`_shared/fcm.ts`) handles OAuth2-signed FCM v1 calls; `send-push-notification` imports it directly. The Flutter side gains a top-level background handler and a `handleNotificationTap` router dispatcher. A new `send-meal-reminders` edge function is called by a daily pg_cron job at 07:00 UTC.

**Tech Stack:** Deno (Web Crypto API for RS256 JWT), Firebase Cloud Messaging v1 REST API, Flutter `firebase_messaging` 15.x, Riverpod `ProviderContainer` / `UncontrolledProviderScope`, go_router, Supabase pg_cron + net.http_post, Vault for secret storage.

**Section 1 status:** DONE — `firebase_options.dart` is real, Android app `com.akeli.nutrition` and iOS app `com.akeli.nutrition` are registered on `afro-health-oyks8y`.

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `supabase/functions/_shared/fcm.ts` | **Create** | RS256 JWT → OAuth2 token exchange → `sendFcmV1()` |
| `supabase/functions/send-push-notification/index.ts` | **Modify** | Replace legacy FCM fetch with `sendFcmV1`; delete stale token on 404 |
| `lib/core/notification_handler.dart` | **Create** | Top-level background handler + `handleNotificationTap()` |
| `lib/main.dart` | **Modify** | Register background handler, wire `getInitialMessage` + `onMessageOpenedApp` using shared `ProviderContainer` |
| `supabase/functions/send-meal-reminders/index.ts` | **Create** | Query today's meal plan entries, deduplicate by user, call `send-push-notification` for each |
| `supabase/migrations/20260602000004_register_meal_reminder_cron.sql` | **Create** | pg_cron job: `0 7 * * *` → `send-meal-reminders`, Vault-secured |
| `test/core/notification_handler_test.dart` | **Create** | Unit tests for `handleNotificationTap` routing logic |

---

## Task 1: FCM v1 Shared Module

**Files:**
- Create: `supabase/functions/_shared/fcm.ts`

### Background

FCM v1 requires a short-lived OAuth2 bearer token derived from a Google service account key (JSON). The Web Crypto API (native in Deno) signs an RS256 JWT which is exchanged for the access token. No external dependencies needed.

The service account JSON is stored in the `FIREBASE_SERVICE_ACCOUNT` Supabase secret. Download it from:
Firebase Console → Project Settings → Service Accounts → Generate new private key.

- [ ] **Step 1: Create `supabase/functions/_shared/fcm.ts`**

```typescript
// FCM v1 — OAuth2-signed push via service account (no external deps, uses Web Crypto)
const PROJECT_ID = "afro-health-oyks8y";
const FCM_ENDPOINT = `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`;
const TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token";
const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

interface ServiceAccount {
  client_email: string;
  private_key: string;
}

function base64url(input: string): string {
  return btoa(input).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

function base64urlBuffer(buffer: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(buffer)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

async function buildJwt(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64url(JSON.stringify({
    iss: sa.client_email,
    sub: sa.client_email,
    aud: TOKEN_ENDPOINT,
    iat: now,
    exp: now + 3600,
    scope: FCM_SCOPE,
  }));

  const pem = sa.private_key.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\n/g, "");
  const binaryDer = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signingInput = `${header}.${claims}`;
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );

  return `${signingInput}.${base64urlBuffer(signature)}`;
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const jwt = await buildJwt(sa);
  const res = await fetch(TOKEN_ENDPOINT, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`OAuth2 token exchange failed (${res.status}): ${text}`);
  }
  const json = await res.json();
  return json.access_token as string;
}

export interface FcmSendResult {
  ok: boolean;
  /** HTTP status from FCM — 404 means the token is stale */
  status: number;
}

/**
 * Send a push notification via FCM v1.
 * Returns { ok, status } so callers can act on 404 (stale token).
 */
export async function sendFcmV1(
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string> = {},
): Promise<FcmSendResult> {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT env var is not set");

  const sa: ServiceAccount = JSON.parse(raw);
  const accessToken = await getAccessToken(sa);

  const payload = {
    message: {
      token: fcmToken,
      notification: { title, body },
      data,
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    },
  };

  const res = await fetch(FCM_ENDPOINT, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  return { ok: res.ok, status: res.status };
}
```

- [ ] **Step 2: Commit**

```bash
git add supabase/functions/_shared/fcm.ts
git commit -m "feat(fcm): add FCM v1 shared module with RS256 JWT + OAuth2 token exchange"
```

---

## Task 2: Migrate `send-push-notification` to FCM v1

**Files:**
- Modify: `supabase/functions/send-push-notification/index.ts`

Changes:
- Remove `FCM_SERVER_KEY` and `FCM_URL` constants
- Import `sendFcmV1` from `../_shared/fcm.ts`
- Replace the legacy fetch block with `sendFcmV1`
- On FCM 404, delete the stale `push_token` row (token cleanup from spec)

- [ ] **Step 1: Replace `send-push-notification/index.ts`**

```typescript
// Appel interne uniquement (service key)
// Envoi de push notification FCM v1 + insert dans notification table
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, err, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";
import { sendFcmV1 } from "../_shared/fcm.ts";

serve(async (req) => {
  const logger = createLogger("send-push-notification");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    logger.debug("[STEP 1] Verify internal secret");
    if (!verifyInternalSecret(req)) {
      logger.warn("EARLY RETURN | reason: invalid internal secret");
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    logger.debug("[STEP 2] Parse body");
    const body = await req.json();
    const { user_id, title, body: notifBody, data = {}, type = "system" } = body;
    logger.debug("[STEP 2] Body parsed", { user_id, title, type });

    if (!user_id || !title) {
      logger.warn("EARLY RETURN | reason: missing user_id or title");
      return err("user_id and title are required");
    }

    const admin = serviceClient();

    logger.debug("[STEP 3] Get push token");
    logRLSCheck(logger, "push_token", "SELECT", user_id);
    const { data: pushToken, error: pushTokenError } = await admin
      .from("push_token")
      .select("token, platform")
      .eq("user_id", user_id)
      .order("updated_at", { ascending: false })
      .limit(1)
      .single();
    logQueryResult(logger, "push_token", "SELECT", pushToken?.token ? 1 : 0, pushTokenError ?? undefined);

    logger.debug("[STEP 4] Insert notification record");
    logRLSCheck(logger, "notification", "INSERT", user_id);
    const { error: notifInsertError } = await admin.from("notification").insert({
      user_id,
      type,
      title,
      body: notifBody,
      data,
    });
    logQueryResult(logger, "notification", "INSERT", notifInsertError ? 0 : 1, notifInsertError ?? undefined);

    if (pushToken?.token) {
      logger.debug("[STEP 5] Sending FCM v1 push | platform: " + (pushToken.platform ?? "unknown"));

      const fcmResult = await sendFcmV1(
        pushToken.token,
        title,
        notifBody ?? "",
        Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      );

      if (!fcmResult.ok) {
        logger.warn("FCM send failed | status: " + fcmResult.status + " | notification_inserted: true");

        // FCM 404 means the token is stale — clean it up
        if (fcmResult.status === 404) {
          logger.debug("[STEP 5b] Deleting stale push token");
          logRLSCheck(logger, "push_token", "DELETE", user_id);
          const { error: deleteError } = await admin
            .from("push_token")
            .delete()
            .eq("token", pushToken.token);
          logQueryResult(logger, "push_token", "DELETE", deleteError ? 0 : 1, deleteError ?? undefined);
        }
      }
    } else {
      logger.debug("[STEP 5] No push token found, skipping FCM");
    }

    logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
    return ok({ sent: !!pushToken?.token, notification_inserted: true });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
```

- [ ] **Step 2: Add `FIREBASE_SERVICE_ACCOUNT` secret**

Run in your terminal (replace `<JSON>` with the one-line JSON from Firebase Console → Service Accounts → Generate new private key):

```bash
supabase secrets set FIREBASE_SERVICE_ACCOUNT='<JSON>' --project-ref njzqcftjzskwcpforwzf
```

Then deploy both the shared module and the updated function:

```bash
supabase functions deploy send-push-notification --project-ref njzqcftjzskwcpforwzf
```

- [ ] **Step 3: Smoke test**

In the Supabase Dashboard → Edge Functions → `send-push-notification` → Invoke, send:
```json
{
  "user_id": "<your-own-user-id>",
  "title": "Test FCM v1",
  "body": "Push notifications working!",
  "type": "system"
}
```
with header `x-internal-secret: <INTERNAL_SECRET_VALUE>`.

Expected: push notification appears on your device; function logs show `✅ EXIT`.

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/send-push-notification/index.ts
git commit -m "feat(fcm): migrate send-push-notification to FCM v1 API; delete stale tokens on 404"
```

---

## Task 3: Flutter Notification Handler

**Files:**
- Create: `lib/core/notification_handler.dart`
- Create: `test/core/notification_handler_test.dart`

### Background

`firebaseMessagingBackgroundHandler` must be a top-level function (not a class method) because Flutter isolates it in a separate Dart isolate when the app is terminated.

`handleNotificationTap` inspects `message.data['type']` and navigates via the GoRouter instance passed in.

- [ ] **Step 1: Write the failing test**

Create `test/core/notification_handler_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:akeli/core/notification_handler.dart';

class MockGoRouter extends Mock implements GoRouter {}

RemoteMessage _makeMessage(Map<String, String> data) {
  return RemoteMessage(data: data);
}

void main() {
  late MockGoRouter router;

  setUp(() {
    router = MockGoRouter();
  });

  test('message type routes to DM chat', () {
    when(() => router.push(any())).thenReturn(null);
    handleNotificationTap(
      _makeMessage({'type': 'message', 'conversation_id': 'conv-123'}),
      router,
    );
    verify(() => router.push('/dm/conv-123')).called(1);
  });

  test('group_message type routes to group detail', () {
    when(() => router.push(any())).thenReturn(null);
    handleNotificationTap(
      _makeMessage({'type': 'group_message', 'group_id': 'grp-456'}),
      router,
    );
    verify(() => router.push('/group/grp-456/detail')).called(1);
  });

  test('conversation_request type routes to notifications', () {
    when(() => router.push(any())).thenReturn(null);
    handleNotificationTap(
      _makeMessage({'type': 'conversation_request'}),
      router,
    );
    verify(() => router.push('/notifications')).called(1);
  });

  test('meal_reminder type routes to meal planner', () {
    when(() => router.push(any())).thenReturn(null);
    handleNotificationTap(
      _makeMessage({'type': 'meal_reminder', 'date': '2026-06-02'}),
      router,
    );
    verify(() => router.push('/meal-planner')).called(1);
  });

  test('unknown type falls back to notifications', () {
    when(() => router.push(any())).thenReturn(null);
    handleNotificationTap(
      _makeMessage({'type': 'unknown_type'}),
      router,
    );
    verify(() => router.push('/notifications')).called(1);
  });

  test('missing type falls back to notifications', () {
    when(() => router.push(any())).thenReturn(null);
    handleNotificationTap(_makeMessage({}), router);
    verify(() => router.push('/notifications')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/notification_handler_test.dart
```

Expected: compilation error — `notification_handler.dart` does not exist yet.

- [ ] **Step 3: Create `lib/core/notification_handler.dart`**

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'logger.dart';
import '../core/router.dart';

final _logger = appLogger;

// Must be top-level — Flutter isolates this in a separate context for background messages.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Notification row is already inserted server-side. Log only — no UI updates here.
  _logger.i('FCM background message | type: ${message.data['type']} | id: ${message.messageId}');
}

void handleNotificationTap(RemoteMessage message, GoRouter router) {
  final type = message.data['type'] as String?;
  _logger.userAction('Notification tapped | type: $type', screen: 'NotificationTap');

  switch (type) {
    case 'message':
      final conversationId = message.data['conversation_id'] as String?;
      if (conversationId != null) {
        router.push(AkeliRoutes.dmChatPath(conversationId));
        return;
      }
    case 'group_message':
      final groupId = message.data['group_id'] as String?;
      if (groupId != null) {
        router.push(AkeliRoutes.groupDetailPath(groupId));
        return;
      }
    case 'meal_reminder':
      router.push(AkeliRoutes.mealPlanner);
      return;
    case 'conversation_request':
      router.push(AkeliRoutes.notifications);
      return;
  }

  // Fallback — unknown type or missing data keys
  router.push(AkeliRoutes.notifications);
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/core/notification_handler_test.dart
```

Expected: all 6 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/notification_handler.dart test/core/notification_handler_test.dart
git commit -m "feat(notifications): add notification_handler — background handler + tap-to-navigate"
```

---

## Task 4: Wire Notification Handlers in `main.dart`

**Files:**
- Modify: `lib/main.dart`

### Background

`FirebaseMessaging.onBackgroundMessage` must be called before `runApp`. `getInitialMessage` (terminated state) must resolve before `runApp` so we can deliver the tap after the first frame. `onMessageOpenedApp` (background state) fires while the app is live.

We switch from `ProviderScope` to `UncontrolledProviderScope` + an explicit `ProviderContainer` so the GoRouter instance can be read before `runApp` and reused by the widget tree.

- [ ] **Step 1: Replace `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';
import 'core/logger.dart';
import 'core/notification_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appLogger.i('🚀 Akeli app starting | initializing Supabase & Firebase');

  await initializeDateFormatting('fr_FR', null);

  RemoteMessage? initialMessage;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    appLogger.i('✅ Firebase initialized');

    // Background handler must be registered before runApp
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Terminated state — capture before runApp; deliver after first frame
    initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      appLogger.i('FCM terminated-state message | type: ${initialMessage.data['type']}');
    }

    // Foreground: show in-app SnackBar
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      appLogger.info('FCM Foreground Message received: ${message.notification?.title}');

      final title = message.notification?.title ?? 'Nouvelle notification';
      final body = message.notification?.body ?? '';

      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (body.isNotEmpty) Text(body),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Voir',
            onPressed: () {
              rootScaffoldMessengerKey.currentContext?.push(AkeliRoutes.notifications);
            },
          ),
        ),
      );
    });
  } catch (e) {
    appLogger.e('⚠️ Firebase init failed (Please run flutterfire configure): $e');
  }

  await initializeSupabase();
  appLogger.i('✅ Supabase initialized | launching ProviderScope');

  // Single ProviderContainer shared with the widget tree so the router instance
  // used by notification tap handlers is identical to the one used by GoRouter.
  final container = ProviderContainer();
  final router = container.read(routerProvider);

  // Terminated state: deliver tap after first frame so the navigator is mounted
  if (initialMessage != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleNotificationTap(initialMessage!, router);
    });
  }

  // Background state: app resumed by tapping a notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    appLogger.i('FCM background tap | type: ${message.data['type']}');
    handleNotificationTap(message, router);
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AkeliApp(),
    ),
  );
}

class AkeliApp extends ConsumerWidget {
  const AkeliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.d('🔄 AkeliApp.build() | evaluating router');
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Akeli',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
    );
  }
}
```

- [ ] **Step 2: Run Flutter analyzer**

```bash
flutter analyze lib/main.dart lib/core/notification_handler.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat(notifications): wire FCM background handler + tap-to-navigate in main.dart"
```

---

## Task 5: `send-meal-reminders` Edge Function

**Files:**
- Create: `supabase/functions/send-meal-reminders/index.ts`

### Background

Called only by pg_cron (never by the Flutter app). Secured via `x-internal-secret`. Queries `meal_plan_entry` for today, deduplicates by user, calls `send-push-notification` once per user. Returns `{ notified, skipped, failed }`.

The internal URL is `https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/send-push-notification` (hardcoded, same project as the batch cron).

- [ ] **Step 1: Create `supabase/functions/send-meal-reminders/index.ts`**

```typescript
// Cron-only — not callable from Flutter. Secured by x-internal-secret.
// Fires daily at 07:00 UTC via pg_cron. Sends one meal reminder per user
// who has at least one meal_plan_entry for today.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const INTERNAL_SECRET = Deno.env.get("INTERNAL_SECRET")!;
const PUSH_URL = `${SUPABASE_URL}/functions/v1/send-push-notification`;

serve(async (req) => {
  const logger = createLogger("send-meal-reminders");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    logger.debug("[STEP 1] Verify internal secret");
    if (!verifyInternalSecret(req)) {
      logger.warn("EARLY RETURN | reason: invalid internal secret");
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const today = new Date().toISOString().slice(0, 10);
    logger.debug("[STEP 2] Querying meal_plan_entry for date: " + today);

    const admin = serviceClient();

    logRLSCheck(logger, "meal_plan_entry", "SELECT", "cron");
    const { data: entries, error: entriesError } = await admin
      .from("meal_plan_entry")
      .select("user_id")
      .eq("planned_date", today);
    logQueryResult(logger, "meal_plan_entry", "SELECT", entries?.length ?? 0, entriesError ?? undefined);

    if (entriesError) {
      logger.error("Failed to query meal_plan_entry", { message: entriesError.message });
      return serverError(entriesError);
    }

    // Deduplicate — one notification per user
    const userIds = [...new Set((entries ?? []).map((e: { user_id: string }) => e.user_id))];
    logger.debug("[STEP 3] Unique users to notify: " + userIds.length);

    let notified = 0;
    let failed = 0;

    for (const userId of userIds) {
      const mealCount = (entries ?? []).filter((e: { user_id: string }) => e.user_id === userId).length;
      const bodyText = mealCount === 1
        ? "Vous avez 1 repas planifié aujourd'hui."
        : `Vous avez ${mealCount} repas planifiés aujourd'hui.`;

      const res = await fetch(PUSH_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-internal-secret": INTERNAL_SECRET,
        },
        body: JSON.stringify({
          user_id: userId,
          type: "meal_reminder",
          title: "Votre plan repas du jour",
          body: bodyText,
          data: { date: today },
        }),
      });

      if (res.ok) {
        notified++;
      } else {
        logger.warn("Push failed for user | userId: " + userId + " | status: " + res.status);
        failed++;
      }
    }

    const skipped = 0; // reserved for future opt-out logic
    logger.info(`✅ EXIT | notified: ${notified} | skipped: ${skipped} | failed: ${failed} | duration: ${Date.now() - start}ms`);
    return ok({ notified, skipped, failed });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
```

- [ ] **Step 2: Deploy**

```bash
supabase functions deploy send-meal-reminders --project-ref njzqcftjzskwcpforwzf
```

- [ ] **Step 3: Smoke test**

Invoke via Dashboard → Edge Functions → `send-meal-reminders` with header `x-internal-secret: <value>` and empty body `{}`.

Expected response: `{ "notified": N, "skipped": 0, "failed": 0 }` (N may be 0 if no entries exist for today — that's fine).

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/send-meal-reminders/index.ts
git commit -m "feat(notifications): add send-meal-reminders edge function — daily cron push"
```

---

## Task 6: pg_cron Migration for Meal Reminders

**Files:**
- Create: `supabase/migrations/20260602000004_register_meal_reminder_cron.sql`

### Background

Follows the exact same Vault-backed pattern as `20260531210607_register_batch_meal_plan_cron.sql`. The INTERNAL_SECRET is read from `vault.decrypted_secrets` at runtime so the plaintext never appears in `cron.job.command`. The cron fires at `0 7 * * *` (07:00 UTC daily). The URL is hardcoded to the production project (`njzqcftjzskwcpforwzf`).

The `x-internal-secret` header is used (not `Authorization: Bearer`) because `send-meal-reminders` uses `verifyInternalSecret`.

- [ ] **Step 1: Create the migration**

```sql
-- Register daily meal reminder cron job.
-- Fires every day at 07:00 UTC and calls the send-meal-reminders edge function.
--
-- The INTERNAL_SECRET must be in Vault before this migration is applied.
-- If not already present, add it:
--   SELECT vault.create_secret('<value>', 'INTERNAL_SECRET', 'Internal secret for cron auth');

-- Vault pre-flight guard — skip on local dev if secret is missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM vault.decrypted_secrets WHERE name = 'INTERNAL_SECRET'
  ) THEN
    RAISE WARNING 'INTERNAL_SECRET not found in vault — skipping cron registration (local dev). Run: SELECT vault.create_secret(''<secret>'', ''INTERNAL_SECRET'') for production.';
    RETURN;
  END IF;
END;
$$;

-- Idempotent — unschedule first so re-runs don't error or duplicate
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'send-meal-reminders-daily';

SELECT cron.schedule(
  'send-meal-reminders-daily',
  '0 7 * * *',
  $$
  SELECT net.http_post(
    -- NOTE: URL hardcoded to production project njzqcftjzskwcpforwzf — update if migrating
    url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/send-meal-reminders',
    headers := jsonb_build_object(
      'Content-Type',      'application/json',
      'x-internal-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'INTERNAL_SECRET' ORDER BY created_at DESC LIMIT 1)
    ),
    body    := '{}'::jsonb
  ) AS request_id;
  $$
);
```

- [ ] **Step 2: Apply migration**

```bash
supabase db push --project-ref njzqcftjzskwcpforwzf
```

- [ ] **Step 3: Verify cron registered**

In Supabase Dashboard → Database → Extensions → pg_cron → Jobs, confirm `send-meal-reminders-daily` appears with schedule `0 7 * * *`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260602000004_register_meal_reminder_cron.sql
git commit -m "feat(notifications): register send-meal-reminders-daily pg_cron job at 07:00 UTC"
```

---

## Post-Implementation Checklist

- [ ] `FCM_SERVER_KEY` secret removed from Supabase project (after verifying FCM v1 works)
- [ ] iOS APNs Authentication Key (`.p8`) uploaded to Firebase Console → Project Settings → Cloud Messaging → Apple app configuration (required for iOS push to work)
- [ ] iOS Xcode capability: Runner → Signing & Capabilities → + Push Notifications (writes `com.apple.developer.push-notifications` to `Runner.entitlements`)
- [ ] `flutter test` passes with no regressions

---

## Notes

- **`google-services.json` and `GoogleService-Info.plist`** — `flutterfire configure` generates these. Confirm they exist at `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` before building for a device.
- **Per-user timezone** — V1 fires at 07:00 UTC for all users. Future work: add `timezone` column to `user_profile` and adjust cron logic.
- **Token cleanup** — implemented in Task 2: `send-push-notification` deletes the `push_token` row when FCM returns 404.
