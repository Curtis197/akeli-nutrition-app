// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ConversationTypeStruct extends FFFirebaseStruct {
  ConversationTypeStruct({
    int? requesterId,
    int? conversationId,
    String? otherUserName,
    int? otherUserId,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _requesterId = requesterId,
        _conversationId = conversationId,
        _otherUserName = otherUserName,
        _otherUserId = otherUserId,
        super(firestoreUtilData);

  // "requester_id" field.
  int? _requesterId;
  int get requesterId => _requesterId ?? 0;
  set requesterId(int? val) => _requesterId = val;

  void incrementRequesterId(int amount) => requesterId = requesterId + amount;

  bool hasRequesterId() => _requesterId != null;

  // "conversation_id" field.
  int? _conversationId;
  int get conversationId => _conversationId ?? 0;
  set conversationId(int? val) => _conversationId = val;

  void incrementConversationId(int amount) =>
      conversationId = conversationId + amount;

  bool hasConversationId() => _conversationId != null;

  // "other_user_name" field.
  String? _otherUserName;
  String get otherUserName => _otherUserName ?? '';
  set otherUserName(String? val) => _otherUserName = val;

  bool hasOtherUserName() => _otherUserName != null;

  // "other_user_id" field.
  int? _otherUserId;
  int get otherUserId => _otherUserId ?? 0;
  set otherUserId(int? val) => _otherUserId = val;

  void incrementOtherUserId(int amount) => otherUserId = otherUserId + amount;

  bool hasOtherUserId() => _otherUserId != null;

  static ConversationTypeStruct fromMap(Map<String, dynamic> data) =>
      ConversationTypeStruct(
        requesterId: castToType<int>(data['requester_id']),
        conversationId: castToType<int>(data['conversation_id']),
        otherUserName: data['other_user_name'] as String?,
        otherUserId: castToType<int>(data['other_user_id']),
      );

  static ConversationTypeStruct? maybeFromMap(dynamic data) => data is Map
      ? ConversationTypeStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'requester_id': _requesterId,
        'conversation_id': _conversationId,
        'other_user_name': _otherUserName,
        'other_user_id': _otherUserId,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'requester_id': serializeParam(
          _requesterId,
          ParamType.int,
        ),
        'conversation_id': serializeParam(
          _conversationId,
          ParamType.int,
        ),
        'other_user_name': serializeParam(
          _otherUserName,
          ParamType.String,
        ),
        'other_user_id': serializeParam(
          _otherUserId,
          ParamType.int,
        ),
      }.withoutNulls;

  static ConversationTypeStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      ConversationTypeStruct(
        requesterId: deserializeParam(
          data['requester_id'],
          ParamType.int,
          false,
        ),
        conversationId: deserializeParam(
          data['conversation_id'],
          ParamType.int,
          false,
        ),
        otherUserName: deserializeParam(
          data['other_user_name'],
          ParamType.String,
          false,
        ),
        otherUserId: deserializeParam(
          data['other_user_id'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'ConversationTypeStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ConversationTypeStruct &&
        requesterId == other.requesterId &&
        conversationId == other.conversationId &&
        otherUserName == other.otherUserName &&
        otherUserId == other.otherUserId;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([requesterId, conversationId, otherUserName, otherUserId]);
}

ConversationTypeStruct createConversationTypeStruct({
  int? requesterId,
  int? conversationId,
  String? otherUserName,
  int? otherUserId,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    ConversationTypeStruct(
      requesterId: requesterId,
      conversationId: conversationId,
      otherUserName: otherUserName,
      otherUserId: otherUserId,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

ConversationTypeStruct? updateConversationTypeStruct(
  ConversationTypeStruct? conversationType, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    conversationType
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addConversationTypeStructData(
  Map<String, dynamic> firestoreData,
  ConversationTypeStruct? conversationType,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (conversationType == null) {
    return;
  }
  if (conversationType.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && conversationType.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final conversationTypeData =
      getConversationTypeFirestoreData(conversationType, forFieldValue);
  final nestedData =
      conversationTypeData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = conversationType.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getConversationTypeFirestoreData(
  ConversationTypeStruct? conversationType, [
  bool forFieldValue = false,
]) {
  if (conversationType == null) {
    return {};
  }
  final firestoreData = mapToFirestore(conversationType.toMap());

  // Add any Firestore field values
  conversationType.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getConversationTypeListFirestoreData(
  List<ConversationTypeStruct>? conversationTypes,
) =>
    conversationTypes
        ?.map((e) => getConversationTypeFirestoreData(e, true))
        .toList() ??
    [];
