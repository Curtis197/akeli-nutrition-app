// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AiChatStruct extends FFFirebaseStruct {
  AiChatStruct({
    String? reply,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _reply = reply,
        super(firestoreUtilData);

  // "reply" field.
  String? _reply;
  String get reply => _reply ?? '';
  set reply(String? val) => _reply = val;

  bool hasReply() => _reply != null;

  static AiChatStruct fromMap(Map<String, dynamic> data) => AiChatStruct(
        reply: data['reply'] as String?,
      );

  static AiChatStruct? maybeFromMap(dynamic data) =>
      data is Map ? AiChatStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'reply': _reply,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'reply': serializeParam(
          _reply,
          ParamType.String,
        ),
      }.withoutNulls;

  static AiChatStruct fromSerializableMap(Map<String, dynamic> data) =>
      AiChatStruct(
        reply: deserializeParam(
          data['reply'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'AiChatStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is AiChatStruct && reply == other.reply;
  }

  @override
  int get hashCode => const ListEquality().hash([reply]);
}

AiChatStruct createAiChatStruct({
  String? reply,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    AiChatStruct(
      reply: reply,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

AiChatStruct? updateAiChatStruct(
  AiChatStruct? aiChat, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    aiChat
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addAiChatStructData(
  Map<String, dynamic> firestoreData,
  AiChatStruct? aiChat,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (aiChat == null) {
    return;
  }
  if (aiChat.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && aiChat.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final aiChatData = getAiChatFirestoreData(aiChat, forFieldValue);
  final nestedData = aiChatData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = aiChat.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getAiChatFirestoreData(
  AiChatStruct? aiChat, [
  bool forFieldValue = false,
]) {
  if (aiChat == null) {
    return {};
  }
  final firestoreData = mapToFirestore(aiChat.toMap());

  // Add any Firestore field values
  aiChat.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getAiChatListFirestoreData(
  List<AiChatStruct>? aiChats,
) =>
    aiChats?.map((e) => getAiChatFirestoreData(e, true)).toList() ?? [];
