// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class GroupByNameTypeStruct extends FFFirebaseStruct {
  GroupByNameTypeStruct({
    int? requesterId,
    int? conversationId,
    String? groupName,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _requesterId = requesterId,
        _conversationId = conversationId,
        _groupName = groupName,
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

  // "group_name" field.
  String? _groupName;
  String get groupName => _groupName ?? '';
  set groupName(String? val) => _groupName = val;

  bool hasGroupName() => _groupName != null;

  static GroupByNameTypeStruct fromMap(Map<String, dynamic> data) =>
      GroupByNameTypeStruct(
        requesterId: castToType<int>(data['requester_id']),
        conversationId: castToType<int>(data['conversation_id']),
        groupName: data['group_name'] as String?,
      );

  static GroupByNameTypeStruct? maybeFromMap(dynamic data) => data is Map
      ? GroupByNameTypeStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'requester_id': _requesterId,
        'conversation_id': _conversationId,
        'group_name': _groupName,
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
        'group_name': serializeParam(
          _groupName,
          ParamType.String,
        ),
      }.withoutNulls;

  static GroupByNameTypeStruct fromSerializableMap(Map<String, dynamic> data) =>
      GroupByNameTypeStruct(
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
        groupName: deserializeParam(
          data['group_name'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'GroupByNameTypeStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is GroupByNameTypeStruct &&
        requesterId == other.requesterId &&
        conversationId == other.conversationId &&
        groupName == other.groupName;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([requesterId, conversationId, groupName]);
}

GroupByNameTypeStruct createGroupByNameTypeStruct({
  int? requesterId,
  int? conversationId,
  String? groupName,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    GroupByNameTypeStruct(
      requesterId: requesterId,
      conversationId: conversationId,
      groupName: groupName,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

GroupByNameTypeStruct? updateGroupByNameTypeStruct(
  GroupByNameTypeStruct? groupByNameType, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    groupByNameType
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addGroupByNameTypeStructData(
  Map<String, dynamic> firestoreData,
  GroupByNameTypeStruct? groupByNameType,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (groupByNameType == null) {
    return;
  }
  if (groupByNameType.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && groupByNameType.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final groupByNameTypeData =
      getGroupByNameTypeFirestoreData(groupByNameType, forFieldValue);
  final nestedData =
      groupByNameTypeData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = groupByNameType.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getGroupByNameTypeFirestoreData(
  GroupByNameTypeStruct? groupByNameType, [
  bool forFieldValue = false,
]) {
  if (groupByNameType == null) {
    return {};
  }
  final firestoreData = mapToFirestore(groupByNameType.toMap());

  // Add any Firestore field values
  groupByNameType.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getGroupByNameTypeListFirestoreData(
  List<GroupByNameTypeStruct>? groupByNameTypes,
) =>
    groupByNameTypes
        ?.map((e) => getGroupByNameTypeFirestoreData(e, true))
        .toList() ??
    [];
