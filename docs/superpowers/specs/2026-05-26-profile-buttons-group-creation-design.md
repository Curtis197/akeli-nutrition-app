# Profile Conversation Buttons & Group Creation — Design Spec

**Date:** 2026-05-26  
**Scope:** Two independent but related social features: (1) wiring profile page conversation buttons to the DM system, (2) wiring the community groups provider and enabling group creation.

---

## Feature 1 — Profile Conversation Buttons

### Goal

When a logged-in user views another user's profile, the action buttons in the profile header reflect the real conversation state between the two users and allow them to initiate, open, or leave a private DM.

### Button State Machine

Buttons are **only rendered** when `widget.userId != null` (viewing another user's profile). The current user's own profile shows no action buttons.

| Conversation state | Buttons rendered |
|---|---|
| Loading | `CircularProgressIndicator` where buttons would be |
| No conversation, no pending request | **Ajouter** (gradient fill) |
| Pending request already sent | **En attente** (disabled, grey outline) |
| Active conversation exists | **Ecrire** (primary outline) + **Supprimer** (destructive outline) |

### New Provider: `conversationStateProvider`

```dart
enum ConvState { none, pending, active }

class ConversationState {
  final ConvState status;
  final String? conversationId; // non-null when status == active
}

final conversationStateProvider =
    FutureProvider.autoDispose.family<ConversationState, String>((ref, otherUserId) async {
  // 1. checkExistingDm in parallel with checkPendingRequest
  // 2. If existing DM found → return ConversationState(active, conversationId)
  // 3. Else if pending request found → return ConversationState(pending)
  // 4. Else → return ConversationState(none)
});
```

Lives in `lib/providers/dm_provider.dart`.

### New Action: `leaveDmConversation`

Soft-leave: deletes the current user's row from `conversation_participant`. The other user retains their history.

```dart
Future<void> leaveDmConversation(WidgetRef ref, String conversationId) async {
  // DELETE FROM conversation_participant
  // WHERE conversation_id = conversationId AND user_id = currentUser.id
  // Then: ref.invalidate(myPrivateConversationsProvider)
}
```

Lives in `lib/providers/dm_provider.dart`.

### Profile Page Changes (`lib/features/profile/profile_page.dart`)

- Import `dm_provider.dart`
- In `build()`, when `!isCurrentUser`: watch `conversationStateProvider(widget.userId!)` and render the appropriate button set
- **Ajouter** handler: `sendDmRequest(ref, widget.userId!)` → invalidate `conversationStateProvider` → show snackbar "Demande envoyée"
- **Ecrire** handler: `context.push(AkeliRoutes.dmChatPath(state.conversationId!), extra: profile?.displayName ?? '')`
- **Supprimer** handler: show `AlertDialog` with title "Fermer la conversation ?" and body "Vous quitterez cette conversation. L'autre utilisateur gardera son historique." with buttons "Annuler" / "Fermer" → on confirm: `leaveDmConversation(ref, state.conversationId!)` → show snackbar "Conversation fermée"
- When `isCurrentUser`: render `const SizedBox.shrink()` where buttons were (no change to current user's own view)

---

## Feature 2 — Community Groups: Wiring + Creation

### 2a — Wire `communityGroupsProvider`

**Current:** Returns `[]` unconditionally.  
**New:** Queries the DB for groups the current user is a member of.

```
communityGroupsProvider:
1. Get currentUser — return [] if null
2. SELECT group_id FROM group_member WHERE user_id = me
3. If empty → return []
4. SELECT * FROM community_group WHERE id IN (group_ids) ORDER BY updated_at DESC
5. Return List<Map<String,dynamic>> with keys: id, name, description, cover_url, member_count, updated_at
```

Lives in `lib/features/community/community_page.dart` (inline provider, no separate file).

### 2b — Group Creation Flow

**Entry point:** FAB on the Groupes tab (currently shows "bientôt disponible" snackbar).

**UI:** `showModalBottomSheet` with a stateful form:

| Field | Type | Validation |
|---|---|---|
| Nom | `TextField` | Required, max 50 chars |
| Description | `TextField` | Optional, max 200 chars, multiline |
| Public | `Switch` | Default: true |

A **Créer** button at the bottom confirms creation. A loading state disables the button during the async operation. Errors are shown as a red text below the button.

**Creation sequence (in `createGroup` action):**

```
1. INSERT community_group (name, description, is_public, creator_id=me)
   → get new group.id
2. INSERT group_member (group_id, user_id=me, role='admin')
3. INSERT conversation (type='group', community_group_id=group.id, created_by=me)
   → get conversation.id
4. INSERT conversation_participant (conversation_id, user_id=me)
5. ref.invalidate(communityGroupsProvider)
6. Navigator.pop (close sheet)
7. context.go(AkeliRoutes.groupChatPath(group.id))
```

**New action `createGroup`** lives in `lib/providers/dm_provider.dart`:

```dart
Future<String> createGroup(WidgetRef ref, {
  required String name,
  String? description,
  bool isPublic = true,
}) async {
  // Executes the 4-insert sequence above
  // Returns groupId
}
```

### 2c — RLS Migration

A new migration `20260526000003_group_creation_rls.sql` adds INSERT policies that are currently missing:

```sql
-- community_group: authenticated users can create groups
CREATE POLICY "authenticated user creates group" ON community_group
  FOR INSERT WITH CHECK (creator_id = auth.uid() AND auth.uid() IS NOT NULL);

-- community_group: creator can update their own groups
CREATE POLICY "creator updates group" ON community_group
  FOR UPDATE USING (creator_id = auth.uid());

-- group_member: users can insert their own membership
CREATE POLICY "user inserts own membership" ON group_member
  FOR INSERT WITH CHECK (user_id = auth.uid());
```

The existing `conversation` INSERT policy ("authenticated user creates conversation") and `conversation_participant` INSERT policy already cover steps 3 and 4.

---

## Features 3 & 4 — Already Implemented

**Recipe filter/sort:** The `_FilterSheet` bottom sheet in `feed_page.dart` exposes region, difficulty, time, calorie range, and all four sort options. It is now scrollable. No additional work.

**Community conversation filter:** The Tout / Groupes / Privés tabs already implement the requested filter. Once Feature 2a wires `communityGroupsProvider`, the Tout and Groupes tabs show real data automatically.

---

## Files Changed

| File | Change |
|---|---|
| `lib/providers/dm_provider.dart` | Add `conversationStateProvider`, `leaveDmConversation`, `createGroup` |
| `lib/features/profile/profile_page.dart` | Wire action buttons to `conversationStateProvider` |
| `lib/features/community/community_page.dart` | Wire `communityGroupsProvider` to DB; group creation bottom sheet |
| `supabase/migrations/20260526000003_group_creation_rls.sql` | INSERT policies for `community_group` and `group_member` |

---

## Error Handling

- All DB operations catch `PostgrestException` with RLS logging (`e.code == '42501'`) and generic error snackbar for the user
- Group creation: duplicate name is allowed (no unique constraint) — names are not unique by design
- Leave conversation: if the row is already gone (race condition), the DELETE is silent (no error)
- Send DM request: if a pending request already exists, the DB will return a unique constraint error — the UI re-fetches `conversationStateProvider` to show the correct state
