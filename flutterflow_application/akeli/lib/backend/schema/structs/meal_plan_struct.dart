// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MealPlanStruct extends FFFirebaseStruct {
  MealPlanStruct({
    String? id,
    String? userId,
    int? totalMeals,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _id = id,
        _userId = userId,
        _totalMeals = totalMeals,
        super(firestoreUtilData);

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "user_id" field.
  String? _userId;
  String get userId => _userId ?? '';
  set userId(String? val) => _userId = val;

  bool hasUserId() => _userId != null;

  // "total_meals" field.
  int? _totalMeals;
  int get totalMeals => _totalMeals ?? 0;
  set totalMeals(int? val) => _totalMeals = val;

  void incrementTotalMeals(int amount) => totalMeals = totalMeals + amount;

  bool hasTotalMeals() => _totalMeals != null;

  static MealPlanStruct fromMap(Map<String, dynamic> data) => MealPlanStruct(
        id: data['id'] as String?,
        userId: data['user_id'] as String?,
        totalMeals: castToType<int>(data['total_meals']),
      );

  static MealPlanStruct? maybeFromMap(dynamic data) =>
      data is Map ? MealPlanStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'user_id': _userId,
        'total_meals': _totalMeals,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'user_id': serializeParam(
          _userId,
          ParamType.String,
        ),
        'total_meals': serializeParam(
          _totalMeals,
          ParamType.int,
        ),
      }.withoutNulls;

  static MealPlanStruct fromSerializableMap(Map<String, dynamic> data) =>
      MealPlanStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        userId: deserializeParam(
          data['user_id'],
          ParamType.String,
          false,
        ),
        totalMeals: deserializeParam(
          data['total_meals'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'MealPlanStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is MealPlanStruct &&
        id == other.id &&
        userId == other.userId &&
        totalMeals == other.totalMeals;
  }

  @override
  int get hashCode => const ListEquality().hash([id, userId, totalMeals]);
}

MealPlanStruct createMealPlanStruct({
  String? id,
  String? userId,
  int? totalMeals,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    MealPlanStruct(
      id: id,
      userId: userId,
      totalMeals: totalMeals,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

MealPlanStruct? updateMealPlanStruct(
  MealPlanStruct? mealPlan, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    mealPlan
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addMealPlanStructData(
  Map<String, dynamic> firestoreData,
  MealPlanStruct? mealPlan,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (mealPlan == null) {
    return;
  }
  if (mealPlan.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && mealPlan.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final mealPlanData = getMealPlanFirestoreData(mealPlan, forFieldValue);
  final nestedData = mealPlanData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = mealPlan.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getMealPlanFirestoreData(
  MealPlanStruct? mealPlan, [
  bool forFieldValue = false,
]) {
  if (mealPlan == null) {
    return {};
  }
  final firestoreData = mapToFirestore(mealPlan.toMap());

  // Add any Firestore field values
  mealPlan.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getMealPlanListFirestoreData(
  List<MealPlanStruct>? mealPlans,
) =>
    mealPlans?.map((e) => getMealPlanFirestoreData(e, true)).toList() ?? [];
