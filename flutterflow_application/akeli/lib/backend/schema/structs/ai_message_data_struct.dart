// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AiMessageDataStruct extends FFFirebaseStruct {
  AiMessageDataStruct({
    AiChatMessageStruct? aiChatMessage,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _aiChatMessage = aiChatMessage,
        super(firestoreUtilData);

  // "ai_chat_message" field.
  AiChatMessageStruct? _aiChatMessage;
  AiChatMessageStruct get aiChatMessage =>
      _aiChatMessage ?? AiChatMessageStruct();
  set aiChatMessage(AiChatMessageStruct? val) => _aiChatMessage = val;

  void updateAiChatMessage(Function(AiChatMessageStruct) updateFn) {
    updateFn(_aiChatMessage ??= AiChatMessageStruct());
  }

  bool hasAiChatMessage() => _aiChatMessage != null;

  static AiMessageDataStruct fromMap(Map<String, dynamic> data) =>
      AiMessageDataStruct(
        aiChatMessage: data['ai_chat_message'] is AiChatMessageStruct
            ? data['ai_chat_message']
            : AiChatMessageStruct.maybeFromMap(data['ai_chat_message']),
      );

  static AiMessageDataStruct? maybeFromMap(dynamic data) => data is Map
      ? AiMessageDataStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'ai_chat_message': _aiChatMessage?.toMap(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'ai_chat_message': serializeParam(
          _aiChatMessage,
          ParamType.DataStruct,
        ),
      }.withoutNulls;

  static AiMessageDataStruct fromSerializableMap(Map<String, dynamic> data) =>
      AiMessageDataStruct(
        aiChatMessage: deserializeStructParam(
          data['ai_chat_message'],
          ParamType.DataStruct,
          false,
          structBuilder: AiChatMessageStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'AiMessageDataStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is AiMessageDataStruct && aiChatMessage == other.aiChatMessage;
  }

  @override
  int get hashCode => const ListEquality().hash([aiChatMessage]);
}

AiMessageDataStruct createAiMessageDataStruct({
  AiChatMessageStruct? aiChatMessage,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    AiMessageDataStruct(
      aiChatMessage:
          aiChatMessage ?? (clearUnsetFields ? AiChatMessageStruct() : null),
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

AiMessageDataStruct? updateAiMessageDataStruct(
  AiMessageDataStruct? aiMessageData, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    aiMessageData
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addAiMessageDataStructData(
  Map<String, dynamic> firestoreData,
  AiMessageDataStruct? aiMessageData,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (aiMessageData == null) {
    return;
  }
  if (aiMessageData.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && aiMessageData.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final aiMessageDataData =
      getAiMessageDataFirestoreData(aiMessageData, forFieldValue);
  final nestedData =
      aiMessageDataData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = aiMessageData.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getAiMessageDataFirestoreData(
  AiMessageDataStruct? aiMessageData, [
  bool forFieldValue = false,
]) {
  if (aiMessageData == null) {
    return {};
  }
  final firestoreData = mapToFirestore(aiMessageData.toMap());

  // Handle nested data for "ai_chat_message" field.
  addAiChatMessageStructData(
    firestoreData,
    aiMessageData.hasAiChatMessage() ? aiMessageData.aiChatMessage : null,
    'ai_chat_message',
    forFieldValue,
  );

  // Add any Firestore field values
  aiMessageData.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getAiMessageDataListFirestoreData(
  List<AiMessageDataStruct>? aiMessageDatas,
) =>
    aiMessageDatas
        ?.map((e) => getAiMessageDataFirestoreData(e, true))
        .toList() ??
    [];
