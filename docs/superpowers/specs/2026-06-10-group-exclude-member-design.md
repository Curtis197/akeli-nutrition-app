# Group — Exclude Member Feature

**Date:** 2026-06-10  
**Status:** Approved

## Summary

A group admin can remove any member (including other admins) from the group. Removal is simple — no ban, no history wipe — the excluded user just loses access and receives a notification. Past messages remain visible to remaining members.

---

## Decisions

| Question | Decision |
|---|---|
| Ban or simple removal? | Simple removal — can be re-invited later |
| Can admins remove other admins? | Yes |
| Notification to removed user? | Yes — push notification |
| Past messages kept? | Yes |
| UI trigger | Kebab menu ⋮ on member row (admin only) |

---

## Backend — `remove-group-member` Edge Function

**File:** `supabase/functions/remove-group-member/index.ts`

**Request body:**
```json
{ "group_id": "<uuid>", "target_user_id": "<uuid>" }
```

**Steps:**
1. Authenticate caller via JWT
2. Verify caller has `role = 'admin'` in `group_member` for `group_id` → 403 if not
3. Verify `target_user_id` is a member of the group → 404 if not found (treat as already removed on client)
4. Block self-removal: if `target_user_id == caller` → 400
5. Delete from `group_member` where `group_id` and `user_id = target_user_id`
6. Delete from `conversation_participant` where `conversation_id` (looked up via `community_group_id = group_id`) and `user_id = target_user_id`
7. Fetch group name from `community_group`
8. Call `send-push-notification` with:
   - `user_id`: `target_user_id`
   - `title`: `"Vous avez été retiré d'un groupe"`
   - `body`: `"Vous avez été exclu du groupe : ${groupName}"`
   - `type`: `"group_exclusion"`
   - `data`: `{ group_id }`
9. Return `{ success: true }`

**Error responses:**
- `403` — caller not admin
- `404` — target not a member (client treats as success)
- `400` — self-removal attempt

No migration required — only deletes from existing tables.

---

## Flutter UI

### `_MemberRow` widget changes

Add `onExcludeTap` as a nullable `VoidCallback?`. When non-null, render a `PopupMenuButton<String>` to the right of the DM icon button containing a single item:

```
icon: Icons.person_remove_outlined
text: "Exclure du groupe"
textStyle: TextStyle(color: AkeliColors.error)
```

### `_MembersTab` changes

Pass `onExcludeTap` for each member only when `isAdmin && !isMe`. No role check on the target (admins can remove other admins).

### `GroupDetailPage` — `_onExcludeTap()`

New method called when the kebab menu item is tapped:

1. Show `showDialog` confirmation:
   - Title: `"Exclure ${member.displayName} ?"`
   - Body: `"Cette personne perdra l'accès au groupe et au chat de groupe."`
   - Actions: "Annuler" | "Exclure" (red, `AkeliColors.error`)

2. On confirm, invoke edge function:
   ```dart
   client.functions.invoke('remove-group-member', body: {
     'group_id': widget.groupId,
     'target_user_id': member.userId,
   })
   ```

3. On success: `ref.invalidate(groupMembersProvider(widget.groupId))` + SnackBar "Membre exclu du groupe"

4. On error: SnackBar with appropriate message per status code:
   - 403 → "Vous n'êtes plus administrateur de ce groupe"
   - 404 → treat as success (already removed)
   - other → "Une erreur est survenue. Veuillez réessayer."

**No optimistic removal** — list updates only after server confirmation.

---

## Logging

Edge function follows full Deno logging standard (ENTRY, STEP N, RLS checks, EXIT).  
`_onExcludeTap` logs:
- `userAction('Exclude member tapped', screen: 'GroupDetailPage', metadata: { 'targetUserId': ... })`
- `edge('remove-group-member', 'BEFORE | ...')` / `AFTER` / `ERROR`

---

## Files to Create / Modify

| File | Change |
|---|---|
| `supabase/functions/remove-group-member/index.ts` | **Create** — new edge function |
| `lib/features/community/group_detail_page.dart` | **Modify** — kebab menu on `_MemberRow`, `_onExcludeTap()` in `GroupDetailPage`, pass callback in `_MembersTab` |
