# Notification Workflow — Design Spec
**Date:** 2026-05-24
**Branch:** fix-compliance-and-router-issues-814be

---

## Context

The `notification` table and `push_token` table already exist with full RLS. Meal reminders are fully wired (cron → `send-meal-reminders` → `send-push-notification` → FCM + `notification` insert). Two trigger gaps exist: DM messages and conversation requests never insert into `notification`. The `NotificationsPage` is a stub (always shows empty state). No unread badge exists on the bell icon.

---

## Scope

1. DB triggers: insert into `notification` when a DM or conversation request is created
2. Riverpod provider: fetch notifications for current user
3. `NotificationsPage`: real list with type-mapped cards, auto mark-as-read on open
4. Bell badge: red dot when unread notifications exist

FCM push for message/request events is **out of scope** for this pass (meal reminders already push via cron; in-app feed is the priority).

---

## Section 1 — DB Migration

**File:** `supabase/migrations/20260524000006_notification_triggers.sql`

### `fn_notify_chat_message()`

- Trigger: `AFTER INSERT ON chat_message FOR EACH ROW WHEN (NEW.conversation_id IS NOT NULL)`
- Skips group messages (those have `group_id`, not `conversation_id`)
- Looks up sender `display_name` from `user_profile`
- Looks up recipient: `conversation_participant WHERE conversation_id = NEW.conversation_id AND user_id != NEW.sender_id LIMIT 1`
- Inserts into `notification`:
  - `user_id` = recipient
  - `type` = `'message'`
  - `title` = sender display_name (fallback: `'Nouveau message'`)
  - `body` = `LEFT(NEW.content, 100)`
  - `data` = `{"conversation_id": ..., "sender_id": ...}`
- Function is `SECURITY DEFINER` to bypass RLS on `notification`

### `fn_notify_conversation_request()`

- Trigger: `AFTER INSERT ON conversation_request FOR EACH ROW`
- Looks up requester `display_name` from `user_profile`
- Inserts into `notification`:
  - `user_id` = `NEW.recipient_id`
  - `type` = `'conversation_request'`
  - `title` = `"{name} veut discuter"` (fallback: `"Quelqu'un veut discuter"`)
  - `body` = `'Acceptez ou refusez la demande de conversation.'`
  - `data` = `{"request_id": ..., "requester_id": ...}`
- Function is `SECURITY DEFINER`

---

## Section 2 — Flutter Provider

**File:** `lib/providers/notifications_provider.dart`

### `notificationsProvider` — `FutureProvider<List<Map<String, dynamic>>>`

- Guards: returns `[]` if no authenticated user
- Query: `SELECT * FROM notification WHERE user_id = $me ORDER BY created_at DESC LIMIT 50`
- Full logging: BEFORE / AFTER / ERROR + zero-row RLS detection

### `unreadNotificationCountProvider` — `FutureProvider<int>`

- Guards: returns `0` if no user
- Query: `SELECT count FROM notification WHERE user_id = $me AND is_read = false`
- Used by the bell badge in `main_shell.dart`

### `markAllNotificationsRead()` — standalone `Future<void>` function

- UPDATE `notification SET is_read = true WHERE user_id = $me AND is_read = false`
- Invalidates `notificationsProvider` and `unreadNotificationCountProvider` after success
- Called from `NotificationsPage.initState()`

---

## Section 3 — NotificationsPage

**File:** `lib/features/notifications/notifications_page.dart`

- Convert to `ConsumerStatefulWidget`
- `initState`: call `markAllNotificationsRead(ref)` → invalidates both providers
- Watch `notificationsProvider`:
  - Loading → centered `CircularProgressIndicator`
  - Error → `EmptyState` with generic error message
  - Empty data → existing `EmptyState` (icon + "Aucune notification")
  - Non-empty → `ListView.builder` of `AkeliNotifCard`

### Type mapping

| `notification.type`    | `NotifType`          | Notes                                                         |
|------------------------|----------------------|---------------------------------------------------------------|
| `message`              | `NotifType.chat`     | `avatarUrl` = `null` (placeholder avatar rendered by `AkeliAvatar`; full avatar lookup is a future enhancement) |
| `conversation_request` | `NotifType.request`  | `onAccept` → `acceptDmRequest`, `onDecline` → `rejectDmRequest`; invalidates providers after |
| `meal_reminder`        | `NotifType.meal`     | `emoji` = `🍽️`, subtitle from `data.meal_type`              |
| all others             | `NotifType.meal`     | Generic emoji `🔔`                                            |

### Time display

Format `created_at` as relative time (e.g. "Il y a 5 min", "Hier") using Dart's `DateTime` diff — no external package.

---

## Section 4 — Bell Badge (`main_shell.dart`)

- Wrap the bell `IconButton` in a `Stack`
- Watch `unreadNotificationCountProvider`
- If count > 0: overlay a `Positioned` red dot — `Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle))` at top-right corner
- If loading or 0: no overlay

---

## What is NOT changing

- `send-push-notification` edge function — untouched
- `send-meal-reminders` edge function — untouched
- `dm_provider.dart` send paths — untouched
- FCM push for DM/request events — deferred

---

## Logging requirements

All Dart files follow the project logging standard (CLAUDE.md):
- `import 'package:akeli/core/logger.dart'`
- `final _logger = appLogger`
- BEFORE / AFTER / ERROR on every DB op
- `userAction` log on accept/decline taps
- `provider` log on build + state transitions
