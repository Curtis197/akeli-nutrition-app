# Notification Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix three notification bugs (broken conversation-request trigger, group messages silently skipped, test label mismatch) and add group push notifications via a new edge function.

**Architecture:** A single migration fixes two DB trigger issues. A new `verify_jwt=true` edge function `notify-group-message` handles push + in-app for group chats (calling the existing `send-push-notification` which already writes notification rows). `GroupChatPage` fire-and-forgets that function after each group send. The DM trigger is narrowed to DM-only conversations (skip `community_group_id IS NOT NULL`) to avoid duplicate rows.

**Tech Stack:** Flutter 3.x · Riverpod · Supabase (supabase_flutter) · Deno/TypeScript edge functions · GoRouter · flutter_test

> **Note on Fix 2 (meal reminders):** `send-push-notification` already unconditionally inserts a `notification` row before attempting FCM. `send-meal-reminders` calls `send-push-notification`, so meal reminder rows are already written. No code change needed.

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `supabase/migrations/20260530000003_fix_notification_triggers.sql` | Fix conversation_request trigger columns; narrow DM trigger to skip group-linked conversations |
| Create | `supabase/functions/notify-group-message/index.ts` | Fan-out push + in-app to all group members on group message send |
| Modify | `supabase/config.toml` | Register `notify-group-message` with `verify_jwt = true` |
| Modify | `lib/features/community/group_chat_page.dart` | Call `notify-group-message` fire-and-forget after group message send |
| Modify | `test/features/notifications/notifications_page_test.dart` | Fix French button label assertions |

---

### Task 1: DB Migration — Fix Trigger Bugs

**Files:**
- Create: `supabase/migrations/20260530000003_fix_notification_triggers.sql`

- [ ] **Step 1: Create the migration file**

Create `supabase/migrations/20260530000003_fix_notification_triggers.sql`:

```sql
-- ---------------------------------------------------------------------------
-- FIX 1: fn_notify_conversation_request used wrong column names.
-- The live conversation_request table has requester_id / recipient_id,
-- not from_user_id / to_user_id.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_notify_conversation_request()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_requester_name text;
BEGIN
  SELECT display_name INTO v_requester_name
    FROM user_profile WHERE id = NEW.requester_id;

  INSERT INTO notification (user_id, type, title, body, data)
  VALUES (
    NEW.recipient_id,
    'conversation_request',
    COALESCE(v_requester_name, 'Quelqu''un') || ' veut discuter',
    'Acceptez ou refusez la demande de conversation.',
    jsonb_build_object(
      'request_id',   NEW.id,
      'requester_id', NEW.requester_id
    )
  );

  RETURN NEW;
END;
$$;

-- Recreate trigger (idempotent)
DROP TRIGGER IF EXISTS trg_notify_conversation_request ON conversation_request;
CREATE TRIGGER trg_notify_conversation_request
  AFTER INSERT ON conversation_request
  FOR EACH ROW
  EXECUTE FUNCTION fn_notify_conversation_request();

-- ---------------------------------------------------------------------------
-- FIX 2: fn_notify_chat_message used LIMIT 1, notifying only one participant.
-- For DMs this was accidentally correct (2 participants → 1 recipient).
-- Group chats also use conversation_id but have N participants — LIMIT 1 drops
-- N-2 recipients.
--
-- Correct approach:
--   - DMs:   conversation.community_group_id IS NULL  → trigger handles them,
--            loops over all conversation_participant rows (always 1 recipient).
--   - Groups: conversation.community_group_id IS NOT NULL → skip here;
--             notify-group-message edge function handles push + in-app via
--             send-push-notification (which already inserts notification rows).
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_notify_chat_message()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sender_name  text;
  v_recipient    RECORD;
  v_is_group     boolean;
BEGIN
  -- Only handle DM conversations (conversation_id set)
  IF NEW.conversation_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Skip group-linked conversations — handled by notify-group-message edge fn
  SELECT (community_group_id IS NOT NULL)
    INTO v_is_group
    FROM conversation
   WHERE id = NEW.conversation_id;

  IF v_is_group THEN
    RETURN NEW;
  END IF;

  SELECT display_name INTO v_sender_name
    FROM user_profile WHERE id = NEW.sender_id;

  -- Loop over all participants except sender (DMs: always exactly one)
  FOR v_recipient IN
    SELECT user_id
      FROM conversation_participant
     WHERE conversation_id = NEW.conversation_id
       AND user_id != NEW.sender_id
  LOOP
    INSERT INTO notification (user_id, type, title, body, data)
    VALUES (
      v_recipient.user_id,
      'message',
      COALESCE(v_sender_name, 'Nouveau message'),
      LEFT(NEW.content, 100),
      jsonb_build_object(
        'conversation_id', NEW.conversation_id,
        'sender_id',       NEW.sender_id
      )
    );
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_chat_message ON chat_message;
CREATE TRIGGER trg_notify_chat_message
  AFTER INSERT ON chat_message
  FOR EACH ROW
  EXECUTE FUNCTION fn_notify_chat_message();
```

- [ ] **Step 2: Smoke-test in Supabase Studio or psql**

Open Supabase Studio SQL editor (`http://127.0.0.1:54323`) and run:

```sql
-- Verify functions compile and exist
SELECT proname FROM pg_proc
WHERE proname IN ('fn_notify_conversation_request', 'fn_notify_chat_message');

-- Verify triggers exist on correct tables
SELECT tgname, relname
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
WHERE tgname IN ('trg_notify_conversation_request', 'trg_notify_chat_message');
```

Expected: 2 rows from `pg_proc`, 2 rows from `pg_trigger`.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260530000003_fix_notification_triggers.sql
git commit -m "fix(db): correct conversation_request trigger columns; narrow DM trigger to skip group-linked convos"
```

---

### Task 2: `notify-group-message` Edge Function

**Files:**
- Create: `supabase/functions/notify-group-message/index.ts`
- Modify: `supabase/config.toml`

- [ ] **Step 1: Add to `config.toml`**

Open `supabase/config.toml`. After the last `[functions.*]` block, append:

```toml
[functions.notify-group-message]
verify_jwt = true
```

- [ ] **Step 2: Create the edge function**

Create `supabase/functions/notify-group-message/index.ts`:

```typescript
// Called by Flutter after sending a group message.
// Fans out push + in-app notifications to all group members except the sender.
// send-push-notification already inserts a notification row for each call,
// so we do NOT also write to the notification table here.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

const SELF_URL = Deno.env.get("SUPABASE_URL")!;
const INTERNAL_SECRET = Deno.env.get("INTERNAL_SECRET")!;

serve(async (req) => {
  const logger = createLogger("notify-group-message");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    logger.debug("[STEP 1] Verify JWT");
    const { user } = await getAuthUser(req);
    if (!user) {
      logger.warn("EARLY RETURN | reason: unauthenticated");
      return unauthorized("Authentication required");
    }
    logger.setUserId(user.id);
    logger.info("👤 Auth verified | userId: " + user.id);

    logger.debug("[STEP 2] Parse body");
    const body = await req.json();
    const { group_id, message_preview } = body as {
      group_id?: string;
      message_preview?: string;
    };

    if (!group_id || !message_preview) {
      logger.warn("EARLY RETURN | reason: missing group_id or message_preview");
      return err("group_id and message_preview are required");
    }
    logger.debug("[STEP 2] Parsed | group_id: " + group_id);

    const admin = serviceClient();

    logger.debug("[STEP 3] Verify sender is a group member");
    logRLSCheck(logger, "group_member", "SELECT", user.id);
    const { data: membership, error: memberError } = await admin
      .from("group_member")
      .select("user_id")
      .eq("group_id", group_id)
      .eq("user_id", user.id)
      .maybeSingle();
    logQueryResult(logger, "group_member", "SELECT", membership ? 1 : 0, memberError ?? undefined);

    if (!membership) {
      logger.warn("EARLY RETURN | reason: sender not a group member | group_id: " + group_id);
      return unauthorized("Not a member of this group");
    }

    logger.debug("[STEP 4] Fetch sender display_name");
    logRLSCheck(logger, "user_profile", "SELECT", user.id);
    const { data: senderProfile } = await admin
      .from("user_profile")
      .select("display_name")
      .eq("id", user.id)
      .maybeSingle();
    const senderName = senderProfile?.display_name ?? "Quelqu'un";

    logger.debug("[STEP 5] Fetch group name");
    logRLSCheck(logger, "community_group", "SELECT", "all");
    const { data: group } = await admin
      .from("community_group")
      .select("name")
      .eq("id", group_id)
      .maybeSingle();
    const groupName = group?.name ?? "Groupe";

    logger.debug("[STEP 6] Fetch group members excluding sender");
    logRLSCheck(logger, "group_member", "SELECT", "all");
    const { data: members, error: membersError } = await admin
      .from("group_member")
      .select("user_id")
      .eq("group_id", group_id)
      .neq("user_id", user.id);
    logQueryResult(logger, "group_member", "SELECT", members?.length ?? 0, membersError ?? undefined);

    if (!members || members.length === 0) {
      logger.info("✅ EXIT | no other members to notify | duration: " + (Date.now() - start) + "ms");
      return ok({ sent: 0, failed: 0 });
    }

    logger.debug("[STEP 7] Fan-out push to " + members.length + " members");

    let sent = 0;
    let failed = 0;

    for (const member of members) {
      logger.debug("[STEP 7] Notifying member: " + member.user_id);
      const pushRes = await fetch(`${SELF_URL}/functions/v1/send-push-notification`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-internal-secret": INTERNAL_SECRET,
        },
        body: JSON.stringify({
          user_id: member.user_id,
          title: senderName + " (" + groupName + ")",
          body: message_preview,
          type: "message",
          data: { group_id, sender_id: user.id },
        }),
      });

      if (pushRes.ok) {
        sent++;
      } else {
        failed++;
        logger.warn("[STEP 7] Push failed | member: " + member.user_id + " | status: " + pushRes.status);
      }
    }

    logger.info("✅ EXIT | status: 200 | sent: " + sent + " | failed: " + failed + " | duration: " + (Date.now() - start) + "ms");
    return ok({ sent, failed });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
```

- [ ] **Step 3: Verify `_shared/response.ts` exports `unauthorized`**

Open `supabase/functions/_shared/response.ts` and confirm `unauthorized` is exported. If not, add it:

```typescript
export const unauthorized = (message = "Unauthorized") =>
  new Response(JSON.stringify({ error: message }), {
    status: 401,
    headers: { "Content-Type": "application/json" },
  });
```

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/notify-group-message/index.ts supabase/config.toml
git commit -m "feat(edge): add notify-group-message function for group push + in-app fan-out"
```

---

### Task 3: Flutter — Call `notify-group-message` After Group Send

**Files:**
- Modify: `lib/features/community/group_chat_page.dart`

- [ ] **Step 1: Read the current `_sendMessage` method**

Open `lib/features/community/group_chat_page.dart`. The relevant section (around line 59) currently reads:

```dart
void _sendMessage() {
  final text = _controller.text.trim();
  if (text.isEmpty || _resolvedConversationId == null) return;
  _logger.userAction('Message sent', screen: 'GroupChatPage', metadata: {
    'conversationId': _resolvedConversationId,
    'length': text.length,
  });
  _controller.clear();
  sendMessage(ref, _resolvedConversationId!, text).catchError((e) {
    _logger.db('ERROR | sendMessage | $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'envoi")),
      );
    }
  });
}
```

- [ ] **Step 2: Add the import for `dart:math`**

At the top of `lib/features/community/group_chat_page.dart`, add:

```dart
import 'dart:math';
```

- [ ] **Step 3: Replace `_sendMessage` with the version that fire-and-forgets the edge function**

```dart
void _sendMessage() {
  final text = _controller.text.trim();
  if (text.isEmpty || _resolvedConversationId == null) return;
  _logger.userAction('Message sent', screen: 'GroupChatPage', metadata: {
    'conversationId': _resolvedConversationId,
    'groupId': widget.groupId,
    'length': text.length,
  });
  _controller.clear();
  sendMessage(ref, _resolvedConversationId!, text).then((_) {
    if (widget.groupId != null) {
      _notifyGroupMembers(widget.groupId!, text);
    }
  }).catchError((e) {
    _logger.db('ERROR | sendMessage | $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'envoi")),
      );
    }
  });
}

void _notifyGroupMembers(String groupId, String text) {
  final preview = text.substring(0, min(100, text.length));
  _logger.edge('notify-group-message', 'BEFORE | groupId: $groupId');
  final client = ref.read(supabaseClientProvider);
  client.functions.invoke(
    'notify-group-message',
    body: {'group_id': groupId, 'message_preview': preview},
  ).then((_) {
    _logger.edge('notify-group-message', 'AFTER | success');
  }).catchError((Object e, StackTrace st) {
    _logger.edge('notify-group-message', 'ERROR | $e', error: e, stackTrace: st);
  });
}
```

- [ ] **Step 4: Verify the import for `supabaseClientProvider`**

Check the import list at the top of `group_chat_page.dart`. If `supabase_client.dart` isn't imported, add:

```dart
import '../../core/supabase_client.dart';
```

- [ ] **Step 5: Run flutter analyze**

```bash
flutter analyze lib/features/community/group_chat_page.dart
```

Expected: no errors, no warnings.

- [ ] **Step 6: Commit**

```bash
git add lib/features/community/group_chat_page.dart
git commit -m "feat(flutter): fire-and-forget notify-group-message after group message send"
```

---

### Task 4: Fix Widget Test Label Assertions

**Files:**
- Modify: `test/features/notifications/notifications_page_test.dart`

- [ ] **Step 1: Run the failing test to confirm**

```bash
flutter test test/features/notifications/notifications_page_test.dart -v
```

Expected: the `conversation_request` test fails with something like:
```
Expected: exactly one matching node in the widget tree
  Actual: _TextFinder:<"Accept">
```

- [ ] **Step 2: Fix the assertions**

In `test/features/notifications/notifications_page_test.dart`, find the `conversation_request` test (around line 73–75) and update:

Old:
```dart
expect(find.text('Accept'), findsOneWidget);
expect(find.text('Decline'), findsOneWidget);
```

New:
```dart
expect(find.text('Accepter'), findsOneWidget);
expect(find.text('Refuser'), findsOneWidget);
```

- [ ] **Step 3: Run tests — expect all to pass**

```bash
flutter test test/features/notifications/notifications_page_test.dart -v
```

Expected output:
```
✓ NotificationsPage shows empty state when no notifications
✓ NotificationsPage shows chat card for message notification
✓ NotificationsPage shows request card with Accept/Decline for conversation_request
All tests passed!
```

- [ ] **Step 4: Run full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add test/features/notifications/notifications_page_test.dart
git commit -m "fix(test): update notification button label assertions to French (Accepter/Refuser)"
```

---

## Self-Review

**Spec coverage:**
- ✅ Fix conversation_request trigger columns → Task 1
- ✅ Meal reminder in-app → already working via `send-push-notification` (documented in plan header, no task needed)
- ✅ Test label mismatch → Task 4
- ✅ Group in-app (DM trigger narrowed + edge function inserts via send-push-notification) → Tasks 1 + 2
- ✅ Group push fan-out → Task 2
- ✅ Flutter call site → Task 3

**Placeholder scan:** None. All code blocks are complete.

**Type consistency:**
- `_notifyGroupMembers(String groupId, String text)` defined Task 3 Step 3, called Task 3 Step 3 ✅
- `supabaseClientProvider` imported Task 3 Step 4, used Task 3 Step 3 ✅
- `send-push-notification` body shape `{ user_id, title, body, type, data }` matches Task 2 Step 2 ✅
- `unauthorized` helper verified in Task 2 Step 3 before use in Task 2 Step 2 ✅
- `getAuthUser`, `serviceClient`, `createLogger`, `logRLSCheck`, `logQueryResult` imported from existing `_shared/` files ✅
