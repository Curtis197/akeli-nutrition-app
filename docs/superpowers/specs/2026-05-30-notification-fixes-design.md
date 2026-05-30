# Notification Fixes — Design Spec

**Date:** 2026-05-30
**Scope:** Four targeted fixes to the in-app notification workflow.

---

## Problem Summary

Four issues identified in the notification workflow:

1. **Trigger column mismatch** — `fn_notify_conversation_request` references `NEW.from_user_id` / `NEW.to_user_id` but the live `conversation_request` table has `requester_id` / `recipient_id`. Every conversation request INSERT silently fails to notify.
2. **Meal reminder in-app gap** — `send-meal-reminders` sends push notifications only; it never writes to the `notification` table, making the `case 'meal_reminder':` branch in `NotificationsPage` dead code.
3. **Test label mismatch** — `notifications_page_test.dart` expects English `'Accept'` / `'Decline'` but `AkeliNotifCard` renders French `'Accepter'` / `'Refuser'`.
4. **Group notifications unimplemented** — no in-app notification and no push when a group message is sent.

---

## Fix 1 — Conversation Request Trigger Column Names

**File:** `supabase/migrations/20260530000001_fix_notification_triggers.sql`

Recreate `fn_notify_conversation_request` with correct column references:
- `NEW.from_user_id` → `NEW.requester_id`
- `NEW.to_user_id` → `NEW.recipient_id`

Drop and recreate the trigger (idempotent). No schema changes — trigger function only.

---

## Fix 2 — Meal Reminder In-App Notification

**File:** `supabase/functions/send-meal-reminders/index.ts`

After each successful push (current `if (pushRes.ok)` branch), insert a row into `notification` using the admin service client:

```
type:    'meal_reminder'
user_id: reminder.user_id
title:   same title sent to push
body:    same body sent to push
data:    { meal_type: reminder.meal_type }
```

Use `upsert` with a conflict target of `(user_id, type, created_at::date)` is NOT needed — simple INSERT is fine; duplicate reminders on the same day are intentional (if the user has multiple reminder slots). Log the insert result (BEFORE / AFTER / ERROR pattern per logging standard).

---

## Fix 3 — Test Label Mismatch

**File:** `test/features/notifications/notifications_page_test.dart`

Change two assertions:
- `find.text('Accept')` → `find.text('Accepter')`
- `find.text('Decline')` → `find.text('Refuser')`

---

## Fix 4 — Group Message Notifications

### Architecture note

`GroupChatPage` resolves `groupId` → `conversationId` via `resolveConversationIdProvider`, then calls `sendMessage(ref, conversationId, text)` — which inserts `chat_message` with `conversation_id` set (not `group_id`). Group chats go through the same `conversation_id` path as DMs.

The existing `fn_notify_chat_message` trigger therefore already fires for group messages. The bug is the `LIMIT 1` — it picks one random participant instead of all. Fix: loop over all `conversation_participant` rows.

### 4a — In-App (fix existing DM trigger to loop, not LIMIT 1)

**File:** `supabase/migrations/20260530000001_fix_notification_triggers.sql` (same migration as Fix 1)

Modify `fn_notify_chat_message`: replace the single-recipient `SELECT ... LIMIT 1` + conditional INSERT with a `FOR` loop over all `conversation_participant` rows where `user_id != NEW.sender_id`, inserting one `notification` per member.

- `type: 'message'`
- `title`: sender's display name
- `body`: `LEFT(NEW.content, 100)`
- `data`: `{ conversation_id, sender_id }`

This correctly handles both DMs (2 participants → 1 notification) and group conversations (N participants → N−1 notifications).

SECURITY DEFINER + `SET search_path = public`.

### 4b — Push Fan-Out (Edge Function)

**File:** `supabase/functions/notify-group-message/index.ts`

Internal edge function (`verify_jwt = false`, requires `x-internal-secret` header).

Request body: `{ group_id: string, sender_id: string, message_preview: string }`

Steps:
1. Verify internal secret
2. Read group name from `community_group`
3. Read sender display name from `user_profile`
4. Query `group_member` for all `user_id` where `group_id = p_group_id AND user_id != sender_id`
5. For each member, call `send-push-notification` with:
   - `title`: `"[GroupName] SenderName"`
   - `body`: `message_preview`
   - `type`: `'message'`
   - `data`: `{ group_id, sender_id }`
6. Return `{ sent: N, failed: M }`

**File:** `supabase/config.toml` — add:
```toml
[functions.notify-group-message]
verify_jwt = false
```

### 4c — Flutter Call Site

**File:** `lib/features/community/group_chat_page.dart` — `_sendMessage()`

After `sendMessage(ref, _resolvedConversationId!, text)` is called (fire-and-forget, inside the `.then()` chain or in parallel), call `notify-group-message` via `supabase.functions.invoke()` only when `widget.groupId != null`. Pass `{ group_id: widget.groupId, sender_id: currentUser.id, message_preview: text.substring(0, min(100, text.length)) }`. Fire-and-forget. Log with `_logger.edge('notify-group-message', ...)` pattern.

---

## Architecture Notes

- In-app group notifications are guaranteed by the DB trigger even if the Flutter edge function call fails.
- Push is best-effort (client calls edge function after insert).
- No `pg_net` extension — trigger cannot call push directly.
- `notification.type` stays `'message'` for group messages; the `data.group_id` field distinguishes them from DMs at the app layer if needed later.

---

## Files Changed

| Action | File |
|--------|------|
| Create | `supabase/migrations/20260530000001_fix_notification_triggers.sql` |
| Modify | `supabase/functions/send-meal-reminders/index.ts` |
| Modify | `test/features/notifications/notifications_page_test.dart` |
| Create | `supabase/functions/notify-group-message/index.ts` |
| Modify | `supabase/config.toml` |
| Modify | `lib/features/community/group_chat_page.dart` |
