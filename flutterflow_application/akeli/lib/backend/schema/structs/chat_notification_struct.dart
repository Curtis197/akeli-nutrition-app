// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ChatNotificationStruct extends FFFirebaseStruct {
  ChatNotificationStruct({
    int? conversationId,
    int? senderUserId,
    String? senderName,
    int? messageId,
    String? messagePreview,
    int? unreadCount,
    String? sentAt,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _conversationId = conversationId,
        _senderUserId = senderUserId,
        _senderName = senderName,
        _messageId = messageId,
        _messagePreview = messagePreview,
        _unreadCount = unreadCount,
        _sentAt = sentAt,
        super(firestoreUtilData);

  // "conversation_id" field.
  int? _conversationId;
  int get conversationId => _conversationId ?? 0;
  set conversationId(int? val) => _conversationId = val;

  void incrementConversationId(int amount) =>
      conversationId = conversationId + amount;

  bool hasConversationId() => _conversationId != null;

  // "sender_user_id" field.
  int? _senderUserId;
  int get senderUserId => _senderUserId ?? 0;
  set senderUserId(int? val) => _senderUserId = val;

  void incrementSenderUserId(int amount) =>
      senderUserId = senderUserId + amount;

  bool hasSenderUserId() => _senderUserId != null;

  // "sender_name" field.
  String? _senderName;
  String get senderName => _senderName ?? '';
  set senderName(String? val) => _senderName = val;

  bool hasSenderName() => _senderName != null;

  // "message_id" field.
  int? _messageId;
  int get messageId => _messageId ?? 0;
  set messageId(int? val) => _messageId = val;

  void incrementMessageId(int amount) => messageId = messageId + amount;

  bool hasMessageId() => _messageId != null;

  // "message_preview" field.
  String? _messagePreview;
  String get messagePreview => _messagePreview ?? '';
  set messagePreview(String? val) => _messagePreview = val;

  bool hasMessagePreview() => _messagePreview != null;

  // "unread_count" field.
  int? _unreadCount;
  int get unreadCount => _unreadCount ?? 0;
  set unreadCount(int? val) => _unreadCount = val;

  void incrementUnreadCount(int amount) => unreadCount = unreadCount + amount;

  bool hasUnreadCount() => _unreadCount != null;

  // "sent_at" field.
  String? _sentAt;
  String get sentAt => _sentAt ?? '';
  set sentAt(String? val) => _sentAt = val;

  bool hasSentAt() => _sentAt != null;

  static ChatNotificationStruct fromMap(Map<String, dynamic> data) =>
      ChatNotificationStruct(
        conversationId: castToType<int>(data['conversation_id']),
        senderUserId: castToType<int>(data['sender_user_id']),
        senderName: data['sender_name'] as String?,
        messageId: castToType<int>(data['message_id']),
        messagePreview: data['message_preview'] as String?,
        unreadCount: castToType<int>(data['unread_count']),
        sentAt: data['sent_at'] as String?,
      );

  static ChatNotificationStruct? maybeFromMap(dynamic data) => data is Map
      ? ChatNotificationStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'conversation_id': _conversationId,
        'sender_user_id': _senderUserId,
        'sender_name': _senderName,
        'message_id': _messageId,
        'message_preview': _messagePreview,
        'unread_count': _unreadCount,
        'sent_at': _sentAt,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'conversation_id': serializeParam(
          _conversationId,
          ParamType.int,
        ),
        'sender_user_id': serializeParam(
          _senderUserId,
          ParamType.int,
        ),
        'sender_name': serializeParam(
          _senderName,
          ParamType.String,
        ),
        'message_id': serializeParam(
          _messageId,
          ParamType.int,
        ),
        'message_preview': serializeParam(
          _messagePreview,
          ParamType.String,
        ),
        'unread_count': serializeParam(
          _unreadCount,
          ParamType.int,
        ),
        'sent_at': serializeParam(
          _sentAt,
          ParamType.String,
        ),
      }.withoutNulls;

  static ChatNotificationStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      ChatNotificationStruct(
        conversationId: deserializeParam(
          data['conversation_id'],
          ParamType.int,
          false,
        ),
        senderUserId: deserializeParam(
          data['sender_user_id'],
          ParamType.int,
          false,
        ),
        senderName: deserializeParam(
          data['sender_name'],
          ParamType.String,
          false,
        ),
        messageId: deserializeParam(
          data['message_id'],
          ParamType.int,
          false,
        ),
        messagePreview: deserializeParam(
          data['message_preview'],
          ParamType.String,
          false,
        ),
        unreadCount: deserializeParam(
          data['unread_count'],
          ParamType.int,
          false,
        ),
        sentAt: deserializeParam(
          data['sent_at'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'ChatNotificationStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ChatNotificationStruct &&
        conversationId == other.conversationId &&
        senderUserId == other.senderUserId &&
        senderName == other.senderName &&
        messageId == other.messageId &&
        messagePreview == other.messagePreview &&
        unreadCount == other.unreadCount &&
        sentAt == other.sentAt;
  }

  @override
  int get hashCode => const ListEquality().hash([
        conversationId,
        senderUserId,
        senderName,
        messageId,
        messagePreview,
        unreadCount,
        sentAt
      ]);
}

ChatNotificationStruct createChatNotificationStruct({
  int? conversationId,
  int? senderUserId,
  String? senderName,
  int? messageId,
  String? messagePreview,
  int? unreadCount,
  String? sentAt,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    ChatNotificationStruct(
      conversationId: conversationId,
      senderUserId: senderUserId,
      senderName: senderName,
      messageId: messageId,
      messagePreview: messagePreview,
      unreadCount: unreadCount,
      sentAt: sentAt,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

ChatNotificationStruct? updateChatNotificationStruct(
  ChatNotificationStruct? chatNotification, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    chatNotification
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addChatNotificationStructData(
  Map<String, dynamic> firestoreData,
  ChatNotificationStruct? chatNotification,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (chatNotification == null) {
    return;
  }
  if (chatNotification.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && chatNotification.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final chatNotificationData =
      getChatNotificationFirestoreData(chatNotification, forFieldValue);
  final nestedData =
      chatNotificationData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = chatNotification.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getChatNotificationFirestoreData(
  ChatNotificationStruct? chatNotification, [
  bool forFieldValue = false,
]) {
  if (chatNotification == null) {
    return {};
  }
  final firestoreData = mapToFirestore(chatNotification.toMap());

  // Add any Firestore field values
  chatNotification.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getChatNotificationListFirestoreData(
  List<ChatNotificationStruct>? chatNotifications,
) =>
    chatNotifications
        ?.map((e) => getChatNotificationFirestoreData(e, true))
        .toList() ??
    [];
