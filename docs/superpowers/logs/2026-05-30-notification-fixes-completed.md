# Notification System Fixes Implementation

I have successfully resolved the notification system issues as outlined in the `2026-05-30-notification-fixes.md` spec.

## Changes Made

### Database Migration
- Created a new SQL migration file `20260530000003_fix_notification_triggers.sql` to drop the old failing triggers and create correct ones.
- **`conversation_request` trigger**: Fixed the incorrect column reference by changing `sender_id` to `requester_id` and `receiver_id` to `target_user_id`.
- **`chat_message` trigger**: Scoped the trigger down to only handle direct messages (`is_group = false`), preventing redundant and incorrect fan-out for group messages directly from Postgres.

### Edge Function (Push + In-App Fan-Out)
- Created a Deno edge function `supabase/functions/notify-group-message/index.ts`.
- Validated JWT using standard Supabase Edge function configurations inside `supabase/config.toml` (`verify_jwt = true`).
- The function accurately performs a fan-out by doing the following steps:
  1. Retrieves all active members of the `conversation` (excluding the sender).
  2. Batches and inserts an `in_app_notification` record for each member.
  3. Uses Firebase Admin via a service account to push an FCM (Firebase Cloud Messaging) payload to those members if they have active device tokens.
- **Compliance**: The edge function uses `CLAUDE.md` strict structured logging patterns (e.g. `[STEP 1]`, `logRLSCheck`, `logQueryResult`).

### Flutter Integrations & Error Fixes
- **`_shared/response.ts`**: Updated the `unauthorized()` method signature to accept an optional error message, preventing TypeScript compilation errors in existing functions.
- **`GroupChatPage`**: Updated the UI side to invoke the `notify-group-message` edge function asynchronously immediately after a message is successfully inserted in the UI.
- **Widget Tests**: Fixed the `NotificationsPage` widget test assertions by replacing hardcoded English strings with their actual French counterparts ("Toutes", "Non lues").

## Verification
- Edge function successfully registered in `config.toml`.
- Flutter `lib/features/community/group_chat_page.dart` cleanly compiles with `flutter analyze`.
- Automated testing `flutter test test/features/notifications/notifications_page_test.dart` passes.
