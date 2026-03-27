// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ChatMessageStruct extends FFFirebaseStruct {
  ChatMessageStruct({
    String? content,
    int? userId,
    int? conversationId,
    bool? received,
    List<int>? readBy,
    String? createdAtParis,
    String? createdAt,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _content = content,
        _userId = userId,
        _conversationId = conversationId,
        _received = received,
        _readBy = readBy,
        _createdAtParis = createdAtParis,
        _createdAt = createdAt,
        super(firestoreUtilData);

  // "content" field.
  String? _content;
  String get content => _content ?? '';
  set content(String? val) => _content = val;

  bool hasContent() => _content != null;

  // "user_id" field.
  int? _userId;
  int get userId => _userId ?? 0;
  set userId(int? val) => _userId = val;

  void incrementUserId(int amount) => userId = userId + amount;

  bool hasUserId() => _userId != null;

  // "conversation_id" field.
  int? _conversationId;
  int get conversationId => _conversationId ?? 0;
  set conversationId(int? val) => _conversationId = val;

  void incrementConversationId(int amount) =>
      conversationId = conversationId + amount;

  bool hasConversationId() => _conversationId != null;

  // "received" field.
  bool? _received;
  bool get received => _received ?? false;
  set received(bool? val) => _received = val;

  bool hasReceived() => _received != null;

  // "read_by" field.
  List<int>? _readBy;
  List<int> get readBy => _readBy ?? const [];
  set readBy(List<int>? val) => _readBy = val;

  void updateReadBy(Function(List<int>) updateFn) {
    updateFn(_readBy ??= []);
  }

  bool hasReadBy() => _readBy != null;

  // "created_at_paris" field.
  String? _createdAtParis;
  String get createdAtParis => _createdAtParis ?? '';
  set createdAtParis(String? val) => _createdAtParis = val;

  bool hasCreatedAtParis() => _createdAtParis != null;

  // "created_at" field.
  String? _createdAt;
  String get createdAt => _createdAt ?? '';
  set createdAt(String? val) => _createdAt = val;

  bool hasCreatedAt() => _createdAt != null;

  static ChatMessageStruct fromMap(Map<String, dynamic> data) =>
      ChatMessageStruct(
        content: data['content'] as String?,
        userId: castToType<int>(data['user_id']),
        conversationId: castToType<int>(data['conversation_id']),
        received: data['received'] as bool?,
        readBy: getDataList(data['read_by']),
        createdAtParis: data['created_at_paris'] as String?,
        createdAt: data['created_at'] as String?,
      );

  static ChatMessageStruct? maybeFromMap(dynamic data) => data is Map
      ? ChatMessageStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'content': _content,
        'user_id': _userId,
        'conversation_id': _conversationId,
        'received': _received,
        'read_by': _readBy,
        'created_at_paris': _createdAtParis,
        'created_at': _createdAt,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'content': serializeParam(
          _content,
          ParamType.String,
        ),
        'user_id': serializeParam(
          _userId,
          ParamType.int,
        ),
        'conversation_id': serializeParam(
          _conversationId,
          ParamType.int,
        ),
        'received': serializeParam(
          _received,
          ParamType.bool,
        ),
        'read_by': serializeParam(
          _readBy,
          ParamType.int,
          isList: true,
        ),
        'created_at_paris': serializeParam(
          _createdAtParis,
          ParamType.String,
        ),
        'created_at': serializeParam(
          _createdAt,
          ParamType.String,
        ),
      }.withoutNulls;

  static ChatMessageStruct fromSerializableMap(Map<String, dynamic> data) =>
      ChatMessageStruct(
        content: deserializeParam(
          data['content'],
          ParamType.String,
          false,
        ),
        userId: deserializeParam(
          data['user_id'],
          ParamType.int,
          false,
        ),
        conversationId: deserializeParam(
          data['conversation_id'],
          ParamType.int,
          false,
        ),
        received: deserializeParam(
          data['received'],
          ParamType.bool,
          false,
        ),
        readBy: deserializeParam<int>(
          data['read_by'],
          ParamType.int,
          true,
        ),
        createdAtParis: deserializeParam(
          data['created_at_paris'],
          ParamType.String,
          false,
        ),
        createdAt: deserializeParam(
          data['created_at'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'ChatMessageStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is ChatMessageStruct &&
        content == other.content &&
        userId == other.userId &&
        conversationId == other.conversationId &&
        received == other.received &&
        listEquality.equals(readBy, other.readBy) &&
        createdAtParis == other.createdAtParis &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode => const ListEquality().hash([
        content,
        userId,
        conversationId,
        received,
        readBy,
        createdAtParis,
        createdAt
      ]);
}

ChatMessageStruct createChatMessageStruct({
  String? content,
  int? userId,
  int? conversationId,
  bool? received,
  String? createdAtParis,
  String? createdAt,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    ChatMessageStruct(
      content: content,
      userId: userId,
      conversationId: conversationId,
      received: received,
      createdAtParis: createdAtParis,
      createdAt: createdAt,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

ChatMessageStruct? updateChatMessageStruct(
  ChatMessageStruct? chatMessage, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    chatMessage
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addChatMessageStructData(
  Map<String, dynamic> firestoreData,
  ChatMessageStruct? chatMessage,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (chatMessage == null) {
    return;
  }
  if (chatMessage.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && chatMessage.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final chatMessageData =
      getChatMessageFirestoreData(chatMessage, forFieldValue);
  final nestedData =
      chatMessageData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = chatMessage.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getChatMessageFirestoreData(
  ChatMessageStruct? chatMessage, [
  bool forFieldValue = false,
]) {
  if (chatMessage == null) {
    return {};
  }
  final firestoreData = mapToFirestore(chatMessage.toMap());

  // Add any Firestore field values
  chatMessage.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getChatMessageListFirestoreData(
  List<ChatMessageStruct>? chatMessages,
) =>
    chatMessages?.map((e) => getChatMessageFirestoreData(e, true)).toList() ??
    [];
