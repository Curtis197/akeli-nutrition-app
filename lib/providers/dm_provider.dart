import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../core/supabase_client.dart';
import 'auth_provider.dart';
import 'mode_provider.dart';

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
      requesterName: profile?['first_name'] as String? ?? 'Utilisateur',
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
    final firstName = (profile?['first_name'] as String? ?? '').trim();
    final username = (profile?['username'] as String? ?? '').trim();
    final displayName = firstName.isNotEmpty
        ? firstName
        : username.isNotEmpty
            ? username
            : 'Utilisateur';
    return GroupMember(
      userId: json['user_id'] as String,
      displayName: displayName,
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
  final String messageType; // 'text' | 'image' | 'recipe_share'
  final String? recipeId;
  final String? caption;
  final DateTime sentAt;
  final bool isMine;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.messageType,
    this.recipeId,
    this.caption,
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
      senderName: profile?['first_name'] as String? ?? 'Utilisateur',
      senderAvatar: profile?['avatar_url'] as String?,
      content: json['content'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      recipeId: json['recipe_id'] as String?,
      caption: json['caption'] as String?,
      sentAt: DateTime.parse(json['sent_at'] as String),
      isMine: senderId == currentUserId,
    );
  }
}

// ─── Query providers ────────────────────────────────────────────────────────

enum ConvState { none, pending, active }

class ConversationState {
  final ConvState status;
  final String? conversationId;

  const ConversationState(this.status, {this.conversationId});
}

final conversationStateProvider =
    FutureProvider.autoDispose.family<ConversationState, String>((ref, otherUserId) async {
  final logger = appLogger;
  final client = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserProvider)?.id;

  logger.provider('conversationStateProvider build() | otherUserId: $otherUserId');
  ref.onDispose(() => logger.provider('conversationStateProvider disposed'));

  if (userId == null) return const ConversationState(ConvState.none);

  // Check for existing private conversation
  logger.db('BEFORE | conversationStateProvider | checkExistingDm | otherUserId: $otherUserId');
  final mine = await client
      .from('conversation_participant')
      .select('conversation_id')
      .eq('user_id', userId) as List<dynamic>;

  if (mine.isNotEmpty) {
    final myIds = mine.cast<Map<String, dynamic>>().map((r) => r['conversation_id'] as String).toList();
    final shared = await client
        .from('conversation_participant')
        .select('conversation_id, conversation:conversation_id(type)')
        .inFilter('conversation_id', myIds)
        .eq('user_id', otherUserId) as List<dynamic>;

    for (final row in shared.cast<Map<String, dynamic>>()) {
      final conv = row['conversation'] as Map<String, dynamic>?;
      if (conv?['type'] == 'private') {
        final id = row['conversation_id'] as String;
        logger.db('AFTER | conversationStateProvider | found active DM | conversationId: $id');
        return ConversationState(ConvState.active, conversationId: id);
      }
    }
  }

  // Check for pending outbound request
  logger.db('BEFORE | conversationStateProvider | checkPendingRequest | otherUserId: $otherUserId');
  final pending = await client
      .from('conversation_request')
      .select('id')
      .eq('requester_id', userId)
      .eq('recipient_id', otherUserId)
      .eq('status', 'pending')
      .maybeSingle();

  if (pending != null) {
    logger.db('AFTER | conversationStateProvider | pending request exists');
    return const ConversationState(ConvState.pending);
  }

  logger.db('AFTER | conversationStateProvider | no relationship');
  return const ConversationState(ConvState.none);
});



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
      .select('conversation_id, user_id, user_profile:user_id(first_name, avatar_url)')
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
          otherUserName: otherProfile?['first_name'] as String? ?? 'Utilisateur',
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
            'id, requester_id, message, created_at, user_profile:requester_id(first_name, avatar_url)')
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
            'user_id, role, joined_at, user_profile:user_id(first_name, username, avatar_url)')
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

/// Fetches a userId→displayName map for all participants in a conversation.
final conversationParticipantNamesProvider =
    FutureProvider.autoDispose.family<Map<String, String>, String>((ref, conversationId) async {
  final logger = appLogger;
  logger.provider('conversationParticipantNamesProvider build() | conversationId: $conversationId');
  ref.onDispose(() => logger.provider('conversationParticipantNamesProvider disposed'));

  final client = ref.watch(supabaseClientProvider);
  logger.db('BEFORE | table: conversation_participant | op: SELECT names | conversationId: $conversationId');

  try {
    final rows = await client
        .from('conversation_participant')
        .select('user_id, user_profile:user_id(first_name, username)')
        .eq('conversation_id', conversationId) as List<dynamic>;

    logger.db('AFTER | table: conversation_participant | rows: ${rows.length}');

    final map = <String, String>{};
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final userId = row['user_id'] as String;
      final profile = row['user_profile'] as Map<String, dynamic>?;
      final firstName = (profile?['first_name'] as String? ?? '').trim();
      final username = (profile?['username'] as String? ?? '').trim();
      final name = firstName.isNotEmpty ? firstName : username;
      if (name.isNotEmpty) {
        map[userId] = name;
      }
    }
    return map;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls('Permission denied | conversationParticipantNamesProvider | conversationId: $conversationId', error: e, stackTrace: st);
    } else {
      logger.db('ERROR | conversationParticipantNamesProvider | code: ${e.code}', error: e, stackTrace: st);
    }
    return {};
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

// ─── Actions ────────────────────────────────────────────────────────────────

/// Returns the conversationId if a private DM conversation already exists
/// between the current user and [otherUserId], otherwise null.
Future<String?> checkExistingDm(WidgetRef ref, String otherUserId) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) return null;

  logger.db('BEFORE | checkExistingDm | otherUserId: $otherUserId');

  try {
    final mine = await client
        .from('conversation_participant')
        .select('conversation_id')
        .eq('user_id', userId) as List<dynamic>;

    if (mine.isEmpty) {
      logger.db('AFTER | checkExistingDm | no conversations for current user');
      return null;
    }

    final myIds = mine
        .cast<Map<String, dynamic>>()
        .map((r) => r['conversation_id'] as String)
        .toList();

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
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls('Permission denied | checkExistingDm | userId: $userId', error: e, stackTrace: st);
    } else {
      logger.db('ERROR | checkExistingDm | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
    rethrow;
  }
}

/// Returns true if a pending DM request from current user to [recipientId] exists.
Future<bool> checkPendingRequest(WidgetRef ref, String recipientId) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) return false;

  logger.db('BEFORE | checkPendingRequest | recipientId: $recipientId');

  try {
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
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls('Permission denied | checkPendingRequest | userId: $userId', error: e, stackTrace: st);
    } else {
      logger.db('ERROR | checkPendingRequest | code: ${e.code}', error: e, stackTrace: st);
    }
    rethrow;
  }
}

/// Sends a DM request from the current user to [recipientId].
Future<void> sendDmRequest(WidgetRef ref, String recipientId) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) return;

  logger.db(
      'BEFORE | table: conversation_request | op: INSERT | recipientId: $recipientId');
  try {
    await client.from('conversation_request').insert({
      'requester_id': userId,
      'recipient_id': recipientId,
      'status': 'pending',
    });
    logger.db(
        'AFTER | table: conversation_request | op: INSERT | success');
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls(
          'Permission denied | table: conversation_request | INSERT | userId: $userId',
          error: e,
          stackTrace: st);
    } else {
      logger.db(
          'ERROR | table: conversation_request | INSERT | code: ${e.code} | ${e.message}',
          error: e,
          stackTrace: st);
    }
    rethrow;
  }
}

/// Accepts a DM request via the SECURITY DEFINER RPC, which handles
/// participant insertion without RLS conflicts.
/// Returns the new conversationId.
Future<String> acceptDmRequest(
  WidgetRef ref,
  String requestId,
) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);

  logger.db('BEFORE | rpc: respond_conversation_request | action: accepted | requestId: $requestId');

  try {
    final result = await client.rpc('respond_conversation_request', params: {
      'p_request_id': requestId,
      'p_action': 'accepted',
    }) as Map<String, dynamic>;

    final conversationId = result['conversation_id'] as String;
    logger.db('AFTER | rpc: respond_conversation_request | conversationId: $conversationId');

    ref.invalidate(myPrivateConversationsProvider);
    ref.invalidate(pendingDmRequestsProvider);

    return conversationId;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls('Permission denied | rpc: respond_conversation_request | requestId: $requestId', error: e, stackTrace: st);
    } else {
      logger.db('ERROR | rpc: respond_conversation_request | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
    rethrow;
  }
}

/// Rejects a DM request via the SECURITY DEFINER RPC.
Future<void> rejectDmRequest(WidgetRef ref, String requestId) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);

  logger.db('BEFORE | rpc: respond_conversation_request | action: rejected | requestId: $requestId');

  try {
    await client.rpc('respond_conversation_request', params: {
      'p_request_id': requestId,
      'p_action': 'rejected',
    });
    logger.db('AFTER | rpc: respond_conversation_request | rejected');
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls('Permission denied | rpc: respond_conversation_request | requestId: $requestId', error: e, stackTrace: st);
    } else {
      logger.db('ERROR | rpc: respond_conversation_request | code: ${e.code}', error: e, stackTrace: st);
    }
    rethrow;
  }

  ref.invalidate(pendingDmRequestsProvider);
}

/// Sends a text message in a conversation and updates conversation.updated_at.
/// Uploads an image to the chat_media bucket and returns its public URL.
Future<String> uploadChatImage(
  WidgetRef ref,
  Uint8List bytes,
  String extension,
) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) throw Exception('User not logged in');

  // Normalize extension: heic/heif encode as JPEG, and 'jpg' is not a valid MIME subtype.
  const extToMime = {
    'jpg': 'jpeg',
    'heic': 'jpeg',
    'heif': 'jpeg',
  };
  final mimeSubtype = extToMime[extension] ?? extension;
  final uploadExt = mimeSubtype; // keep stored file as .jpeg/.png/etc.
  final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$uploadExt';
  logger.db('BEFORE | storage: chat_media | op: UPLOAD | path: $path | mime: image/$mimeSubtype');
  try {
    await client.storage.from('chat_media').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(upsert: false, contentType: 'image/$mimeSubtype'),
    );
    final url = client.storage.from('chat_media').getPublicUrl(path);
    logger.db('AFTER | storage: chat_media | op: UPLOAD | url: $url');
    return url;
  } on StorageException catch (e, st) {
    logger.db('ERROR | storage: chat_media | UPLOAD | code: ${e.statusCode}', error: e, stackTrace: st);
    rethrow;
  }
}

Future<void> sendMessage(
  WidgetRef ref,
  String conversationId,
  String content, {
  String messageType = 'text',
  String? recipeId,
  String? caption,
}) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) return;

  logger.db(
      'BEFORE | table: chat_message | op: INSERT | conversationId: $conversationId | type: $messageType');
  try {
    await client.from('chat_message').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'content': content,
      'message_type': messageType,
      if (recipeId != null) 'recipe_id': recipeId,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
    });
    logger.db('AFTER | table: chat_message | inserted | type: $messageType');

    await client
        .from('conversation')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);
    logger.db('AFTER | table: conversation | updated_at bumped');
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls(
          'Permission denied | table: chat_message | INSERT | conversationId: $conversationId',
          error: e,
          stackTrace: st);
    } else {
      logger.db(
          'ERROR | table: chat_message | INSERT | code: ${e.code}',
          error: e,
          stackTrace: st);
    }
    rethrow;
  }

  // chatMessagesProvider is a realtime stream — it updates automatically.
  // Only invalidate the conversation list so the "last message" preview refreshes.
  ref.invalidate(myPrivateConversationsProvider);
}

/// Updates last_read_at for the current user in a conversation (clears unread badge).
Future<void> markConversationRead(WidgetRef ref, String conversationId) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) return;

  logger.db(
      'BEFORE | table: conversation_participant | op: UPDATE last_read_at | conversationId: $conversationId');
  try {
    await client
        .from('conversation_participant')
        .update({'last_read_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
    logger.db(
        'AFTER | table: conversation_participant | last_read_at updated');
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls(
          'Permission denied | table: conversation_participant | UPDATE last_read_at | conversationId: $conversationId',
          error: e,
          stackTrace: st);
    } else {
      logger.db(
          'ERROR | table: conversation_participant | UPDATE last_read_at | code: ${e.code}',
          error: e,
          stackTrace: st);
    }
    rethrow;
  }

  ref.invalidate(myPrivateConversationsProvider);
}

/// Soft-leaves a DM conversation (deletes the current user's participant row).
Future<void> leaveDmConversation(WidgetRef ref, String conversationId) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) return;

  logger.db(
      'BEFORE | table: conversation_participant | op: DELETE | conversationId: $conversationId');
  try {
    await client
        .from('conversation_participant')
        .delete()
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
    logger.db('AFTER | table: conversation_participant | deleted for current user');
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls(
          'Permission denied | table: conversation_participant | DELETE | conversationId: $conversationId',
          error: e,
          stackTrace: st);
    } else {
      logger.db(
          'ERROR | table: conversation_participant | DELETE | code: ${e.code}',
          error: e,
          stackTrace: st);
    }
    rethrow;
  }

  ref.invalidate(myPrivateConversationsProvider);
}

/// Creates a new community group and returns its ID.
Future<String> createGroup(
  WidgetRef ref, {
  required String name,
  String? description,
  bool isPublic = true,
  Uint8List? coverImageBytes,
  String? coverImageExtension,
}) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) throw Exception('User not logged in');

  logger.db('BEFORE | createGroup | name: $name');

  try {
    // 1. Create group
    logger.db('BEFORE | table: community_group | op: INSERT');
    
    // Upload image if provided
    String? coverUrl;
    if (coverImageBytes != null && coverImageExtension != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.$coverImageExtension';
      final imagePath = 'covers/$fileName';
      logger.db('BEFORE | storage: group_covers | op: UPLOAD | path: $imagePath');
      await client.storage.from('group_covers').uploadBinary(
        imagePath,
        coverImageBytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: 'image/$coverImageExtension',
        ),
      );
      coverUrl = client.storage.from('group_covers').getPublicUrl(imagePath);
      logger.db('AFTER | storage: group_covers | op: UPLOAD | url: $coverUrl');
    }

    final appMode = ref.read(currentModeProvider);
    final activeMode = appMode == AppMode.beauty ? 'beauty' : 'nutrition';

    final groupResult = await client
        .from('community_group')
        .insert({
          'name': name,
          'description': description?.isNotEmpty == true ? description : null,
          'is_public': isPublic,
          'creator_id': userId,
          'mode': activeMode,
          if (coverUrl != null) 'cover_url': coverUrl,
        })
        .select('id')
        .single();
    final groupId = groupResult['id'] as String;
    logger.db('AFTER | table: community_group | groupId: $groupId');

    // 2. Add creator as admin
    logger.db('BEFORE | table: group_member | op: INSERT | role: admin');
    await client.from('group_member').insert({
      'group_id': groupId,
      'user_id': userId,
      'role': 'admin',
    });

    // 3. Create conversation for the group
    logger.db('BEFORE | table: conversation | op: INSERT | type: creator_group');
    final convResult = await client
        .from('conversation')
        .insert({
          'type': 'creator_group',
          'community_group_id': groupId,
          'created_by': userId,
          'mode': activeMode,
        })
        .select('id')
        .single();
    final conversationId = convResult['id'] as String;

    // 4. Add creator to the conversation
    logger.db('BEFORE | table: conversation_participant | op: INSERT | conversationId: $conversationId');
    await client.from('conversation_participant').insert({
      'conversation_id': conversationId,
      'user_id': userId,
    });
    
    logger.db('AFTER | createGroup sequence completed | groupId: $groupId');
    return groupId;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls('Permission denied | createGroup', error: e, stackTrace: st);
    } else {
      logger.db('ERROR | createGroup | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
    rethrow;
  }
}

/// Updates the cover image of a community group.
Future<void> updateGroupCover(
  WidgetRef ref,
  String groupId,
  Uint8List imageBytes,
  String extension,
) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) throw Exception('User not logged in');

  logger.db('BEFORE | updateGroupCover | groupId: $groupId');

  try {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.$extension';
    final imagePath = 'covers/$fileName';
    
    logger.db('BEFORE | storage: group_covers | op: UPLOAD | path: $imagePath');
    await client.storage.from('group_covers').uploadBinary(
      imagePath,
      imageBytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: 'image/$extension',
      ),
    );
    final coverUrl = client.storage.from('group_covers').getPublicUrl(imagePath);
    logger.db('AFTER | storage: group_covers | op: UPLOAD | url: $coverUrl');

    logger.db('BEFORE | table: community_group | op: UPDATE | cover_url');
    await client
        .from('community_group')
        .update({'cover_url': coverUrl})
        .eq('id', groupId);
    logger.db('AFTER | table: community_group | op: UPDATE | cover_url');
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls('Permission denied | updateGroupCover', error: e, stackTrace: st);
    } else {
      logger.db('ERROR | updateGroupCover | code: ${e.code}', error: e, stackTrace: st);
    }
    rethrow;
  }
}

// ---------------------------------------------------------------------------
// Group details — for the edit sheet and admin check
// ---------------------------------------------------------------------------

final groupDetailsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, groupId) async {
  appLogger.provider('groupDetailsProvider build() | groupId: $groupId');
  ref.onDispose(() => appLogger.provider('groupDetailsProvider disposed | groupId: $groupId'));

  final client = ref.watch(supabaseClientProvider);
  appLogger.db('BEFORE | table: v_community_group | op: SELECT | groupId: $groupId');

  try {
    final data = await client
        .from('v_community_group')
        .select('id, name, description, is_public, creator_id, region_code, language, topic, max_members, member_count, cover_url')
        .eq('id', groupId)
        .maybeSingle();
    appLogger.db('AFTER | table: community_group | rows: ${data == null ? 0 : 1}');
    if (data == null) appLogger.rls('Zero rows | table: community_group | groupId: $groupId | possible RLS block');
    return data;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: community_group | groupId: $groupId', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: community_group | code: ${e.code}', error: e, stackTrace: st);
    }
    rethrow;
  }
});

/// Shared image URLs in a group's conversation, ordered newest-first.
final groupSharedImagesProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, groupId) async {
  appLogger.provider('groupSharedImagesProvider build() | groupId: $groupId');
  ref.onDispose(() => appLogger.provider('groupSharedImagesProvider disposed | groupId: $groupId'));

  final client = ref.watch(supabaseClientProvider);
  final conversationId = await ref.watch(resolveConversationIdProvider(groupId).future);
  if (conversationId == null) {
    appLogger.provider('groupSharedImagesProvider → no conversation found');
    return [];
  }
  appLogger.db('BEFORE | table: chat_message | op: SELECT | type: image | conversationId: $conversationId');

  try {
    final data = await client
        .from('chat_message')
        .select('content')
        .eq('conversation_id', conversationId)
        .eq('message_type', 'image')
        .order('sent_at', ascending: false)
        .limit(100) as List<dynamic>;

    final urls = data.cast<Map<String, dynamic>>().map((r) => r['content'] as String).toList();
    appLogger.db('AFTER | table: chat_message | rows: ${urls.length}');
    return urls;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: chat_message | conversationId: $conversationId', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: chat_message | code: ${e.code}', error: e, stackTrace: st);
    }
    rethrow;
  }
});

/// Shared recipe IDs in a group's conversation, ordered newest-first (deduped).
final groupSharedRecipesProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, groupId) async {
  appLogger.provider('groupSharedRecipesProvider build() | groupId: $groupId');
  ref.onDispose(() => appLogger.provider('groupSharedRecipesProvider disposed | groupId: $groupId'));

  final client = ref.watch(supabaseClientProvider);
  final conversationId = await ref.watch(resolveConversationIdProvider(groupId).future);
  if (conversationId == null) {
    appLogger.provider('groupSharedRecipesProvider → no conversation found');
    return [];
  }
  appLogger.db('BEFORE | table: chat_message | op: SELECT | type: recipe_share | conversationId: $conversationId');

  try {
    final data = await client
        .from('chat_message')
        .select('recipe_id')
        .eq('conversation_id', conversationId)
        .eq('message_type', 'recipe_share')
        .not('recipe_id', 'is', null)
        .order('sent_at', ascending: false)
        .limit(100) as List<dynamic>;

    // Deduplicate while preserving first-seen order
    final seen = <String>{};
    final ids = data
        .cast<Map<String, dynamic>>()
        .map((r) => r['recipe_id'] as String)
        .where(seen.add)
        .toList();
    appLogger.db('AFTER | table: chat_message | recipes: ${ids.length} (deduped)');
    return ids;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: chat_message | conversationId: $conversationId', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: chat_message | code: ${e.code}', error: e, stackTrace: st);
    }
    rethrow;
  }
});

Future<void> updateGroup(
  WidgetRef ref, {
  required String groupId,
  required String name,
  String? description,
  required bool isPublic,
  String? regionId,
  String? language,
  String? topic,
  int? maxMembers,
}) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) throw Exception('User not logged in');

  final updateData = {
    'name': name,
    'description': description?.isNotEmpty == true ? description : null,
    'is_public': isPublic,
    'region_code': regionId,
    'language': language,
    'topic': topic,
    'max_members': maxMembers,
  };

  logger.userAction('Update group', metadata: {'groupId': groupId, 'input': updateData});
  logger.db('BEFORE | table: community_group | op: UPDATE | groupId: $groupId');

  try {
    final response = await client
        .from('community_group')
        .update(updateData)
        .eq('id', groupId)
        .eq('creator_id', userId)
        .select()
        .single();
        
    logger.db('AFTER | table: community_group | op: UPDATE | row: $response');
    ref.invalidate(groupDetailsProvider(groupId));
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls('Permission denied | table: community_group | UPDATE | groupId: $groupId', error: e, stackTrace: st);
    } else {
      logger.db('ERROR | table: community_group | UPDATE | code: ${e.code}', error: e, stackTrace: st);
    }
    rethrow;
  }
}

// ---------------------------------------------------------------------------
// Group Browsing
// ---------------------------------------------------------------------------

class BrowseGroupsParams {
  final String? userId;
  final String? regionId;
  final String? language;
  final String? topic;
  final String? mode;

  const BrowseGroupsParams({this.userId, this.regionId, this.language, this.topic, this.mode});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrowseGroupsParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          regionId == other.regionId &&
          language == other.language &&
          topic == other.topic &&
          mode == other.mode;

  @override
  int get hashCode =>
      userId.hashCode ^ regionId.hashCode ^ language.hashCode ^ topic.hashCode ^ mode.hashCode;
}

final browseGroupsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, BrowseGroupsParams>((ref, params) async {
  final logger = appLogger;
  logger.provider('browseGroupsProvider build()');
  ref.onDispose(() => logger.provider('browseGroupsProvider disposed'));

  final client = ref.watch(supabaseClientProvider);
  // Finding #7 fix: resolve the effective mode from params.mode if the
  // caller set one explicitly, otherwise from the globally active mode.
  // This fixes browse_groups_page.dart's call site (which never sets
  // `mode` today) with no change needed to that file.
  final effectiveMode = params.mode ?? ref.watch(currentModeProvider).name;

  final hasFilters = params.regionId != null || params.language != null || params.topic != null;

  try {
    if (!hasFilters && params.userId != null) {
      // Path 1: Personalized RPC
      logger.db('BEFORE | RPC: generate_groups_personalized | mode: $effectiveMode');
      try {
        final rpcResult = await client
            .rpc('generate_groups_personalized', params: {
              'p_user_id': params.userId,
              'p_limit': 50,
              'p_mode': effectiveMode,
            }) as List<dynamic>;

        logger.db('AFTER | RPC: generate_groups_personalized | rows: ${rpcResult.length}');

        if (rpcResult.isNotEmpty) {
          final groupIds = rpcResult
              .cast<Map<String, dynamic>>()
              .map((r) => r['group_id'] as String)
              .toList();

          logger.db('BEFORE | table: v_community_group | op: SELECT public IN');
          final groupsData = await client
              .from('v_community_group')
              .select('id, name, description, member_count, max_members, region_code, language, topic, creator_id, cover_url')
              .inFilter('id', groupIds);

          final groupsMap = {
            for (final g in groupsData.cast<Map<String, dynamic>>())
              g['id'] as String: g
          };

          final orderedGroups = groupIds
              .map((id) => groupsMap[id])
              .whereType<Map<String, dynamic>>()
              .toList();

          if (orderedGroups.isNotEmpty) return orderedGroups;
          // RPC returned IDs but none had group_vector rows yet — fall through to direct query
        }
      } catch (rpcError, st) {
        logger.db('ERROR | RPC: generate_groups_personalized | fallback to direct query', error: rpcError, stackTrace: st);
      }
    }

    // Path 2 or Fallback: Direct query — also mode-scoped (Finding #7:
    // this direct/fallback path previously had no mode filter at all).
    logger.db('BEFORE | table: v_community_group | op: SELECT public (direct) | mode: $effectiveMode');
    var query = client
        .from('v_community_group')
        .select('id, name, description, member_count, max_members, region_code, language, topic, creator_id, cover_url')
        .eq('is_public', true)
        .eq('app_mode', effectiveMode);

    if (params.regionId != null) query = query.eq('region_code', params.regionId!);
    if (params.language != null) query = query.eq('language', params.language!);
    if (params.topic != null) query = query.eq('topic', params.topic!);

    final rows = await query.order('member_count', ascending: false).limit(50);

    logger.db('AFTER | table: community_group | rows: ${rows.length}');
    return List<Map<String, dynamic>>.from(rows);
  } on PostgrestException catch (e, st) {
    logger.db('ERROR | table: community_group | SELECT public | code: ${e.code}', error: e, stackTrace: st);
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Group Invitations
// ---------------------------------------------------------------------------

/// Pending invites sent for a group (admin view)
final pendingGroupInvitesProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, groupId) async {
  final logger = appLogger;
  logger.provider('pendingGroupInvitesProvider build() | groupId: $groupId');
  ref.onDispose(() => logger.provider('pendingGroupInvitesProvider disposed | groupId: $groupId'));

  final client = ref.watch(supabaseClientProvider);
  logger.db('BEFORE | table: group_invite | op: SELECT | groupId: $groupId');

  try {
    final rows = await client
        .from('group_invite')
        .select('invitee_id')
        .eq('group_id', groupId)
        .eq('status', 'pending') as List<dynamic>;

    logger.db('AFTER | table: group_invite | rows: ${rows.length}');
    
    final invites = rows.map((row) => row['invitee_id'] as String).toList();
    return invites;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls('Permission denied | table: group_invite | SELECT | groupId: $groupId', error: e, stackTrace: st);
    } else {
      logger.db('ERROR | table: group_invite | SELECT | code: ${e.code}', error: e, stackTrace: st);
    }
    rethrow;
  }
});
