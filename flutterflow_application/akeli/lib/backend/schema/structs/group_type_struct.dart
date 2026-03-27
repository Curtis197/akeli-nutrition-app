// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class GroupTypeStruct extends FFFirebaseStruct {
  GroupTypeStruct({
    int? id,
    String? createdAt,
    String? name,
    String? description,
    String? imageUrl,
    int? conversationId,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _id = id,
        _createdAt = createdAt,
        _name = name,
        _description = description,
        _imageUrl = imageUrl,
        _conversationId = conversationId,
        super(firestoreUtilData);

  // "id" field.
  int? _id;
  int get id => _id ?? 0;
  set id(int? val) => _id = val;

  void incrementId(int amount) => id = id + amount;

  bool hasId() => _id != null;

  // "created_at" field.
  String? _createdAt;
  String get createdAt => _createdAt ?? '';
  set createdAt(String? val) => _createdAt = val;

  bool hasCreatedAt() => _createdAt != null;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  set name(String? val) => _name = val;

  bool hasName() => _name != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  set description(String? val) => _description = val;

  bool hasDescription() => _description != null;

  // "image_url" field.
  String? _imageUrl;
  String get imageUrl => _imageUrl ?? '';
  set imageUrl(String? val) => _imageUrl = val;

  bool hasImageUrl() => _imageUrl != null;

  // "conversation_id" field.
  int? _conversationId;
  int get conversationId => _conversationId ?? 0;
  set conversationId(int? val) => _conversationId = val;

  void incrementConversationId(int amount) =>
      conversationId = conversationId + amount;

  bool hasConversationId() => _conversationId != null;

  static GroupTypeStruct fromMap(Map<String, dynamic> data) => GroupTypeStruct(
        id: castToType<int>(data['id']),
        createdAt: data['created_at'] as String?,
        name: data['name'] as String?,
        description: data['description'] as String?,
        imageUrl: data['image_url'] as String?,
        conversationId: castToType<int>(data['conversation_id']),
      );

  static GroupTypeStruct? maybeFromMap(dynamic data) => data is Map
      ? GroupTypeStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'created_at': _createdAt,
        'name': _name,
        'description': _description,
        'image_url': _imageUrl,
        'conversation_id': _conversationId,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.int,
        ),
        'created_at': serializeParam(
          _createdAt,
          ParamType.String,
        ),
        'name': serializeParam(
          _name,
          ParamType.String,
        ),
        'description': serializeParam(
          _description,
          ParamType.String,
        ),
        'image_url': serializeParam(
          _imageUrl,
          ParamType.String,
        ),
        'conversation_id': serializeParam(
          _conversationId,
          ParamType.int,
        ),
      }.withoutNulls;

  static GroupTypeStruct fromSerializableMap(Map<String, dynamic> data) =>
      GroupTypeStruct(
        id: deserializeParam(
          data['id'],
          ParamType.int,
          false,
        ),
        createdAt: deserializeParam(
          data['created_at'],
          ParamType.String,
          false,
        ),
        name: deserializeParam(
          data['name'],
          ParamType.String,
          false,
        ),
        description: deserializeParam(
          data['description'],
          ParamType.String,
          false,
        ),
        imageUrl: deserializeParam(
          data['image_url'],
          ParamType.String,
          false,
        ),
        conversationId: deserializeParam(
          data['conversation_id'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'GroupTypeStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is GroupTypeStruct &&
        id == other.id &&
        createdAt == other.createdAt &&
        name == other.name &&
        description == other.description &&
        imageUrl == other.imageUrl &&
        conversationId == other.conversationId;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([id, createdAt, name, description, imageUrl, conversationId]);
}

GroupTypeStruct createGroupTypeStruct({
  int? id,
  String? createdAt,
  String? name,
  String? description,
  String? imageUrl,
  int? conversationId,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    GroupTypeStruct(
      id: id,
      createdAt: createdAt,
      name: name,
      description: description,
      imageUrl: imageUrl,
      conversationId: conversationId,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

GroupTypeStruct? updateGroupTypeStruct(
  GroupTypeStruct? groupType, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    groupType
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addGroupTypeStructData(
  Map<String, dynamic> firestoreData,
  GroupTypeStruct? groupType,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (groupType == null) {
    return;
  }
  if (groupType.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && groupType.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final groupTypeData = getGroupTypeFirestoreData(groupType, forFieldValue);
  final nestedData = groupTypeData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = groupType.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getGroupTypeFirestoreData(
  GroupTypeStruct? groupType, [
  bool forFieldValue = false,
]) {
  if (groupType == null) {
    return {};
  }
  final firestoreData = mapToFirestore(groupType.toMap());

  // Add any Firestore field values
  groupType.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getGroupTypeListFirestoreData(
  List<GroupTypeStruct>? groupTypes,
) =>
    groupTypes?.map((e) => getGroupTypeFirestoreData(e, true)).toList() ?? [];
