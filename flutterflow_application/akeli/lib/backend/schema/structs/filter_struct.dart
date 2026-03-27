// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class FilterStruct extends FFFirebaseStruct {
  FilterStruct({
    String? key,
    String? value,
    String? type,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _key = key,
        _value = value,
        _type = type,
        super(firestoreUtilData);

  // "key" field.
  String? _key;
  String get key => _key ?? '';
  set key(String? val) => _key = val;

  bool hasKey() => _key != null;

  // "value" field.
  String? _value;
  String get value => _value ?? '';
  set value(String? val) => _value = val;

  bool hasValue() => _value != null;

  // "type" field.
  String? _type;
  String get type => _type ?? '';
  set type(String? val) => _type = val;

  bool hasType() => _type != null;

  static FilterStruct fromMap(Map<String, dynamic> data) => FilterStruct(
        key: data['key'] as String?,
        value: data['value'] as String?,
        type: data['type'] as String?,
      );

  static FilterStruct? maybeFromMap(dynamic data) =>
      data is Map ? FilterStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'key': _key,
        'value': _value,
        'type': _type,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'key': serializeParam(
          _key,
          ParamType.String,
        ),
        'value': serializeParam(
          _value,
          ParamType.String,
        ),
        'type': serializeParam(
          _type,
          ParamType.String,
        ),
      }.withoutNulls;

  static FilterStruct fromSerializableMap(Map<String, dynamic> data) =>
      FilterStruct(
        key: deserializeParam(
          data['key'],
          ParamType.String,
          false,
        ),
        value: deserializeParam(
          data['value'],
          ParamType.String,
          false,
        ),
        type: deserializeParam(
          data['type'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'FilterStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is FilterStruct &&
        key == other.key &&
        value == other.value &&
        type == other.type;
  }

  @override
  int get hashCode => const ListEquality().hash([key, value, type]);
}

FilterStruct createFilterStruct({
  String? key,
  String? value,
  String? type,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    FilterStruct(
      key: key,
      value: value,
      type: type,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

FilterStruct? updateFilterStruct(
  FilterStruct? filter, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    filter
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addFilterStructData(
  Map<String, dynamic> firestoreData,
  FilterStruct? filter,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (filter == null) {
    return;
  }
  if (filter.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && filter.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final filterData = getFilterFirestoreData(filter, forFieldValue);
  final nestedData = filterData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = filter.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getFilterFirestoreData(
  FilterStruct? filter, [
  bool forFieldValue = false,
]) {
  if (filter == null) {
    return {};
  }
  final firestoreData = mapToFirestore(filter.toMap());

  // Add any Firestore field values
  filter.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getFilterListFirestoreData(
  List<FilterStruct>? filters,
) =>
    filters?.map((e) => getFilterFirestoreData(e, true)).toList() ?? [];
