# Firebase Push Notifications — Design Spec
**Date:** 2026-06-02  
**Status:** Approved  
**Platforms:** Android + iOS  
**Firebase project:** `afro-health`

---

## Overview

Wire end-to-end push notifications for Akeli across Android and iOS. The scaffolding (DB schema, edge function skeleton, Flutter providers, notifications UI) is already in place. This design fills four gaps:

1. Firebase project wiring (`flutterfire configure`)
2. FCM legacy API → FCM v1 API migration
3. Flutter background + tap-to-navigate notification handling
4. Meal reminder scheduling via pg_cron

---

## Current State

| Component | Status |
|---|---|
| `push_token` + `notification` DB tables | ✅ Exists with RLS |
| `firebase_core` + `firebase_messaging` in pubspec | ✅ |
| `firebase_options.dart` | ❌ Placeholder — throws on every call |
| `google-services.json` / `GoogleService-Info.plist` | ❌ Not generated |
| `push_token_provider.dart` | ✅ Registers FCM token to Supabase |
| `send-push-notification` edge function | ⚠️ Uses deprecated FCM legacy HTTP API |
| `notify-group-message` edge function | ✅ Calls dispatcher correctly |
| DB triggers (DM + conversation_request) | ✅ Insert into `notification` table |
| Foreground SnackBar in `main.dart` | ✅ |
| Background message handler | ❌ Missing |
| Tap-to-navigate (terminated + background) | ❌ Missing |
| Meal reminder scheduler | ❌ Missing |

---

## Section 1 — Firebase Project Wiring

### Goal
Replace the placeholder `firebase_options.dart` with real credentials and add platform config files.

### Steps

**1. Run flutterfire configure**
```bash
flutterfire configure --project=afro-health
```
This generates:
- `lib/firebase_options.dart` (real options)
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

**2. iOS — Push Notifications capability**
- In Xcode: `Runner → Signing & Capabilities → + → Push Notifications`
- Writes `com.apple.developer.push-notifications` to `ios/Runner/Runner.entitlements`
- In Firebase Console: Project Settings → Cloud Messaging → Apple app configuration → upload APNs Authentication Key (`.p8` file from Apple Developer portal)

**3. Android**
- `google-services.json` is sufficient. FCM works via Google Play Services — no additional Xcode-style steps.

**4. `main.dart`**
- `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` is already correct — no code change needed once the options file is real.

### Files changed
- `lib/firebase_options.dart` (generated — replace placeholder)
- `android/app/google-services.json` (generated — new file)
- `ios/Runner/GoogleService-Info.plist` (generated — new file)
- `ios/Runner/Runner.entitlements` (Xcode capability addition)

---

## Section 2 — FCM v1 API Migration

### Goal
Replace the deprecated FCM legacy HTTP API (`/fcm/send` + `FCM_SERVER_KEY`) with FCM v1 (`/v1/projects/{project_id}/messages:send` + OAuth2 bearer token).

### Why FCM v1
Google deprecated the legacy FCM HTTP API and is shutting it down. FCM v1 uses short-lived OAuth2 tokens issued from a service account — more secure and required going forward.

### New file: `supabase/functions/_shared/fcm.ts`

Responsibilities:
- Read `FIREBASE_SERVICE_ACCOUNT` env var (JSON string of service account key)
- Build a signed JWT (RS256) from the service account credentials using the Web Crypto API (native in Deno — no external dependency)
- Exchange the JWT for a Google OAuth2 access token via `https://oauth2.googleapis.com/token`
- Export `sendFcmV1(fcmToken, title, body, data)` which calls:  
  `POST https://fcm.googleapis.com/v1/projects/afro-health/messages:send`  
  with `Authorization: Bearer <access_token>`

FCM v1 message structure:
```json
{
  "message": {
    "token": "<device_fcm_token>",
    "notification": { "title": "...", "body": "..." },
    "data": { "type": "...", "...": "..." },
    "android": { "priority": "high" },
    "apns": {
      "payload": { "aps": { "sound": "default", "badge": 1 } }
    }
  }
}
```

### Updated: `supabase/functions/send-push-notification/index.ts`

Changes:
- Remove `FCM_SERVER_KEY` and `FCM_URL` constants
- Import `sendFcmV1` from `../_shared/fcm.ts`
- Replace the old `fetch(FCM_URL, ...)` block with `sendFcmV1(pushToken.token, title, notifBody, data)`
- Function signature, internal secret auth, DB insert logic — all unchanged

### Supabase secrets

Add:
```
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"afro-health",...}
```

Remove (after deployment verified):
```
FCM_SERVER_KEY
```

Service account key is downloaded from:  
Firebase Console → Project Settings → Service Accounts → Generate new private key → Save JSON

### Files changed
- `supabase/functions/_shared/fcm.ts` (new)
- `supabase/functions/send-push-notification/index.ts` (updated)

---

## Section 3 — Flutter Notification Handling

### Goal
Handle push notifications in all three app states: foreground (already done), background, and terminated. Add tap-to-navigate deep linking.

### New file: `lib/core/notification_handler.dart`

Contains two exports:

**1. Background handler (top-level function)**
```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Notification row already inserted server-side — log only.
}
```
Must be top-level (not inside a class) because Flutter isolates it in a separate context.

**2. `handleNotificationTap(RemoteMessage message, GoRouter router)`**
Reads `message.data['type']` and routes:

| `type` | `data` keys | Route |
|---|---|---|
| `message` | `conversation_id` | `AkeliRoutes.dmChatPath(conversationId)` |
| `group_message` | `group_id` | `AkeliRoutes.groupDetailPath(groupId)` |
| `conversation_request` | — | `AkeliRoutes.notifications` |
| `meal_reminder` | `meal_type`, `date` | `AkeliRoutes.mealPlanner` |
| fallback | — | `AkeliRoutes.notifications` |

### Changes to `lib/main.dart`

After `Firebase.initializeApp(...)`:

```dart
// 1. Register background handler
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

// 2. Terminated state — app launched by tap
final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
if (initialMessage != null) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    handleNotificationTap(initialMessage, router);
  });
}

// 3. Background state — app already open, user taps notification
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  handleNotificationTap(message, router);
});
```

**Router access before `runApp`:** The `GoRouter` instance is constructed once and stored in a module-level variable (or accessed via a `ProviderContainer` created before `runApp`) so both `getInitialMessage` and `onMessageOpenedApp` can pass it to `handleNotificationTap`.

### Files changed
- `lib/core/notification_handler.dart` (new)
- `lib/main.dart` (updated — register background handler + tap listeners)

---

## Section 4 — Meal Reminder Scheduling

### Goal
Send daily meal reminder push notifications to users who have meals planned for the current day.

### New file: `supabase/functions/send-meal-reminders/index.ts`

Secured via `x-internal-secret` header (same pattern as `send-push-notification`). Called by pg_cron — not by the Flutter app.

**Logic:**
1. Determine today's date in UTC (`new Date().toISOString().slice(0, 10)`)
2. Query `meal_plan_entry` joined with `user_profile` for all entries where `planned_date = today`
3. Deduplicate by user — one notification per user per day regardless of how many meals they have planned
4. For each user, call `send-push-notification` internally:
   ```json
   {
     "user_id": "...",
     "type": "meal_reminder",
     "title": "Votre plan repas du jour",
     "body": "Vous avez X repas planifiés aujourd'hui.",
     "data": { "date": "2026-06-02" }
   }
   ```
5. Return `{ notified, skipped, failed }` summary

**V1 simplification:** Reminders fire at 7:00 AM UTC for all users. Per-user timezone scheduling is deferred.

### New migration: pg_cron registration

New file: `supabase/migrations/20260602000004_register_meal_reminder_cron.sql`

```sql
-- Set config params used by the cron job (idempotent)
ALTER DATABASE postgres SET app.supabase_url = '<SUPABASE_URL>';
ALTER DATABASE postgres SET app.internal_secret = '<INTERNAL_SECRET>';

SELECT cron.schedule(
  'send-meal-reminders-daily',
  '0 7 * * *',
  $$
  SELECT net.http_post(
    url        := current_setting('app.supabase_url') || '/functions/v1/send-meal-reminders',
    headers    := jsonb_build_object(
                    'Content-Type',      'application/json',
                    'x-internal-secret', current_setting('app.internal_secret')
                  ),
    body       := '{}'::jsonb
  );
  $$
);
```

Follows the same pattern as `20260531210607_register_batch_meal_plan_cron.sql`.

### Files changed
- `supabase/functions/send-meal-reminders/index.ts` (new)
- `supabase/migrations/20260602000004_register_meal_reminder_cron.sql` (new)

---

## Delivery Sequence

Implement in this order to keep the app working at each step:

1. **Firebase wiring** — run `flutterfire configure`, add iOS APNs capability
2. **FCM v1 migration** — `_shared/fcm.ts` + update `send-push-notification`; add `FIREBASE_SERVICE_ACCOUNT` secret; deploy and smoke test
3. **Flutter tap handling** — `notification_handler.dart` + `main.dart` wiring
4. **Meal reminders** — `send-meal-reminders` function + cron migration

---

## Open Questions / Future Work

- **Per-user timezone scheduling** — V1 fires at 7 AM UTC. A future design can add a `timezone` column to `user_profile` and use a pg_cron job that checks each user's local time.
- **Notification preferences** — no per-user opt-out for notification types yet. Future: `notification_preferences` table.
- **APNs certificate vs. key** — APNs Authentication Key (`.p8`) is preferred over certificate (`.p12`) as it doesn't expire. Use the key.
- **Token cleanup** — stale FCM tokens accumulate if users reinstall the app. FCM v1 returns `404` for invalid tokens; `send-push-notification` should delete the token row on `404` response.
