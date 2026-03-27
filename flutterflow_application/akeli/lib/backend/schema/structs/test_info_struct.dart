// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TestInfoStruct extends FFFirebaseStruct {
  TestInfoStruct({
    String? userId,
    String? receipeId,
    String? mealType,
    String? recipeName,
    String? mealId,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _userId = userId,
        _receipeId = receipeId,
        _mealType = mealType,
        _recipeName = recipeName,
        _mealId = mealId,
        super(firestoreUtilData);

  // "user_id" field.
  String? _userId;
  String get userId => _userId ?? '';
  set userId(String? val) => _userId = val;

  bool hasUserId() => _userId != null;

  // "receipe_id" field.
  String? _receipeId;
  String get receipeId => _receipeId ?? '';
  set receipeId(String? val) => _receipeId = val;

  bool hasReceipeId() => _receipeId != null;

  // "meal_type" field.
  String? _mealType;
  String get mealType => _mealType ?? '';
  set mealType(String? val) => _mealType = val;

  bool hasMealType() => _mealType != null;

  // "recipe_name" field.
  String? _recipeName;
  String get recipeName => _recipeName ?? '';
  set recipeName(String? val) => _recipeName = val;

  bool hasRecipeName() => _recipeName != null;

  // "meal_id" field.
  String? _mealId;
  String get mealId => _mealId ?? '';
  set mealId(String? val) => _mealId = val;

  bool hasMealId() => _mealId != null;

  static TestInfoStruct fromMap(Map<String, dynamic> data) => TestInfoStruct(
        userId: data['user_id'] as String?,
        receipeId: data['receipe_id'] as String?,
        mealType: data['meal_type'] as String?,
        recipeName: data['recipe_name'] as String?,
        mealId: data['meal_id'] as String?,
      );

  static TestInfoStruct? maybeFromMap(dynamic data) =>
      data is Map ? TestInfoStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'user_id': _userId,
        'receipe_id': _receipeId,
        'meal_type': _mealType,
        'recipe_name': _recipeName,
        'meal_id': _mealId,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'user_id': serializeParam(
          _userId,
          ParamType.String,
        ),
        'receipe_id': serializeParam(
          _receipeId,
          ParamType.String,
        ),
        'meal_type': serializeParam(
          _mealType,
          ParamType.String,
        ),
        'recipe_name': serializeParam(
          _recipeName,
          ParamType.String,
        ),
        'meal_id': serializeParam(
          _mealId,
          ParamType.String,
        ),
      }.withoutNulls;

  static TestInfoStruct fromSerializableMap(Map<String, dynamic> data) =>
      TestInfoStruct(
        userId: deserializeParam(
          data['user_id'],
          ParamType.String,
          false,
        ),
        receipeId: deserializeParam(
          data['receipe_id'],
          ParamType.String,
          false,
        ),
        mealType: deserializeParam(
          data['meal_type'],
          ParamType.String,
          false,
        ),
        recipeName: deserializeParam(
          data['recipe_name'],
          ParamType.String,
          false,
        ),
        mealId: deserializeParam(
          data['meal_id'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'TestInfoStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is TestInfoStruct &&
        userId == other.userId &&
        receipeId == other.receipeId &&
        mealType == other.mealType &&
        recipeName == other.recipeName &&
        mealId == other.mealId;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([userId, receipeId, mealType, recipeName, mealId]);
}

TestInfoStruct createTestInfoStruct({
  String? userId,
  String? receipeId,
  String? mealType,
  String? recipeName,
  String? mealId,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    TestInfoStruct(
      userId: userId,
      receipeId: receipeId,
      mealType: mealType,
      recipeName: recipeName,
      mealId: mealId,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

TestInfoStruct? updateTestInfoStruct(
  TestInfoStruct? testInfo, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    testInfo
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addTestInfoStructData(
  Map<String, dynamic> firestoreData,
  TestInfoStruct? testInfo,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (testInfo == null) {
    return;
  }
  if (testInfo.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && testInfo.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final testInfoData = getTestInfoFirestoreData(testInfo, forFieldValue);
  final nestedData = testInfoData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = testInfo.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getTestInfoFirestoreData(
  TestInfoStruct? testInfo, [
  bool forFieldValue = false,
]) {
  if (testInfo == null) {
    return {};
  }
  final firestoreData = mapToFirestore(testInfo.toMap());

  // Add any Firestore field values
  testInfo.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getTestInfoListFirestoreData(
  List<TestInfoStruct>? testInfos,
) =>
    testInfos?.map((e) => getTestInfoFirestoreData(e, true)).toList() ?? [];
