# Group Invitation Workflow — Design Spec
**Date:** 2026-05-30  
**Status:** Approved  
**Sub-project:** 1 of 3 (Invitations → Browsing → Vector Discovery)

---

## Overview

Admins of a community group can invite users they have an existing DM conversation with. Invitees receive a push notification and can accept or decline from the notifications feed. Accepting atomically joins them to the group.

---

## Data Model

### New table: `group_invite`

```sql
CREATE TABLE group_invite (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id     uuid NOT NULL REFERENCES community_group(id) ON DELETE CASCADE,
  inviter_id   uuid NOT NULL REFERENCES user_profile(id),
  invitee_id   uuid NOT NULL REFERENCES user_profile(id),
  status       text NOT NULL DEFAULT 'pending'
               CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at   timestamptz DEFAULT now(),
  UNIQUE (group_id, invitee_id)
);

ALTER TABLE group_invite ENABLE ROW LEVEL SECURITY;

-- Admin can insert invites for groups they manage
CREATE POLICY "admin inserts invites" ON group_invite
  FOR INSERT WITH CHECK (
    inviter_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM group_member
      WHERE group_member.group_id = group_invite.group_id
        AND group_member.user_id = auth.uid()
        AND group_member.role = 'admin'
    )
  );

-- Invitee and inviter can read their rows
CREATE POLICY "participant reads invites" ON group_invite
  FOR SELECT USING (
    invitee_id = auth.uid() OR inviter_id = auth.uid()
  );

-- Invitee can update status of their pending invite
CREATE POLICY "invitee updates invite" ON group_invite
  FOR UPDATE USING (invitee_id = auth.uid());
```

### New RPC: `accept_group_invite(p_invite_id uuid)`

SECURITY DEFINER — atomically in one transaction:
1. Validates `auth.uid() = invitee_id` and `status = 'pending'`
2. Sets `status = 'accepted'`
3. Inserts into `group_member(group_id, user_id, role: 'member')`
4. Looks up `conversation.id WHERE community_group_id = group_id`
5. Inserts into `conversation_participant(conversation_id, user_id)`
6. Returns `group_id` so Flutter can navigate to the group

Idempotent: if user is already a `group_member`, skips inserts and returns success.

---

## Flutter

### Trigger point
Group detail page (`/group/:id/detail`) — admin-only section "Membres" shows an **"Inviter"** button (`OutlinedButton`) below the member list.

### `_InviteSheet` (bottom sheet)

**Data sources:**
- `myPrivateConversationsProvider` → list of DM contacts (already has `otherUserId`, `otherUserName`, `otherUserAvatar`)
- `groupMembersProvider(groupId)` → filter out existing members
- `pendingGroupInvitesProvider(groupId)` → new FutureProvider, SELECT from `group_invite WHERE group_id = ? AND status = 'pending'` → filter out already-invited users

**UI:**
- Title: "Inviter des membres"
- Scrollable list: avatar + name + checkbox per eligible contact
- Empty state: "Vous n'avez pas encore de conversations privées avec des utilisateurs à inviter"
- "Inviter (N)" FilledButton — disabled until ≥1 selected, shows CircularProgressIndicator while loading
- On success: sheet closes + SnackBar "Invitations envoyées"
- On error: inline error text, sheet stays open for retry

### New providers in `dm_provider.dart`

```dart
// Pending invites sent for a group (admin view)
final pendingGroupInvitesProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, groupId) async {
  // Returns list of invitee user_ids with pending status
});
```

### Accept/decline UI (notifications feed)

Notification items of `type = 'group_invite'` render two inline action buttons:
- **"Accepter"** → calls RPC `accept_group_invite(invite_id)` → on success shows "Vous avez rejoint le groupe" + "Ouvrir" button routing to `/group/:group_id`. Invalidates `communityGroupsProvider`.
- **"Décliner"** → calls `.update({ status: 'declined' })` on `group_invite` directly → notification item shows "Invitation déclinée", buttons removed.

Stale invite (already processed): RPC returns gracefully, Flutter shows "Déjà traité".

---

## Edge Function: `invite-to-group`

**File:** `supabase/functions/invite-to-group/index.ts`  
**JWT required:** yes  
**CORS:** `handleCors(req)` at top

**Request body:**
```json
{ "group_id": "uuid", "user_ids": ["uuid", ...] }
```

**Steps:**
1. Auth — `getAuthUser(req)`
2. Validate `user_ids` non-empty, max 20
3. Verify caller is admin: service client checks `group_member WHERE group_id = ? AND user_id = auth.uid AND role = 'admin'`
4. Fetch `community_group.name` and caller's `user_profile.first_name`
5. Bulk insert into `group_invite` with `ON CONFLICT (group_id, invitee_id) DO NOTHING`
6. Fan-out: for each `user_id`, call `send-push-notification` with:
   - `title`: `"${inviterName} vous invite"`
   - `body`: `"Rejoignez le groupe : ${groupName}"`
   - `type`: `"group_invite"`
   - `data`: `{ group_id, invite_id }`
7. Return `{ invited: N, skipped: M, failed: K }`

Push failures are non-fatal — logged and counted but do not roll back invite inserts.

---

## Error Handling

| Scenario | Handling |
|---|---|
| Non-admin calls `invite-to-group` | 403, Flutter shows "Vous n'êtes pas administrateur" |
| Empty `user_ids` | 400 |
| Re-inviting already-pending user | `ON CONFLICT DO NOTHING` — counted in `skipped` |
| Push notification failure | Non-fatal, counted in `failed` |
| RPC: invite not found / wrong user | Exception, Flutter shows "Invitation introuvable" |
| RPC: already a member | Idempotent success |
| RPC: already declined | Flutter shows "Cette invitation a été refusée" |
| Flutter: edge function call fails | Inline error in sheet, user can retry |

---

## Files to Create / Modify

| File | Action |
|---|---|
| `supabase/migrations/YYYYMMDD_group_invite.sql` | Create `group_invite` table + RLS + `accept_group_invite` RPC |
| `supabase/functions/invite-to-group/index.ts` | New edge function |
| `lib/providers/dm_provider.dart` | Add `pendingGroupInvitesProvider` |
| `lib/features/community/group_detail_page.dart` | Add invite button + `_InviteSheet` |
| `lib/features/notifications/notifications_page.dart` | Add `group_invite` notification item with action buttons |

---

## Out of Scope (Sub-projects 2 & 3)

- Group browsing / discovery feed
- Demographic targeting fields on groups (region, language, topic)
- Vector-based group recommendations
