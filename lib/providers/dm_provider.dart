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

  factory DmConversation.fromParts({
    required String conversationId,
    required String otherUserId,
    required String otherUserName,
    String? otherUserAvatar,
    String? lastMessage,
    required DateTime updatedAt,
    required int unreadCount,
  }) =>
      DmConversation(
        conversationId: conversationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        otherUserAvatar: otherUserAvatar,
        lastMessage: lastMessage,
        updatedAt: updatedAt,
        unreadCount: unreadCount,
      );
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

  // 1. My participations — get conversation_ids + last_read_at
  logger.db('BEFORE | table: conversation_participant | op: SELECT mine | userId: ${user.id}');
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

  // 2. Private conversations ordered by updated_at
  logger.db('BEFORE | table: conversation | op: SELECT private in | count: ${myConvIds.length}');
  final conversations = await client
      .from('conversation')
      .select('id, updated_at')
      .inFilter('id', myConvIds)
      .eq('type', 'private')
      .order('updated_at', ascending: false) as List<dynamic>;
  logger.db('AFTER | table: conversation | rows: ${conversations.length}');

  if (conversations.isEmpty) return [];

  final convIds = conversations
      .cast<Map<String, dynamic>>()
      .map((c) => c['id'] as String)
      .toList();

  // 3. Batch fetch other participants for ALL conversations in one query
  logger.db('BEFORE | table: conversation_participant | op: SELECT others batch | convs: ${convIds.length}');
  final allOthers = await client
      .from('conversation_participant')
      .select('conversation_id, user_id, user_profile:user_id(display_name, avatar_url)')
      .inFilter('conversation_id', convIds)
      .neq('user_id', user.id) as List<dynamic>;
  logger.db('AFTER | table: conversation_participant | others rows: ${allOthers.length}');

  final otherMap = <String, Map<String, dynamic>>{};
  for (final row in allOthers.cast<Map<String, dynamic>>()) {
    otherMap[row['conversation_id'] as String] = row;
  }

  // 4. Batch fetch recent messages for ALL conversations (capped at 200)
  logger.db('BEFORE | table: chat_message | op: SELECT batch | convs: ${convIds.length}');
  final allMessages = await client
      .from('chat_message')
      .select('conversation_id, content, sent_at')
      .inFilter('conversation_id', convIds)
      .order('sent_at', ascending: false)
      .limit(200) as List<dynamic>;
  logger.db('AFTER | table: chat_message | rows: ${allMessages.length}');

  // Build last-message and unread maps from the batch
  final lastMessageMap = <String, String?>{};
  final unreadCountMap = <String, int>{};

  for (final msg in allMessages.cast<Map<String, dynamic>>()) {
    final convId = msg['conversation_id'] as String;
    final sentAt = msg['sent_at'] as String;
    final content = msg['content'] as String?;

    if (!lastMessageMap.containsKey(convId)) {
      lastMessageMap[convId] = content; // first = most recent (ordered desc)
    }

    final lastRead = lastReadMap[convId];
    if (lastRead != null && sentAt.compareTo(lastRead) > 0) {
      unreadCountMap[convId] = (unreadCountMap[convId] ?? 0) + 1;
    }
  }

  // 5. Assemble DmConversation list
  final result = conversations
      .cast<Map<String, dynamic>>()
      .map((conv) {
        final convId = conv['id'] as String;
        final otherRow = otherMap[convId];
        final otherProfile = otherRow?['user_profile'] as Map<String, dynamic>?;
        return DmConversation.fromParts(
          conversationId: convId,
          otherUserId: otherRow?['user_id'] as String? ?? '',
          otherUserName: otherProfile?['display_name'] as String? ?? 'Utilisateur',
          otherUserAvatar: otherProfile?['avatar_url'] as String?,
          lastMessage: lastMessageMap[convId],
          updatedAt: DateTime.parse(conv['updated_at'] as String),
          unreadCount: unreadCountMap[convId] ?? 0,
        );
      })
      .toList();

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
  logger.db(
      'BEFORE | table: conversation_request | op: SELECT pending | userId: ${user.id}');

  try {
    final rows = await client
        .from('conversation_request')
        .select(
            'id, requester_id, message, created_at, user_profile:requester_id(display_name, avatar_url)')
        .eq('recipient_id', user.id)
        .eq('status', 'pending')
        .order('created_at', ascending: false) as List<dynamic>;

    logger.db('AFTER | table: conversation_request | rows: ${rows.length}');
    if (rows.isEmpty) {
      logger.provider('pendingDmRequestsProvider → data (empty)');
      return [];
    }

    final requests =
        rows.cast<Map<String, dynamic>>().map(DmRequest.fromJson).toList();
    logger.provider(
        'pendingDmRequestsProvider → data | count: ${requests.length}');
    return requests;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls(
          'Permission denied | table: conversation_request | userId: ${user.id}',
          error: e,
          stackTrace: st);
    } else {
      logger.db(
          'ERROR | table: conversation_request | code: ${e.code}',
          error: e,
          stackTrace: st);
    }
    rethrow;
  }
});

/// All members of a community group.
final groupMembersProvider =
    FutureProvider.autoDispose.family<List<GroupMember>, String>(
        (ref, groupId) async {
  final logger = appLogger;
  logger.provider('groupMembersProvider build() | groupId: $groupId');
  ref.onDispose(
      () => logger.provider('groupMembersProvider disposed | groupId: $groupId'));

  final client = ref.watch(supabaseClientProvider);
  logger.db(
      'BEFORE | table: group_member | op: SELECT | groupId: $groupId');

  try {
    final rows = await client
        .from('group_member')
        .select(
            'user_id, role, joined_at, user_profile:user_id(display_name, avatar_url)')
        .eq('group_id', groupId)
        .order('joined_at', ascending: true) as List<dynamic>;

    logger.db('AFTER | table: group_member | rows: ${rows.length}');
    if (rows.isEmpty) {
      logger.rls(
          'Zero rows | table: group_member | groupId: $groupId | possible RLS block');
    }
    final members =
        rows.cast<Map<String, dynamic>>().map(GroupMember.fromJson).toList();
    logger.provider(
        'groupMembersProvider → data | count: ${members.length}');
    return members;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls(
          'Permission denied | table: group_member | groupId: $groupId',
          error: e,
          stackTrace: st);
    } else {
      logger.db(
          'ERROR | table: group_member | code: ${e.code}',
          error: e,
          stackTrace: st);
    }
    rethrow;
  }
});

/// Resolves the conversation_id for a community group's chat.
final resolveConversationIdProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, groupId) async {
  final logger = appLogger;
  logger.provider(
      'resolveConversationIdProvider build() | groupId: $groupId');
  ref.onDispose(() => logger
      .provider('resolveConversationIdProvider disposed | groupId: $groupId'));

  final client = ref.watch(supabaseClientProvider);
  logger.db(
      'BEFORE | table: conversation | op: SELECT | groupId: $groupId');

  try {
    final data = await client
        .from('conversation')
        .select('id')
        .eq('community_group_id', groupId)
        .maybeSingle();

    final convId = data?['id'] as String?;
    logger.db(
        'AFTER | table: conversation | found: ${convId != null}');
    logger.provider(
        'resolveConversationIdProvider → data | conversationId: $convId');
    return convId;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls(
          'Permission denied | table: conversation | groupId: $groupId',
          error: e,
          stackTrace: st);
    } else {
      logger.db(
          'ERROR | table: conversation | code: ${e.code} | ${e.message}',
          error: e,
          stackTrace: st);
    }
    rethrow;
  }
});

/// Real-time stream of messages in a conversation, newest first.
final chatMessagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessage>, String>(
        (ref, conversationId) {
  final logger = appLogger;
  logger.provider(
      'chatMessagesProvider build() | conversationId: $conversationId');
  ref.onDispose(() => logger.provider(
      'chatMessagesProvider disposed | conversationId: $conversationId'));

  final client = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserProvider)?.id ?? '';

  logger.db(
      'BEFORE stream | table: chat_message | conversationId: $conversationId');

  return client
      .from('chat_message')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      .order('sent_at', ascending: false)
      .map((rows) {
        logger.db(
            'AFTER stream | table: chat_message | rows: ${rows.length}');
        return rows
            .map((r) => ChatMessage.fromJson(r, currentUserId: userId))
            .toList();
      });
});
