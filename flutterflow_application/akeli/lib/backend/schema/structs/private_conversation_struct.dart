// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PrivateConversationStruct extends FFFirebaseStruct {
  PrivateConversationStruct({
    List<ConversationsStruct>? conversations,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _conversations = conversations,
        super(firestoreUtilData);

  // "conversations" field.
  List<ConversationsStruct>? _conversations;
  List<ConversationsStruct> get conversations => _conversations ?? const [];
  set conversations(List<ConversationsStruct>? val) => _conversations = val;

  void updateConversations(Function(List<ConversationsStruct>) updateFn) {
    updateFn(_conversations ??= []);
  }

  bool hasConversations() => _conversations != null;

  static PrivateConversationStruct fromMap(Map<String, dynamic> data) =>
      PrivateConversationStruct(
        conversations: getStructList(
          data['conversations'],
          ConversationsStruct.fromMap,
        ),
      );

  static PrivateConversationStruct? maybeFromMap(dynamic data) => data is Map
      ? PrivateConversationStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'conversations': _conversations?.map((e) => e.toMap()).toList(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'conversations': serializeParam(
          _conversations,
          ParamType.DataStruct,
          isList: true,
        ),
      }.withoutNulls;

  static PrivateConversationStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      PrivateConversationStruct(
        conversations: deserializeStructParam<ConversationsStruct>(
          data['conversations'],
          ParamType.DataStruct,
          true,
          structBuilder: ConversationsStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'PrivateConversationStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is PrivateConversationStruct &&
        listEquality.equals(conversations, other.conversations);
  }

  @override
  int get hashCode => const ListEquality().hash([conversations]);
}

PrivateConversationStruct createPrivateConversationStruct({
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    PrivateConversationStruct(
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

PrivateConversationStruct? updatePrivateConversationStruct(
  PrivateConversationStruct? privateConversation, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    privateConversation
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addPrivateConversationStructData(
  Map<String, dynamic> firestoreData,
  PrivateConversationStruct? privateConversation,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (privateConversation == null) {
    return;
  }
  if (privateConversation.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && privateConversation.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final privateConversationData =
      getPrivateConversationFirestoreData(privateConversation, forFieldValue);
  final nestedData =
      privateConversationData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields =
      privateConversation.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getPrivateConversationFirestoreData(
  PrivateConversationStruct? privateConversation, [
  bool forFieldValue = false,
]) {
  if (privateConversation == null) {
    return {};
  }
  final firestoreData = mapToFirestore(privateConversation.toMap());

  // Add any Firestore field values
  privateConversation.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getPrivateConversationListFirestoreData(
  List<PrivateConversationStruct>? privateConversations,
) =>
    privateConversations
        ?.map((e) => getPrivateConversationFirestoreData(e, true))
        .toList() ??
    [];
