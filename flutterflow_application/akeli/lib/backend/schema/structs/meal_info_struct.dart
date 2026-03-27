// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MealInfoStruct extends FFFirebaseStruct {
  MealInfoStruct({
    String? mealType,
    String? mealDate,
    int? userId,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _mealType = mealType,
        _mealDate = mealDate,
        _userId = userId,
        super(firestoreUtilData);

  // "meal_type" field.
  String? _mealType;
  String get mealType => _mealType ?? '';
  set mealType(String? val) => _mealType = val;

  bool hasMealType() => _mealType != null;

  // "meal_date" field.
  String? _mealDate;
  String get mealDate => _mealDate ?? '';
  set mealDate(String? val) => _mealDate = val;

  bool hasMealDate() => _mealDate != null;

  // "user_id" field.
  int? _userId;
  int get userId => _userId ?? 0;
  set userId(int? val) => _userId = val;

  void incrementUserId(int amount) => userId = userId + amount;

  bool hasUserId() => _userId != null;

  static MealInfoStruct fromMap(Map<String, dynamic> data) => MealInfoStruct(
        mealType: data['meal_type'] as String?,
        mealDate: data['meal_date'] as String?,
        userId: castToType<int>(data['user_id']),
      );

  static MealInfoStruct? maybeFromMap(dynamic data) =>
      data is Map ? MealInfoStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'meal_type': _mealType,
        'meal_date': _mealDate,
        'user_id': _userId,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'meal_type': serializeParam(
          _mealType,
          ParamType.String,
        ),
        'meal_date': serializeParam(
          _mealDate,
          ParamType.String,
        ),
        'user_id': serializeParam(
          _userId,
          ParamType.int,
        ),
      }.withoutNulls;

  static MealInfoStruct fromSerializableMap(Map<String, dynamic> data) =>
      MealInfoStruct(
        mealType: deserializeParam(
          data['meal_type'],
          ParamType.String,
          false,
        ),
        mealDate: deserializeParam(
          data['meal_date'],
          ParamType.String,
          false,
        ),
        userId: deserializeParam(
          data['user_id'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'MealInfoStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is MealInfoStruct &&
        mealType == other.mealType &&
        mealDate == other.mealDate &&
        userId == other.userId;
  }

  @override
  int get hashCode => const ListEquality().hash([mealType, mealDate, userId]);
}

MealInfoStruct createMealInfoStruct({
  String? mealType,
  String? mealDate,
  int? userId,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    MealInfoStruct(
      mealType: mealType,
      mealDate: mealDate,
      userId: userId,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

MealInfoStruct? updateMealInfoStruct(
  MealInfoStruct? mealInfo, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    mealInfo
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addMealInfoStructData(
  Map<String, dynamic> firestoreData,
  MealInfoStruct? mealInfo,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (mealInfo == null) {
    return;
  }
  if (mealInfo.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && mealInfo.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final mealInfoData = getMealInfoFirestoreData(mealInfo, forFieldValue);
  final nestedData = mealInfoData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = mealInfo.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getMealInfoFirestoreData(
  MealInfoStruct? mealInfo, [
  bool forFieldValue = false,
]) {
  if (mealInfo == null) {
    return {};
  }
  final firestoreData = mapToFirestore(mealInfo.toMap());

  // Add any Firestore field values
  mealInfo.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getMealInfoListFirestoreData(
  List<MealInfoStruct>? mealInfos,
) =>
    mealInfos?.map((e) => getMealInfoFirestoreData(e, true)).toList() ?? [];
