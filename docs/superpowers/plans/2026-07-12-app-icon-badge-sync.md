# App Icon Badge Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the OS app-icon badge reflect the real unread notification count and clear when notifications are read in-app, instead of being stuck at a hardcoded `1` forever.

**Architecture:** Server-side, `send-push-notification` computes the real unread count and sends it as the APNs `badge` value on every push (covers the app-closed case). Client-side, a new `badgeSyncProvider` watches the existing `unreadNotificationCountProvider` and calls a native badge plugin whenever that count changes — including immediately after `markAllNotificationsRead()` invalidates it (covers the "read in-app" case, which was the reported bug).

**Tech Stack:** Flutter/Riverpod, `flutter_app_badge_control` (^0.0.2), Deno edge functions, Supabase Postgres.

## Global Constraints

- Every Dart file and Deno file touched must carry full structured logging per `CLAUDE.md`'s Logging Standard (provider lifecycle logs, DB before/after/error, edge function ENTRY/EXIT) — no exceptions.
- L10n standard (`CLAUDE.md`) does not apply to this feature — no new user-visible strings are introduced anywhere in this plan.
- Follow existing test conventions: Flutter provider tests use `flutter_test` + `mocktail` + `ProviderContainer` overrides (see `test/providers/push_token_provider_test.dart`, `test/providers/notifications_provider_test.dart`). Deno edge functions in this repo have no automated test harness — verification is manual via `net.http_post` from SQL (Supabase MCP `execute_sql`), matching how the push-notification fix earlier in this session was verified.

---

### Task 1: Server — send real unread count as the APNs badge

**Files:**
- Modify: `supabase/functions/_shared/fcm.ts`
- Modify: `supabase/functions/send-push-notification/index.ts`

**Interfaces:**
- Produces: `sendFcmV1(fcmToken: string, title: string, body: string, data: Record<string, string>, badge: number): Promise<FcmSendResult>` — the `badge` param is new; callers must now supply it explicitly (no default).

- [ ] **Step 1: Update `sendFcmV1` to accept and use a `badge` parameter**

In `supabase/functions/_shared/fcm.ts`, replace the function signature and the hardcoded `badge: 1`:

```typescript
export async function sendFcmV1(
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string> = {},
  badge: number,
): Promise<FcmSendResult> {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT env var is not set");

  let sa: ServiceAccount;
  try {
    sa = JSON.parse(raw);
  } catch (e) {
    throw new Error(`FIREBASE_SERVICE_ACCOUNT is not valid JSON: ${(e as Error).message}`);
  }
  const accessToken = await getAccessToken(sa);

  const payload = {
    message: {
      token: fcmToken,
      notification: { title, body },
      data,
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default", badge } } },
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

(Only the signature line and the `apns.payload.aps` line change — `badge: 1` becomes `badge`, and the new `badge: number` parameter is added after `data`.)

- [ ] **Step 2: Compute and pass the real unread count in `send-push-notification/index.ts`**

Insert a new query right after the existing STEP 4 notification insert (after the `logQueryResult(logger, "notification", "INSERT", ...)` line, before the `if (!pushEnabled)` check), and update the STEP 5 call site:

```typescript
    logger.debug("[STEP 4b] Fetch unread count for badge");
    logRLSCheck(logger, "notification", "SELECT", user_id);
    const { count: unreadCount, error: unreadCountError } = await admin
      .from("notification")
      .select("id", { count: "exact", head: true })
      .eq("user_id", user_id)
      .eq("is_read", false);
    logQueryResult(logger, "notification", "SELECT", unreadCount ?? 0, unreadCountError ?? undefined);
    const badgeCount = unreadCount ?? 1;

    if (!pushEnabled) {
      logger.info("✅ EXIT | FCM skipped (user opted out) | duration: " + (Date.now() - start) + "ms");
      return ok({ sent: false, notification_inserted: notificationInserted, reason: "user_opted_out" });
    }

    if (pushToken?.token) {
      logger.debug("[STEP 5] Sending FCM v1 push | platform: " + (pushToken.platform ?? "unknown") + " | badge: " + badgeCount);

      const fcmResult = await sendFcmV1(
        pushToken.token,
        title,
        notifBody ?? "",
        Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
        badgeCount,
      );
```

Everything else in the file (STEP 5b stale-token cleanup, the final EXIT log, error handling) stays exactly as-is — only the new STEP 4b block is inserted and the STEP 5 block's `logger.debug` line and `sendFcmV1(...)` call gain the badge count.

- [ ] **Step 3: Deploy the edge function**

Run: `supabase functions deploy send-push-notification --project-ref njzqcftjzskwcpforwzf`

Expected: deploy succeeds with no errors.

- [ ] **Step 4: Verify with a real send**

Using the Supabase MCP `execute_sql` tool against project `njzqcftjzskwcpforwzf`, first check the current unread count for a real test user, then trigger a send and confirm the edge function logs show the matching badge value:

```sql
-- 1. Check expected unread count
SELECT count(*) FROM notification WHERE user_id = '<test_user_id>' AND is_read = false;

-- 2. Trigger a send (same pattern used earlier this session)
SELECT net.http_post(
  url := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/send-push-notification',
  headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'x-internal-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name='INTERNAL_SECRET' ORDER BY created_at DESC LIMIT 1)
  ),
  body := jsonb_build_object('user_id', '<test_user_id>', 'type', 'system', 'title', 'Badge test', 'body', 'checking badge count')
) as request_id;

-- 3. Check the response
SELECT status_code, content FROM net._http_response WHERE id = <request_id>;
```

Then call `mcp__claude_ai_Supabase__get_logs` with `service: "edge-function"` for project `njzqcftjzskwcpforwzf` and confirm a line reading `[STEP 5] Sending FCM v1 push ... badge: N` where `N` matches the count from query 1, plus 1 more (the notification just inserted in this same call is unread, so the count from Step 4b already includes it — confirm the number is the unread count *after* the STEP 4 insert, not before).

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/_shared/fcm.ts supabase/functions/send-push-notification/index.ts
git commit -m "fix(notifications): send real unread count as APNs badge instead of hardcoded 1"
```

---

### Task 2: Add the badge control dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, add this line immediately after `firebase_messaging: ^16.3.0` (line 57):

```yaml
  flutter_app_badge_control: ^0.0.2
```

- [ ] **Step 2: Fetch packages**

Run: `flutter pub get`

Expected: resolves with no version conflicts, `pubspec.lock` updated.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add flutter_app_badge_control dependency"
```

(iOS `Podfile.lock` is not touched here — it regenerates automatically on the next Codemagic iOS build, which already runs `flutter pub get` as part of `codemagic.yaml`; there is no local Mac/CocoaPods step to run from this Windows checkout.)

---

### Task 3: `badgeSyncProvider`

**Files:**
- Create: `lib/providers/badge_sync_provider.dart`
- Test: `test/providers/badge_sync_provider_test.dart`

**Interfaces:**
- Consumes: `unreadNotificationCountProvider` (`FutureProvider.autoDispose<int>`) from `lib/providers/notifications_provider.dart`.
- Produces: `badgeControllerProvider` (`Provider<BadgeController>`), `badgeSyncProvider` (`Provider.autoDispose<void>`), and the `BadgeController` abstract class — all in `lib/providers/badge_sync_provider.dart`. `main_shell.dart` (Task 4) watches `badgeSyncProvider`.

- [ ] **Step 1: Write the failing test**

Create `test/providers/badge_sync_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:akeli/providers/badge_sync_provider.dart';
import 'package:akeli/providers/notifications_provider.dart';

class MockBadgeController extends Mock implements BadgeController {}

void main() {
  late MockBadgeController mockController;
  ProviderContainer? container;

  setUp(() {
    mockController = MockBadgeController();
    when(() => mockController.updateBadgeCount(any())).thenAnswer((_) async {});
    when(() => mockController.removeBadge()).thenAnswer((_) async {});
  });

  tearDown(() {
    container?.dispose();
  });

  test('badgeSyncProvider calls updateBadgeCount when unread count is positive', () async {
    container = ProviderContainer(
      overrides: [
        badgeControllerProvider.overrideWithValue(mockController),
        unreadNotificationCountProvider.overrideWith((ref) async => 3),
      ],
    );

    container!.read(badgeSyncProvider);
    await Future.delayed(Duration.zero);

    verify(() => mockController.updateBadgeCount(3)).called(1);
    verifyNever(() => mockController.removeBadge());
  });

  test('badgeSyncProvider calls removeBadge when unread count is zero', () async {
    container = ProviderContainer(
      overrides: [
        badgeControllerProvider.overrideWithValue(mockController),
        unreadNotificationCountProvider.overrideWith((ref) async => 0),
      ],
    );

    container!.read(badgeSyncProvider);
    await Future.delayed(Duration.zero);

    verify(() => mockController.removeBadge()).called(1);
    verifyNever(() => mockController.updateBadgeCount(any()));
  });

  test('badgeSyncProvider does not throw when the controller call fails', () async {
    when(() => mockController.updateBadgeCount(any())).thenThrow(Exception('platform error'));

    container = ProviderContainer(
      overrides: [
        badgeControllerProvider.overrideWithValue(mockController),
        unreadNotificationCountProvider.overrideWith((ref) async => 5),
      ],
    );

    expect(() => container!.read(badgeSyncProvider), returnsNormally);
    await Future.delayed(Duration.zero);

    verify(() => mockController.updateBadgeCount(5)).called(1);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/providers/badge_sync_provider_test.dart`
Expected: FAIL — compile error, `package:akeli/providers/badge_sync_provider.dart` does not exist.

- [ ] **Step 3: Implement `badge_sync_provider.dart`**

Create `lib/providers/badge_sync_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
import '../core/logger.dart';
import 'notifications_provider.dart';

final _logger = appLogger;

abstract class BadgeController {
  Future<void> updateBadgeCount(int count);
  Future<void> removeBadge();
}

class _AppBadgeController implements BadgeController {
  @override
  Future<void> updateBadgeCount(int count) =>
      FlutterAppBadgeControl.updateBadgeCount(count);

  @override
  Future<void> removeBadge() => FlutterAppBadgeControl.removeBadge();
}

final badgeControllerProvider =
    Provider<BadgeController>((ref) => _AppBadgeController());

final badgeSyncProvider = Provider.autoDispose<void>((ref) {
  _logger.provider('badgeSyncProvider build()');
  ref.onDispose(() => _logger.provider('badgeSyncProvider disposed'));

  final controller = ref.watch(badgeControllerProvider);

  ref.listen<AsyncValue<int>>(unreadNotificationCountProvider, (previous, next) {
    next.whenData((count) async {
      try {
        if (count == 0) {
          await controller.removeBadge();
        } else {
          await controller.updateBadgeCount(count);
        }
        _logger.provider('badgeSyncProvider → synced | count: $count');
      } catch (e, st) {
        _logger.provider('badgeSyncProvider → ERROR | $e', error: e, stackTrace: st);
      }
    });
  }, fireImmediately: true);
});
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/providers/badge_sync_provider_test.dart`
Expected: PASS, 3/3 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/providers/badge_sync_provider.dart test/providers/badge_sync_provider_test.dart
git commit -m "feat(notifications): add badgeSyncProvider to sync OS badge with unread count"
```

---

### Task 4: Wire `badgeSyncProvider` into `MainShell`

**Files:**
- Modify: `lib/shared/widgets/main_shell.dart:6,34`

**Interfaces:**
- Consumes: `badgeSyncProvider` from Task 3.

- [ ] **Step 1: Add the import**

In `lib/shared/widgets/main_shell.dart`, add after line 6 (`import '../../providers/push_token_provider.dart';`):

```dart
import '../../providers/badge_sync_provider.dart';
```

- [ ] **Step 2: Watch the provider in `build()`**

At line 34, change:

```dart
    ref.watch(pushTokenProvider);
```

to:

```dart
    ref.watch(pushTokenProvider);
    ref.watch(badgeSyncProvider);
```

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze`
Expected: no new errors or warnings.

- [ ] **Step 4: Run the full provider test suite**

Run: `flutter test test/providers/`
Expected: all tests PASS, including the 3 new badge tests and the existing suite (no regressions).

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/main_shell.dart
git commit -m "feat(notifications): wire badgeSyncProvider into MainShell"
```

- [ ] **Step 6: Manual on-device verification (after next TestFlight build)**

This cannot be automated — the OS badge is only observable on a real device. After the next Codemagic build lands in TestFlight:
1. Trigger 2-3 test pushes (same `net.http_post` pattern as Task 1 Step 4) while the app is closed. Confirm the app icon badge shows the correct number (matching unread count), not always `1`.
2. Open the app, go to the Notifications page (which calls `markAllNotificationsRead`). Confirm the badge clears from the home screen within a couple seconds.
3. Repeat with the app already open (foreground) when a push arrives, then background the app — confirm the badge still reflects reality once backgrounded.

---

## Self-Review Notes

- **Spec coverage:** Server badge-count fix (spec §1) → Task 1. Client `badgeSyncProvider` + plugin (spec §2) → Tasks 2-4. Data flow (server-closed-app path, in-app-read path) → Task 1 Step 4 + Task 4 Step 6 cover both. Error handling (try/catch + logging) → Task 3 Step 3, tested in Task 3's third test. Out-of-scope items (Android exact counts, foreground-live-update) are correctly not implemented anywhere in this plan.
- **Placeholder scan:** none found — every step has literal file paths, full code, and exact commands.
- **Type consistency:** `BadgeController.updateBadgeCount(int)` / `removeBadge()` are named identically in the abstract class (Task 3 Step 3), the mock (Task 3 Step 1), and the only call sites (same file). `sendFcmV1`'s new `badge: number` parameter name and position match between its definition (Task 1 Step 1) and its only call site (Task 1 Step 2).
