// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TagsStruct extends FFFirebaseStruct {
  TagsStruct({
    String? name,
    String? color,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _name = name,
        _color = color,
        super(firestoreUtilData);

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  set name(String? val) => _name = val;

  bool hasName() => _name != null;

  // "color" field.
  String? _color;
  String get color => _color ?? '';
  set color(String? val) => _color = val;

  bool hasColor() => _color != null;

  static TagsStruct fromMap(Map<String, dynamic> data) => TagsStruct(
        name: data['name'] as String?,
        color: data['color'] as String?,
      );

  static TagsStruct? maybeFromMap(dynamic data) =>
      data is Map ? TagsStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'name': _name,
        'color': _color,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'name': serializeParam(
          _name,
          ParamType.String,
        ),
        'color': serializeParam(
          _color,
          ParamType.String,
        ),
      }.withoutNulls;

  static TagsStruct fromSerializableMap(Map<String, dynamic> data) =>
      TagsStruct(
        name: deserializeParam(
          data['name'],
          ParamType.String,
          false,
        ),
        color: deserializeParam(
          data['color'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'TagsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is TagsStruct && name == other.name && color == other.color;
  }

  @override
  int get hashCode => const ListEquality().hash([name, color]);
}

TagsStruct createTagsStruct({
  String? name,
  String? color,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    TagsStruct(
      name: name,
      color: color,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

TagsStruct? updateTagsStruct(
  TagsStruct? tags, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    tags
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addTagsStructData(
  Map<String, dynamic> firestoreData,
  TagsStruct? tags,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (tags == null) {
    return;
  }
  if (tags.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields = !forFieldValue && tags.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final tagsData = getTagsFirestoreData(tags, forFieldValue);
  final nestedData = tagsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = tags.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getTagsFirestoreData(
  TagsStruct? tags, [
  bool forFieldValue = false,
]) {
  if (tags == null) {
    return {};
  }
  final firestoreData = mapToFirestore(tags.toMap());

  // Add any Firestore field values
  tags.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getTagsListFirestoreData(
  List<TagsStruct>? tagss,
) =>
    tagss?.map((e) => getTagsFirestoreData(e, true)).toList() ?? [];
