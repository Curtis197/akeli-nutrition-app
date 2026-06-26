# Community Private DM + Feed Filters — Design Spec
**Date:** 2026-05-24  
**Status:** Approved

---

## 1. Overview

Two features from the first app review:

1. **Community private DM** — full 1:1 messaging between users, discovered via group participants, gated by a request/accept flow.
2. **Feed filter & ordering** — region, difficulty, time, and sort controls on the Recipes page.

---

## 2. Community Private DM

### 2.1 Database (existing — no migrations needed)

| Table | Role |
|---|---|
| `conversation` | Chat room; `type` = `private` \| `creator_group` \| `support` |
| `conversation_participant` | Members of a conversation; `last_read_at` tracks unread |
| `conversation_request` | DM request lifecycle: `pending` → `accepted` \| `rejected` |
| `chat_message` | Messages; types: `text` \| `image` \| `recipe_share` |
| `group_member` | Members of a `community_group` with role (`admin` \| `member`) |

### 2.2 Data layer — `lib/providers/dm_provider.dart`

**Models:**

```
DmConversation
  conversationId: String
  otherUserName: String
  otherUserAvatar: String?
  lastMessage: String?
  updatedAt: DateTime
  unreadCount: int   // COUNT(chat_message.created_at > conversation_participant.last_read_at)

DmRequest
  requestId: String
  requesterId: String
  requesterName: String
  requesterAvatar: String?
  message: String?
  createdAt: DateTime

GroupMember
  userId: String
  displayName: String
  avatarUrl: String?
  role: String   // 'admin' | 'member'
  joinedAt: DateTime

ChatMessage
  id: String
  conversationId: String
  senderId: String
  senderName: String
  senderAvatar: String?
  text: String
  createdAt: DateTime
  isMine: bool   // senderId == currentUserId
```

**Providers:**

| Provider | Query | Returns |
|---|---|---|
| `myPrivateConversationsProvider` | `conversation_participant` → `conversation` (type=private) → other participant's `user_profile` + last `chat_message` | `AsyncValue<List<DmConversation>>` |
| `pendingDmRequestsProvider` | `conversation_request` WHERE `recipient_id=me` AND `status='pending'` JOIN `user_profile` | `AsyncValue<List<DmRequest>>` |
| `groupMembersProvider(groupId)` | `group_member` WHERE `group_id=groupId` JOIN `user_profile` | `AsyncValue<List<GroupMember>>` |
| `resolveConversationIdProvider(groupId)` | `conversation` WHERE `community_group_id=groupId` | `AsyncValue<String>` |
| `chatMessagesProvider(conversationId)` | `chat_message` WHERE `conversation_id=…` ORDER BY `created_at` DESC + Supabase Realtime subscription | `AsyncValue<List<ChatMessage>>` |

**Actions (plain async functions, not providers):**

| Action | Operation |
|---|---|
| `sendDmRequest(ref, recipientId)` | INSERT `conversation_request` |
| `acceptDmRequest(ref, requestId, requesterId)` | UPDATE request status='accepted' + INSERT `conversation` (type=private) + 2× INSERT `conversation_participant` → returns new `conversationId` |
| `rejectDmRequest(ref, requestId)` | UPDATE request status='rejected' |
| `sendMessage(ref, conversationId, text)` | INSERT `chat_message` + UPDATE `conversation.updated_at` |
| `markConversationRead(ref, conversationId)` | UPDATE `conversation_participant.last_read_at = now()` |
| `checkExistingDm(ref, otherUserId)` | SELECT `conversation` via participant join → returns `conversationId?` |
| `checkPendingRequest(ref, recipientId)` | SELECT `conversation_request` WHERE requester=me AND recipient=recipientId AND status='pending' → returns bool |

### 2.3 Community page — `lib/features/community/community_page.dart`

**Structure:**
```
DefaultTabController(length: 3)
  AppBar: "Communauté"
  TabBar:
    Tab("Tout")
    Tab("Groupes")        ← FAB visible only here
    Tab("Privés", badge: pendingCount)
  TabBarView:
    _ToutTab
    _GroupesTab
    _PrivesTab
```

**`_ToutTab`** — merged `ListView` of groups + DMs, sorted by `updated_at` desc. Groups show people icon + member count; DMs show avatar + last message preview.

**`_GroupesTab`** — existing group list extracted verbatim. FAB ("Créer un groupe") only visible here.

**`_PrivesTab`** — see §2.4.

Badge on Privés tab: watches `pendingDmRequestsProvider`, shows count when > 0.

### 2.4 Privés tab — `_PrivesTab`

```
Column:
  ── "Demandes en attente" section (hidden if empty) ──
  For each DmRequest:
    Row: [Avatar] [Name + optional message]  [Refuser] [Accepter]
    Accept → acceptDmRequest → navigate to GroupChatPage(conversationId, title)
    Reject → rejectDmRequest → item disappears

  ── Conversations list ──
  For each DmConversation:
    Row: [Avatar] [Name]  [time]  [● unread dot if unreadCount > 0]
         [Last message preview]
    Tap → GroupChatPage(conversationId, title: otherUserName)

  ── Empty state (no DMs and no requests) ──
  EmptyState(icon: chat_bubble_outline, title: "Aucune conversation privée",
             subtitle: "Rejoignez un groupe pour commencer")
```

### 2.5 GroupDetailPage — `lib/features/community/group_detail_page.dart`

Wire members list from `groupMembersProvider(groupId)`.

Each member row:
```
[Avatar]  Display name           [✉ IconButton]  ← hidden for current user
          Membre / Admin
```

On ✉ tap:
1. `checkExistingDm(otherUserId)` → if found, navigate to `GroupChatPage(conversationId, title)`
2. `checkPendingRequest(otherUserId)` → if true, SnackBar "Demande déjà envoyée"
3. Otherwise → `sendDmRequest(otherUserId)` → SnackBar "Demande envoyée à [name]"

### 2.6 GroupChatPage — `lib/features/community/group_chat_page.dart`

**New constructor:**
```dart
GroupChatPage({
  this.groupId,         // group chats: resolved to conversationId internally
  this.conversationId,  // DM chats: used directly
  this.title,           // AppBar title (DM: other user's name)
})
// assert exactly one of groupId / conversationId is non-null
```

**Wiring:**
- On init: resolve `conversationId` if only `groupId` provided (via `resolveConversationIdProvider`)
- Watch `chatMessagesProvider(conversationId)` — loads messages + Realtime subscription
- On open: call `markConversationRead(conversationId)`
- Send: call `sendMessage(conversationId, text)` → `_controller.clear()`

**AppBar:**
- Group chats: keep ℹ️ icon → `GroupDetailPage`
- DM chats: show other user's avatar; no ℹ️ button

**Router:** add new named route for DM chat:
```dart
GoRoute(
  path: '/dm/:conversationId',
  builder: (context, state) {
    final conversationId = state.pathParameters['conversationId']!;
    final title = state.extra as String? ?? 'Message privé';
    return GroupChatPage(conversationId: conversationId, title: title);
  },
)
```
Add `AkeliRoutes.dmChatPath(String id)` helper.

---

## 3. Feed Filter & Ordering

### 3.1 FeedParams update — `lib/providers/recipe_provider.dart`

Add `orderBy` field to `FeedParams` (already present on `SearchParams`):
```dart
class FeedParams {
  final int limit;
  final List<String> excludeIds;
  final String? regionId;
  final String? difficulty;
  final int? maxTimeMin;
  final String? orderBy;   // ← new: 'rating' | 'likes' | 'created_at'
}
```

### 3.2 FeedPage UI — `lib/features/recipes/feed_page.dart`

**State additions to `_FeedPageState`:**
```dart
String? _regionId;
String? _difficulty;
int? _maxTimeMin;
String? _orderBy;
```

These compose into `FeedParams(regionId: _regionId, difficulty: _difficulty, ...)` passed to `feedProvider`.

**Filter row** — added below the `SearchBar` in the `SliverAppBar` bottom:

```
[Région ▾]  [Difficulté ▾]  [Temps ▾]  [Trier ▾]  [× clear]
```

- Horizontally scrollable `SingleChildScrollView` of `FilterChip` widgets
- Active filter: chip background = `AkeliColors.primary`, label = `AkeliColors.onPrimary`
- Inactive: default outlined chip
- `× clear` appears at the end only when at least one filter is active → resets all to null

**Bottom sheets per chip:**

| Chip | Options |
|---|---|
| Région | Toutes les régions + 13 entries from `foodRegionNamesProvider` |
| Difficulté | Tous / Facile / Moyen / Difficile |
| Temps | Tous / Moins de 30 min / Moins de 60 min / Moins de 90 min |
| Trier | Pertinence / Mieux noté / Plus populaire / Plus récent |

Each bottom sheet is a `showModalBottomSheet` with a `ListTile` per option. Selected option has a checkmark.

**PreferredSize height** of the `SliverAppBar.bottom` increases from 56 to 104 to accommodate the filter row below the search bar.

---

## 4. Files to Create / Modify

| Action | File |
|---|---|
| **Create** | `lib/providers/dm_provider.dart` |
| **Modify** | `lib/features/community/community_page.dart` |
| **Modify** | `lib/features/community/group_detail_page.dart` |
| **Modify** | `lib/features/community/group_chat_page.dart` |
| **Modify** | `lib/core/router.dart` |
| **Modify** | `lib/providers/recipe_provider.dart` |
| **Modify** | `lib/features/recipes/feed_page.dart` |

---

## 5. Out of Scope

- Push notifications for new DM requests or messages
- Image / recipe_share message types (text only for now)
- Group creation UI (already deferred with "bientôt disponible" snackbar)
- Pagination of chat messages
