# Community Private DM — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire full 1:1 private messaging — request/accept flow from group participant profiles, DM list in a new Privés tab, real-time chat using GroupChatPage.

**Architecture:** New `dm_provider.dart` holds all models, query providers, and action functions. `community_page.dart` becomes a 3-tab shell (Tout/Groupes/Privés). `GroupChatPage` gains a dual constructor (groupId OR direct conversationId). A DB migration fixes four RLS gaps before any Flutter code can touch the tables.

**Tech Stack:** Flutter 3, Riverpod 2 (`FutureProvider`, `StreamProvider`), GoRouter 14, Supabase Dart SDK (PostgREST + Realtime stream), `supabase_flutter`, `AkeliColors`/`AkeliSpacing`/`AkeliRadius` from `lib/core/theme.dart`, `AkeliAvatar` from `lib/shared/widgets/avatar.dart`.

---

## File Map

**Create:**
- `supabase/migrations/20260524000002_community_dm_rls.sql` — RLS fixes
- `lib/providers/dm_provider.dart` — all DM models, providers, and actions

**Modify:**
- `lib/core/router.dart` — add `/dm/:conversationId` route
- `lib/features/community/group_chat_page.dart` — dual constructor + Supabase wiring
- `lib/features/community/group_detail_page.dart` — members list + DM button
- `lib/features/community/community_page.dart` — 3-tab restructure

---

## Task 1: DB migration — fix RLS gaps

**Files:**
- Create: `supabase/migrations/20260524000002_community_dm_rls.sql`

- [ ] **Step 1: Create the migration file**

```sql
-- supabase/migrations/20260524000002_community_dm_rls.sql
-- Fix four RLS gaps required by the Community DM feature.

-- 1. conversation: allow participants to SELECT conversations they belong to
CREATE POLICY "participant reads own conversations" ON conversation
  FOR SELECT
  USING (
    id IN (
      SELECT conversation_id FROM conversation_participant
      WHERE user_id = auth.uid()
    )
  );

-- 2. conversation: allow authenticated users to INSERT new conversations
--    (needed when acceptDmRequest creates the conversation row)
CREATE POLICY "authenticated user creates conversation" ON conversation
  FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- 3. conversation_participant: allow participants to see ALL rows in
--    conversations they belong to (needed to fetch the other user's profile)
CREATE POLICY "participants read all rows in shared conversations" ON conversation_participant
  FOR SELECT
  USING (
    conversation_id IN (
      SELECT conversation_id FROM conversation_participant
      WHERE user_id = auth.uid()
    )
  );

-- 4. group_member: allow members to read other members of their groups
CREATE POLICY "group members read other members" ON group_member
  FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM group_member
      WHERE user_id = auth.uid()
    )
  );

-- 5. conversation_request: the existing policy references wrong column names
--    (from_user_id / to_user_id). Drop and recreate with correct names.
DROP POLICY IF EXISTS "participant reads conversation_request" ON conversation_request;
CREATE POLICY "participant reads conversation_request" ON conversation_request
  FOR ALL
  USING (auth.uid() = requester_id OR auth.uid() = recipient_id);
```

- [ ] **Step 2: Apply migration to local Supabase**

```bash
supabase db push
```

Expected: migration applied without errors.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260524000002_community_dm_rls.sql
git commit -m "fix(db): add RLS policies for conversation, group_member, conversation_request"
```

---

## Task 2: DM models

**Files:**
- Create: `lib/providers/dm_provider.dart` (models section only)
- Create: `test/providers/dm_models_test.dart`

- [ ] **Step 1: Write failing model tests**

Create `test/providers/dm_models_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/providers/dm_provider.dart';

void main() {
  group('DmRequest.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'req-1',
        'requester_id': 'user-1',
        'message': 'Salut !',
        'created_at': '2026-05-24T10:00:00.000Z',
        'user_profile': {'display_name': 'Alice', 'avatar_url': 'https://img'},
      };
      final req = DmRequest.fromJson(json);
      expect(req.requestId, 'req-1');
      expect(req.requesterId, 'user-1');
      expect(req.requesterName, 'Alice');
      expect(req.requesterAvatar, 'https://img');
      expect(req.message, 'Salut !');
    });

    test('handles null avatar and message', () {
      final json = {
        'id': 'req-2',
        'requester_id': 'user-2',
        'message': null,
        'created_at': '2026-05-24T10:00:00.000Z',
        'user_profile': {'display_name': 'Bob', 'avatar_url': null},
      };
      final req = DmRequest.fromJson(json);
      expect(req.requesterAvatar, isNull);
      expect(req.message, isNull);
    });
  });

  group('GroupMember.fromJson', () {
    test('parses member row', () {
      final json = {
        'user_id': 'user-3',
        'role': 'admin',
        'joined_at': '2026-04-01T00:00:00.000Z',
        'user_profile': {'display_name': 'Carol', 'avatar_url': null},
      };
      final m = GroupMember.fromJson(json);
      expect(m.userId, 'user-3');
      expect(m.role, 'admin');
      expect(m.displayName, 'Carol');
    });
  });

  group('ChatMessage.fromJson', () {
    test('isMine true when senderId matches currentUserId', () {
      final json = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'sender_id': 'me',
        'content': 'Hello',
        'sent_at': '2026-05-24T10:00:00.000Z',
        'user_profile': {'display_name': 'Me', 'avatar_url': null},
      };
      final msg = ChatMessage.fromJson(json, currentUserId: 'me');
      expect(msg.isMine, isTrue);
      expect(msg.content, 'Hello');
    });

    test('isMine false for other sender', () {
      final json = {
        'id': 'msg-2',
        'conversation_id': 'conv-1',
        'sender_id': 'other',
        'content': 'Hi',
        'sent_at': '2026-05-24T10:00:00.000Z',
        'user_profile': {'display_name': 'Other', 'avatar_url': null},
      };
      final msg = ChatMessage.fromJson(json, currentUserId: 'me');
      expect(msg.isMine, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
flutter test test/providers/dm_models_test.dart
```

Expected: compilation error — `dm_provider.dart` does not exist yet.

- [ ] **Step 3: Create dm_provider.dart with models only**

Create `lib/providers/dm_provider.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../core/supabase_client.dart';
import 'auth_provider.dart';

// ─── Models ────────────────────────────────────────────────────────────────

@immutable
class DmConversation {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String? lastMessage;
  final DateTime updatedAt;
  final int unreadCount;

  const DmConversation({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.lastMessage,
    required this.updatedAt,
    required this.unreadCount,
  });
}

@immutable
class DmRequest {
  final String requestId;
  final String requesterId;
  final String requesterName;
  final String? requesterAvatar;
  final String? message;
  final DateTime createdAt;

  const DmRequest({
    required this.requestId,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatar,
    this.message,
    required this.createdAt,
  });

  factory DmRequest.fromJson(Map<String, dynamic> json) {
    final profile = json['user_profile'] as Map<String, dynamic>?;
    return DmRequest(
      requestId: json['id'] as String,
      requesterId: json['requester_id'] as String,
      requesterName: profile?['display_name'] as String? ?? 'Utilisateur',
      requesterAvatar: profile?['avatar_url'] as String?,
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

@immutable
class GroupMember {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String role;
  final DateTime joinedAt;

  const GroupMember({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final profile = json['user_profile'] as Map<String, dynamic>?;
    return GroupMember(
      userId: json['user_id'] as String,
      displayName: profile?['display_name'] as String? ?? 'Utilisateur',
      avatarUrl: profile?['avatar_url'] as String?,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}

@immutable
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime sentAt;
  final bool isMine;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.sentAt,
    required this.isMine,
  });

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    final profile = json['user_profile'] as Map<String, dynamic>?;
    final senderId = json['sender_id'] as String;
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: senderId,
      senderName: profile?['display_name'] as String? ?? 'Utilisateur',
      senderAvatar: profile?['avatar_url'] as String?,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
      isMine: senderId == currentUserId,
    );
  }
}
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
flutter test test/providers/dm_models_test.dart
```

Expected: all 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/providers/dm_provider.dart test/providers/dm_models_test.dart
git commit -m "feat(dm): add DM models with unit tests"
```

---

## Task 3: Query providers

**Files:**
- Modify: `lib/providers/dm_provider.dart` — append providers below the models

- [ ] **Step 1: Append query providers to dm_provider.dart**

Add below the models section in `lib/providers/dm_provider.dart`:

```dart
// ─── Query providers ────────────────────────────────────────────────────────

/// All private conversations the current user is a participant in,
/// sorted by most recently updated.
final myPrivateConversationsProvider =
    FutureProvider.autoDispose<List<DmConversation>>((ref) async {
  final logger = appLogger;
  final user = ref.watch(currentUserProvider);
  logger.provider('myPrivateConversationsProvider build() | userId: ${user?.id}');
  ref.onDispose(() => logger.provider('myPrivateConversationsProvider disposed'));

  if (user == null) return [];

  final client = ref.watch(supabaseClientProvider);

  // 1. Get conversation_ids + last_read_at for my participations
  logger.db('BEFORE | table: conversation_participant | op: SELECT | userId: ${user.id}');
  final participations = await client
      .from('conversation_participant')
      .select('conversation_id, last_read_at')
      .eq('user_id', user.id) as List<dynamic>;
  logger.db('AFTER | table: conversation_participant | rows: ${participations.length}');

  if (participations.isEmpty) return [];

  final myConvIds = participations
      .cast<Map<String, dynamic>>()
      .map((p) => p['conversation_id'] as String)
      .toList();
  final lastReadMap = {
    for (final p in participations.cast<Map<String, dynamic>>())
      p['conversation_id'] as String: p['last_read_at'] as String?
  };

  // 2. Get private conversations from those IDs
  logger.db('BEFORE | table: conversation | op: SELECT in | count: ${myConvIds.length}');
  final conversations = await client
      .from('conversation')
      .select('id, updated_at')
      .inFilter('id', myConvIds)
      .eq('type', 'private')
      .order('updated_at', ascending: false) as List<dynamic>;
  logger.db('AFTER | table: conversation | rows: ${conversations.length}');

  if (conversations.isEmpty) return [];

  // 3. For each conversation assemble DmConversation
  final result = <DmConversation>[];
  for (final conv in conversations.cast<Map<String, dynamic>>()) {
    final convId = conv['id'] as String;

    // Other participant
    logger.db('BEFORE | table: conversation_participant | op: SELECT other | convId: $convId');
    final others = await client
        .from('conversation_participant')
        .select('user_id, user_profile:user_id(display_name, avatar_url)')
        .eq('conversation_id', convId)
        .neq('user_id', user.id) as List<dynamic>;

    final otherRow = others.cast<Map<String, dynamic>>().firstOrNull;
    final otherProfile = otherRow?['user_profile'] as Map<String, dynamic>?;

    // Last message
    logger.db('BEFORE | table: chat_message | op: SELECT last | convId: $convId');
    final lastMsgRows = await client
        .from('chat_message')
        .select('content')
        .eq('conversation_id', convId)
        .order('sent_at', ascending: false)
        .limit(1) as List<dynamic>;

    final lastMessage = lastMsgRows.cast<Map<String, dynamic>>().firstOrNull?['content'] as String?;

    // Unread count
    final lastRead = lastReadMap[convId];
    int unreadCount = 0;
    if (lastRead != null) {
      final unread = await client
          .from('chat_message')
          .select('id')
          .eq('conversation_id', convId)
          .gt('sent_at', lastRead) as List<dynamic>;
      unreadCount = unread.length;
    }

    result.add(DmConversation(
      conversationId: convId,
      otherUserId: otherRow?['user_id'] as String? ?? '',
      otherUserName: otherProfile?['display_name'] as String? ?? 'Utilisateur',
      otherUserAvatar: otherProfile?['avatar_url'] as String?,
      lastMessage: lastMessage,
      updatedAt: DateTime.parse(conv['updated_at'] as String),
      unreadCount: unreadCount,
    ));
  }

  logger.provider('myPrivateConversationsProvider → data | count: ${result.length}');
  return result;
});

/// Pending DM requests where the current user is the recipient.
final pendingDmRequestsProvider =
    FutureProvider.autoDispose<List<DmRequest>>((ref) async {
  final logger = appLogger;
  final user = ref.watch(currentUserProvider);
  logger.provider('pendingDmRequestsProvider build() | userId: ${user?.id}');
  ref.onDispose(() => logger.provider('pendingDmRequestsProvider disposed'));

  if (user == null) return [];

  final client = ref.watch(supabaseClientProvider);
  logger.db('BEFORE | table: conversation_request | op: SELECT pending | userId: ${user.id}');

  try {
    final rows = await client
        .from('conversation_request')
        .select('id, requester_id, message, created_at, user_profile:requester_id(display_name, avatar_url)')
        .eq('recipient_id', user.id)
        .eq('status', 'pending')
        .order('created_at', ascending: false) as List<dynamic>;

    logger.db('AFTER | table: conversation_request | rows: ${rows.length}');
    if (rows.isEmpty) {
      logger.provider('pendingDmRequestsProvider → data (empty)');
      return [];
    }

    final requests = rows.cast<Map<String, dynamic>>().map(DmRequest.fromJson).toList();
    logger.provider('pendingDmRequestsProvider → data | count: ${requests.length}');
    return requests;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls('Permission denied | table: conversation_request | userId: ${user.id}', error: e, stackTrace: st);
    } else {
      logger.db('ERROR | table: conversation_request | code: ${e.code}', error: e, stackTrace: st);
    }
    rethrow;
  }
});

/// All members of a community group.
final groupMembersProvider =
    FutureProvider.autoDispose.family<List<GroupMember>, String>((ref, groupId) async {
  final logger = appLogger;
  logger.provider('groupMembersProvider build() | groupId: $groupId');
  ref.onDispose(() => logger.provider('groupMembersProvider disposed | groupId: $groupId'));

  final client = ref.watch(supabaseClientProvider);
  logger.db('BEFORE | table: group_member | op: SELECT | groupId: $groupId');

  try {
    final rows = await client
        .from('group_member')
        .select('user_id, role, joined_at, user_profile:user_id(display_name, avatar_url)')
        .eq('group_id', groupId)
        .order('joined_at', ascending: true) as List<dynamic>;

    logger.db('AFTER | table: group_member | rows: ${rows.length}');
    final members = rows.cast<Map<String, dynamic>>().map(GroupMember.fromJson).toList();
    logger.provider('groupMembersProvider → data | count: ${members.length}');
    return members;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls('Permission denied | table: group_member | groupId: $groupId', error: e, stackTrace: st);
    } else {
      logger.db('ERROR | table: group_member | code: ${e.code}', error: e, stackTrace: st);
    }
    rethrow;
  }
});

/// Resolves the conversation_id for a community group's chat.
final resolveConversationIdProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, groupId) async {
  final logger = appLogger;
  logger.provider('resolveConversationIdProvider build() | groupId: $groupId');
  ref.onDispose(() => logger.provider('resolveConversationIdProvider disposed | groupId: $groupId'));

  final client = ref.watch(supabaseClientProvider);
  logger.db('BEFORE | table: conversation | op: SELECT | groupId: $groupId');

  try {
    final data = await client
        .from('conversation')
        .select('id')
        .eq('community_group_id', groupId)
        .maybeSingle();

    final convId = data?['id'] as String?;
    logger.db('AFTER | table: conversation | found: ${convId != null}');
    logger.provider('resolveConversationIdProvider → data | conversationId: $convId');
    return convId;
  } on PostgrestException catch (e, st) {
    logger.db('ERROR | table: conversation | code: ${e.code}', error: e, stackTrace: st);
    rethrow;
  }
});

/// Real-time stream of messages in a conversation, newest first.
final chatMessagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, conversationId) {
  final logger = appLogger;
  logger.provider('chatMessagesProvider build() | conversationId: $conversationId');
  ref.onDispose(() => logger.provider('chatMessagesProvider disposed | conversationId: $conversationId'));

  final client = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserProvider)?.id ?? '';

  logger.db('BEFORE stream | table: chat_message | conversationId: $conversationId');

  return client
      .from('chat_message')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      .order('sent_at', ascending: false)
      .map((rows) {
        logger.db('AFTER stream | table: chat_message | rows: ${rows.length}');
        return rows
            .map((r) => ChatMessage.fromJson(r, currentUserId: userId))
            .toList();
      });
});
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/providers/dm_provider.dart
```

Expected: no errors. Warnings about unused imports are acceptable only if no code yet calls these providers.

- [ ] **Step 3: Commit**

```bash
git add lib/providers/dm_provider.dart
git commit -m "feat(dm): add query providers (conversations, requests, members, messages)"
```

---

## Task 4: Action functions

**Files:**
- Modify: `lib/providers/dm_provider.dart` — append actions below providers

- [ ] **Step 1: Append action functions to dm_provider.dart**

Add at the bottom of `lib/providers/dm_provider.dart`:

```dart
// ─── Actions ────────────────────────────────────────────────────────────────

/// Returns the conversationId if a private conversation already exists
/// between the current user and [otherUserId], otherwise null.
Future<String?> checkExistingDm(Ref ref, String otherUserId) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) return null;

  logger.db('BEFORE | checkExistingDm | otherUserId: $otherUserId');

  // My conversation_ids
  final mine = await client
      .from('conversation_participant')
      .select('conversation_id')
      .eq('user_id', userId) as List<dynamic>;

  if (mine.isEmpty) return null;

  final myIds = mine.cast<Map<String, dynamic>>()
      .map((r) => r['conversation_id'] as String)
      .toList();

  // Find any conversation both users share that is private
  final shared = await client
      .from('conversation_participant')
      .select('conversation_id, conversation:conversation_id(type)')
      .inFilter('conversation_id', myIds)
      .eq('user_id', otherUserId) as List<dynamic>;

  for (final row in shared.cast<Map<String, dynamic>>()) {
    final conv = row['conversation'] as Map<String, dynamic>?;
    if (conv?['type'] == 'private') {
      final id = row['conversation_id'] as String;
      logger.db('AFTER | checkExistingDm | found: $id');
      return id;
    }
  }

  logger.db('AFTER | checkExistingDm | not found');
  return null;
}

/// Returns true if a pending request from current user to [recipientId] exists.
Future<bool> checkPendingRequest(Ref ref, String recipientId) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) return false;

  logger.db('BEFORE | checkPendingRequest | recipientId: $recipientId');

  final result = await client
      .from('conversation_request')
      .select('id')
      .eq('requester_id', userId)
      .eq('recipient_id', recipientId)
      .eq('status', 'pending')
      .maybeSingle();

  final exists = result != null;
  logger.db('AFTER | checkPendingRequest | exists: $exists');
  return exists;
}

/// Sends a DM request from the current user to [recipientId].
Future<void> sendDmRequest(Ref ref, String recipientId) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) return;

  logger.db('BEFORE | table: conversation_request | op: INSERT | recipientId: $recipientId');
  await client.from('conversation_request').insert({
    'requester_id': userId,
    'recipient_id': recipientId,
    'status': 'pending',
  });
  logger.db('AFTER | table: conversation_request | op: INSERT | success');
}

/// Accepts a DM request: creates conversation + participants, returns conversationId.
Future<String> acceptDmRequest(
  Ref ref,
  String requestId,
  String requesterId,
) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)!.id;

  logger.db('BEFORE | acceptDmRequest | requestId: $requestId');

  // 1. Mark request accepted
  await client.from('conversation_request').update({
    'status': 'accepted',
    'responded_at': DateTime.now().toIso8601String(),
  }).eq('id', requestId);

  // 2. Create conversation
  logger.db('BEFORE | table: conversation | op: INSERT | type: private');
  final convResult = await client
      .from('conversation')
      .insert({'type': 'private', 'created_by': userId})
      .select('id')
      .single();
  final conversationId = convResult['id'] as String;
  logger.db('AFTER | table: conversation | conversationId: $conversationId');

  // 3. Add both participants
  logger.db('BEFORE | table: conversation_participant | op: INSERT | conversationId: $conversationId');
  await client.from('conversation_participant').insert([
    {'conversation_id': conversationId, 'user_id': userId},
    {'conversation_id': conversationId, 'user_id': requesterId},
  ]);
  logger.db('AFTER | table: conversation_participant | inserted: 2');

  ref.invalidate(myPrivateConversationsProvider);
  ref.invalidate(pendingDmRequestsProvider);

  logger.db('AFTER | acceptDmRequest | conversationId: $conversationId');
  return conversationId;
}

/// Rejects a DM request.
Future<void> rejectDmRequest(Ref ref, String requestId) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);

  logger.db('BEFORE | table: conversation_request | op: UPDATE rejected | requestId: $requestId');
  await client.from('conversation_request').update({
    'status': 'rejected',
    'responded_at': DateTime.now().toIso8601String(),
  }).eq('id', requestId);
  logger.db('AFTER | table: conversation_request | rejected');

  ref.invalidate(pendingDmRequestsProvider);
}

/// Sends a text message in a conversation.
Future<void> sendMessage(Ref ref, String conversationId, String content) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) return;

  logger.db('BEFORE | table: chat_message | op: INSERT | conversationId: $conversationId');
  await client.from('chat_message').insert({
    'conversation_id': conversationId,
    'sender_id': userId,
    'content': content,
    'message_type': 'text',
  });

  await client
      .from('conversation')
      .update({'updated_at': DateTime.now().toIso8601String()})
      .eq('id', conversationId);
  logger.db('AFTER | table: chat_message | inserted');

  ref.invalidate(myPrivateConversationsProvider);
}

/// Updates last_read_at for the current user in a conversation (clears unread).
Future<void> markConversationRead(Ref ref, String conversationId) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) return;

  logger.db('BEFORE | table: conversation_participant | op: UPDATE last_read_at | conversationId: $conversationId');
  await client
      .from('conversation_participant')
      .update({'last_read_at': DateTime.now().toIso8601String()})
      .eq('conversation_id', conversationId)
      .eq('user_id', userId);
  logger.db('AFTER | table: conversation_participant | last_read_at updated');

  ref.invalidate(myPrivateConversationsProvider);
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/providers/dm_provider.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/providers/dm_provider.dart
git commit -m "feat(dm): add action functions (send/accept/reject request, send message, mark read)"
```

---

## Task 5: Router — add DM chat route

**Files:**
- Modify: `lib/core/router.dart`

- [ ] **Step 1: Add dmChatPath helper and route**

In `lib/core/router.dart`, add to the `AkeliRoutes` abstract class:

```dart
static const dmChat = '/dm/:conversationId';
static String dmChatPath(String id) => '/dm/$id';
```

Then add the route inside the `routes: [...]` list in `GoRouter(...)`, before the `ShellRoute`:

```dart
GoRoute(
  path: AkeliRoutes.dmChat,
  builder: (context, state) {
    final conversationId = state.pathParameters['conversationId']!;
    final title = state.extra as String? ?? 'Message privé';
    return GroupChatPage(conversationId: conversationId, title: title);
  },
),
```

The import for `GroupChatPage` is already present in router.dart.

- [ ] **Step 2: Verify analysis**

```bash
flutter analyze lib/core/router.dart
```

Expected: no errors. (GroupChatPage constructor will error until Task 6 — that is expected.)

- [ ] **Step 3: Commit**

```bash
git add lib/core/router.dart
git commit -m "feat(dm): add /dm/:conversationId route to router"
```

---

## Task 6: GroupChatPage — Supabase wiring + dual constructor

**Files:**
- Modify: `lib/features/community/group_chat_page.dart`

Replace the entire file with the wired version:

- [ ] **Step 1: Replace group_chat_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/dm_provider.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/chat_bubble.dart';

class GroupChatPage extends ConsumerStatefulWidget {
  final String? groupId;
  final String? conversationId;
  final String? title;

  const GroupChatPage({
    super.key,
    this.groupId,
    this.conversationId,
    this.title,
  }) : assert(
          (groupId != null) != (conversationId != null),
          'Exactly one of groupId or conversationId must be provided',
        );

  @override
  ConsumerState<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends ConsumerState<GroupChatPage> {
  final _controller = TextEditingController();
  final _logger = appLogger;
  String? _resolvedConversationId;

  @override
  void initState() {
    super.initState();
    _logger.provider('GroupChatPage initState() | groupId: ${widget.groupId} | conversationId: ${widget.conversationId}');
    if (widget.conversationId != null) {
      _resolvedConversationId = widget.conversationId;
      _markRead();
    }
  }

  @override
  void dispose() {
    _logger.provider('GroupChatPage disposed');
    _controller.dispose();
    super.dispose();
  }

  void _markRead() {
    if (_resolvedConversationId == null) return;
    markConversationRead(ref, _resolvedConversationId!).catchError((e) {
      _logger.db('ERROR | markConversationRead | $e');
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || _resolvedConversationId == null) return;
    _logger.userAction('Message sent', screen: 'GroupChatPage',
        metadata: {'conversationId': _resolvedConversationId, 'length': text.length});
    _controller.clear();
    sendMessage(ref, _resolvedConversationId!, text).catchError((e) {
      _logger.db('ERROR | sendMessage | $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If groupId provided, resolve conversationId first
    if (widget.groupId != null && _resolvedConversationId == null) {
      final resolved = ref.watch(resolveConversationIdProvider(widget.groupId!));
      return resolved.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
        data: (convId) {
          if (convId == null) {
            return const Scaffold(body: Center(child: Text('Conversation introuvable')));
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _resolvedConversationId = convId);
              _markRead();
            }
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      );
    }

    final convId = _resolvedConversationId!;
    final isGroup = widget.groupId != null;
    final appBarTitle = widget.title ?? (isGroup ? 'Discussion du groupe' : 'Message privé');

    _logger.provider('GroupChatPage build() | conversationId: $convId');

    final messagesAsync = ref.watch(chatMessagesProvider(convId));

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: AkeliColors.background,
        elevation: 0,
        leading: const BackButton(),
        title: Text(appBarTitle),
        actions: [
          if (isGroup)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                _logger.userAction('Group info tapped', screen: 'GroupChatPage');
                context.push(AkeliRoutes.groupDetailPath(widget.groupId!));
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun message pour le moment.\nSoyez le premier à écrire !',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AkeliColors.onSurfaceVariant),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(AkeliSpacing.md),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AkeliSpacing.sm),
                      child: AkeliChatBubble(
                        message: msg.content,
                        time: _formatTime(msg.sentAt),
                        isSent: msg.isMine,
                        senderName: msg.isMine ? null : msg.senderName,
                        isRead: false,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: AkeliColors.surface,
            padding: const EdgeInsets.symmetric(
                horizontal: AkeliSpacing.md, vertical: AkeliSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      _logger.userAction('Message submitted via keyboard', screen: 'GroupChatPage');
                      _sendMessage();
                    },
                    decoration: InputDecoration(
                      hintText: 'Écrire un message…',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AkeliRadius.pill)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AkeliSpacing.md, vertical: AkeliSpacing.sm),
                    ),
                  ),
                ),
                const SizedBox(width: AkeliSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: AkeliColors.primary,
                  onPressed: () {
                    _logger.userAction('Send button tapped', screen: 'GroupChatPage');
                    _sendMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }
}
```

- [ ] **Step 2: Verify analysis**

```bash
flutter analyze lib/features/community/group_chat_page.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/community/group_chat_page.dart
git commit -m "feat(dm): wire GroupChatPage to Supabase with dual constructor and Realtime"
```

---

## Task 7: GroupDetailPage — members list + DM button

**Files:**
- Modify: `lib/features/community/group_detail_page.dart`

- [ ] **Step 1: Replace group_detail_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';

class GroupDetailPage extends ConsumerWidget {
  final String groupId;
  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.provider('GroupDetailPage build() | groupId: $groupId');
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final currentUserId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: AkeliColors.background,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Détail du groupe'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              color: AkeliColors.primary.withValues(alpha: 0.1),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('👥', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      'Groupe',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AkeliSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AkeliSpacing.lg),
                  AkeliSectionHeader(
                    title: 'Membres',
                    trailingLabel: 'Inviter',
                    onTrailingTap: () {
                      appLogger.userAction('Invite tapped', screen: 'GroupDetailPage');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Inviter un ami — bientôt disponible')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  membersAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erreur: $e')),
                    data: (members) {
                      if (members.isEmpty) {
                        return const EmptyState(
                          icon: Icons.people_outline_rounded,
                          title: 'Aucun membre',
                          subtitle: 'Les membres apparaîtront ici.',
                        );
                      }
                      return Column(
                        children: members.map((member) {
                          final isMe = member.userId == currentUserId;
                          return _MemberRow(
                            member: member,
                            isMe: isMe,
                            onDmTap: () => _onDmTap(context, ref, member),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: AkeliSpacing.lg),
                  const AkeliSectionHeader(title: 'Recettes partagées'),
                  const SizedBox(height: 12),
                  const EmptyState(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Aucune recette partagée',
                    subtitle:
                        'Les recettes partagées par le groupe apparaîtront ici.',
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onDmTap(
      BuildContext context, WidgetRef ref, GroupMember member) async {
    appLogger.userAction('DM button tapped', screen: 'GroupDetailPage',
        metadata: {'targetUserId': member.userId});

    // 1. Already have a conversation?
    final existingId = await checkExistingDm(ref, member.userId);
    if (existingId != null) {
      if (context.mounted) {
        context.push(AkeliRoutes.dmChatPath(existingId), extra: member.displayName);
      }
      return;
    }

    // 2. Already sent a request?
    final pending = await checkPendingRequest(ref, member.userId);
    if (pending) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande déjà envoyée')),
        );
      }
      return;
    }

    // 3. Send new request
    await sendDmRequest(ref, member.userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demande envoyée à ${member.displayName}')),
      );
    }
  }
}

class _MemberRow extends StatelessWidget {
  final GroupMember member;
  final bool isMe;
  final VoidCallback onDmTap;

  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.onDmTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AkeliSpacing.sm),
      child: Row(
        children: [
          AkeliAvatar(
            imageUrl: member.avatarUrl,
            initials: member.displayName.isNotEmpty
                ? member.displayName[0].toUpperCase()
                : '?',
            size: AvatarSize.md,
          ),
          const SizedBox(width: AkeliSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.displayName,
                    style: Theme.of(context).textTheme.titleSmall),
                Text(
                  member.role == 'admin' ? 'Admin' : 'Membre',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AkeliColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (!isMe)
            IconButton(
              icon: const Icon(Icons.mail_outline_rounded),
              color: AkeliColors.primary,
              tooltip: 'Message privé',
              onPressed: onDmTap,
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analysis**

```bash
flutter analyze lib/features/community/group_detail_page.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/community/group_detail_page.dart
git commit -m "feat(dm): wire GroupDetailPage members list with DM button"
```

---

## Task 8: CommunityPage — 3-tab restructure

**Files:**
- Modify: `lib/features/community/community_page.dart`

- [ ] **Step 1: Replace community_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/dm_provider.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/empty_state.dart';

// ---------------------------------------------------------------------------
// Groups data (V2 placeholder)
// ---------------------------------------------------------------------------

final communityGroupsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  appLogger.provider('communityGroupsProvider build()');
  ref.onDispose(() => appLogger.provider('communityGroupsProvider disposed'));
  return [];
});

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _logger = appLogger;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _logger.provider('CommunityPage initState()');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logger.provider('CommunityPage disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('CommunityPage build()');
    final pendingAsync = ref.watch(pendingDmRequestsProvider);
    final pendingCount = pendingAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        title: const Text('Communauté'),
        backgroundColor: AkeliColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Tout'),
            const Tab(text: 'Groupes'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Privés'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AkeliColors.primary,
                        borderRadius: BorderRadius.circular(AkeliRadius.pill),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ToutTab(),
          _GroupesTab(),
          _PrivesTab(),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          if (_tabController.index != 1) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () {
              _logger.userAction('Create group FAB tapped', screen: 'CommunityPage');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Création de groupe — bientôt disponible')),
              );
            },
            backgroundColor: AkeliColors.primary,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _GroupesTab — existing groups list
// ---------------------------------------------------------------------------

class _GroupesTab extends ConsumerWidget {
  const _GroupesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(communityGroupsProvider);
    appLogger.provider('_GroupesTab build()');

    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erreur: $err')),
      data: (groups) {
        if (groups.isEmpty) {
          return const Center(
            child: Text('Aucun groupe disponible pour le moment.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AkeliSpacing.md),
          itemCount: groups.length,
          itemBuilder: (context, i) {
            final group = groups[i];
            final memberCount = (group['member_count'] as int?) ?? 0;
            final name = group['name'] as String;
            return InkWell(
              onTap: () {
                appLogger.userAction('Group card tapped', screen: 'CommunityPage',
                    metadata: {'groupId': group['id']});
                context.go(AkeliRoutes.groupChatPath(group['id'] as String));
              },
              borderRadius: BorderRadius.circular(AkeliRadius.md),
              child: Container(
                margin: const EdgeInsets.only(bottom: AkeliSpacing.sm),
                padding: const EdgeInsets.all(AkeliSpacing.md),
                decoration: BoxDecoration(
                  color: AkeliColors.surface,
                  borderRadius: BorderRadius.circular(AkeliRadius.md),
                  boxShadow: const [AkeliShadows.sm],
                ),
                child: Row(
                  children: [
                    AkeliAvatar(
                      imageUrl: group['cover_url'] as String?,
                      initials: name
                          .substring(0, name.length >= 2 ? 2 : 1)
                          .toUpperCase(),
                      size: AvatarSize.md,
                    ),
                    const SizedBox(width: AkeliSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: Theme.of(context).textTheme.titleSmall),
                          if (group['description'] != null)
                            Text(
                              group['description'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline_rounded,
                            size: 14, color: AkeliColors.textSecondary),
                        Text(
                          '$memberCount',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AkeliColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _ToutTab — merged groups + DMs
// ---------------------------------------------------------------------------

class _ToutTab extends ConsumerWidget {
  const _ToutTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.provider('_ToutTab build()');
    final groupsAsync = ref.watch(communityGroupsProvider);
    final dmsAsync = ref.watch(myPrivateConversationsProvider);

    final groups = groupsAsync.valueOrNull ?? [];
    final dms = dmsAsync.valueOrNull ?? [];

    if (groupsAsync.isLoading || dmsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (groups.isEmpty && dms.isEmpty) {
      return const EmptyState(
        icon: Icons.forum_outlined,
        title: 'Aucune conversation',
        subtitle: 'Rejoignez un groupe ou envoyez un message privé.',
      );
    }

    // Merge: groups tagged with updatedAt from community_group.updated_at (null → epoch)
    final items = <_ToutItem>[
      ...groups.map((g) => _ToutItem.group(g)),
      ...dms.map((dm) => _ToutItem.dm(dm)),
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return ListView.builder(
      padding: const EdgeInsets.all(AkeliSpacing.md),
      itemCount: items.length,
      itemBuilder: (context, i) => items[i].buildTile(context),
    );
  }
}

class _ToutItem {
  final DateTime updatedAt;
  final Widget Function(BuildContext) _buildTile;

  _ToutItem._({required this.updatedAt, required Widget Function(BuildContext) buildTile})
      : _buildTile = buildTile;

  factory _ToutItem.group(Map<String, dynamic> g) {
    final updatedAt = g['updated_at'] != null
        ? DateTime.tryParse(g['updated_at'] as String) ?? DateTime(2000)
        : DateTime(2000);
    return _ToutItem._(
      updatedAt: updatedAt,
      buildTile: (context) => ListTile(
        leading: const Icon(Icons.people_outline_rounded, color: AkeliColors.primary),
        title: Text(g['name'] as String),
        subtitle: Text('${(g['member_count'] as int?) ?? 0} membres'),
        onTap: () => context.push(AkeliRoutes.groupChatPath(g['id'] as String)),
      ),
    );
  }

  factory _ToutItem.dm(DmConversation dm) {
    return _ToutItem._(
      updatedAt: dm.updatedAt,
      buildTile: (context) => ListTile(
        leading: AkeliAvatar(
          imageUrl: dm.otherUserAvatar,
          initials: dm.otherUserName.isNotEmpty
              ? dm.otherUserName[0].toUpperCase()
              : '?',
          size: AvatarSize.sm,
        ),
        title: Text(dm.otherUserName),
        subtitle: Text(
          dm.lastMessage ?? '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: dm.unreadCount > 0
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AkeliColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => context.push(
          AkeliRoutes.dmChatPath(dm.conversationId),
          extra: dm.otherUserName,
        ),
      ),
    );
  }

  Widget buildTile(BuildContext context) => _buildTile(context);
}

// ---------------------------------------------------------------------------
// _PrivesTab — pending requests + DM list
// ---------------------------------------------------------------------------

class _PrivesTab extends ConsumerWidget {
  const _PrivesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.provider('_PrivesTab build()');
    final requestsAsync = ref.watch(pendingDmRequestsProvider);
    final dmsAsync = ref.watch(myPrivateConversationsProvider);

    final requests = requestsAsync.valueOrNull ?? [];
    final dms = dmsAsync.valueOrNull ?? [];

    if (requestsAsync.isLoading || dmsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests.isEmpty && dms.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Aucune conversation privée',
        subtitle: 'Rejoignez un groupe pour commencer.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AkeliSpacing.md),
      children: [
        if (requests.isNotEmpty) ...[
          Text(
            'Demandes en attente',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AkeliColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AkeliSpacing.sm),
          ...requests.map((req) => _RequestCard(request: req)),
          const Divider(height: AkeliSpacing.xl),
        ],
        ...dms.map((dm) => _DmTile(dm: dm)),
      ],
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final DmRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AkeliSpacing.sm),
      padding: const EdgeInsets.all(AkeliSpacing.md),
      decoration: BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: BorderRadius.circular(AkeliRadius.md),
        boxShadow: const [AkeliShadows.sm],
      ),
      child: Row(
        children: [
          AkeliAvatar(
            imageUrl: request.requesterAvatar,
            initials: request.requesterName.isNotEmpty
                ? request.requesterName[0].toUpperCase()
                : '?',
            size: AvatarSize.md,
          ),
          const SizedBox(width: AkeliSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.requesterName,
                    style: Theme.of(context).textTheme.titleSmall),
                if (request.message != null)
                  Text(
                    request.message!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _reject(context, ref),
            child: const Text('Refuser'),
          ),
          const SizedBox(width: AkeliSpacing.xs),
          FilledButton(
            onPressed: () => _accept(context, ref),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    appLogger.userAction('DM request accepted', screen: 'CommunityPage',
        metadata: {'requestId': request.requestId});
    try {
      final convId = await acceptDmRequest(ref, request.requestId, request.requesterId);
      if (context.mounted) {
        context.push(AkeliRoutes.dmChatPath(convId), extra: request.requesterName);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'acceptation')),
        );
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    appLogger.userAction('DM request rejected', screen: 'CommunityPage',
        metadata: {'requestId': request.requestId});
    await rejectDmRequest(ref, request.requestId);
  }
}

class _DmTile extends StatelessWidget {
  final DmConversation dm;
  const _DmTile({required this.dm});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AkeliAvatar(
        imageUrl: dm.otherUserAvatar,
        initials: dm.otherUserName.isNotEmpty
            ? dm.otherUserName[0].toUpperCase()
            : '?',
        size: AvatarSize.md,
      ),
      title: Text(dm.otherUserName),
      subtitle: Text(
        dm.lastMessage ?? '—',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: dm.unreadCount > 0
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AkeliColors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: () {
        appLogger.userAction('DM tile tapped', screen: 'CommunityPage',
            metadata: {'conversationId': dm.conversationId});
        context.push(AkeliRoutes.dmChatPath(dm.conversationId),
            extra: dm.otherUserName);
      },
    );
  }
}
```

- [ ] **Step 2: Verify analysis**

```bash
flutter analyze lib/features/community/
```

Expected: no errors across all three community files.

- [ ] **Step 3: Commit**

```bash
git add lib/features/community/community_page.dart
git commit -m "feat(dm): restructure CommunityPage into Tout/Groupes/Privés tabs with DM list and request flow"
```

---

## Task 9: Final verification

- [ ] **Step 1: Full project analysis**

```bash
flutter analyze
```

Expected: no errors. Warnings about deprecated APIs are acceptable.

- [ ] **Step 2: Hot-reload smoke test**

Run the app and verify:
1. Community page shows 3 tabs: Tout / Groupes / Privés
2. Group detail page shows members list (empty if no members in local DB)
3. DM button appears on member rows (not on own row)
4. Notifications back button works (from earlier fix)
5. No red screens

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat: community private DM — full feature (providers, chat, tabs, request flow)"
```
