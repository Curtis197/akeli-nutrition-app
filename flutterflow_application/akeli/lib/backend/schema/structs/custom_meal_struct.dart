// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CustomMealStruct extends FFFirebaseStruct {
  CustomMealStruct({
    bool? success,
    int? mealId,
    String? summary,
    int? estimatedCalories,
    MacrosStruct? macros,
    MealInfoStruct? mealInfo,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _success = success,
        _mealId = mealId,
        _summary = summary,
        _estimatedCalories = estimatedCalories,
        _macros = macros,
        _mealInfo = mealInfo,
        super(firestoreUtilData);

  // "success" field.
  bool? _success;
  bool get success => _success ?? false;
  set success(bool? val) => _success = val;

  bool hasSuccess() => _success != null;

  // "meal_id" field.
  int? _mealId;
  int get mealId => _mealId ?? 0;
  set mealId(int? val) => _mealId = val;

  void incrementMealId(int amount) => mealId = mealId + amount;

  bool hasMealId() => _mealId != null;

  // "summary" field.
  String? _summary;
  String get summary => _summary ?? '';
  set summary(String? val) => _summary = val;

  bool hasSummary() => _summary != null;

  // "estimated_calories" field.
  int? _estimatedCalories;
  int get estimatedCalories => _estimatedCalories ?? 0;
  set estimatedCalories(int? val) => _estimatedCalories = val;

  void incrementEstimatedCalories(int amount) =>
      estimatedCalories = estimatedCalories + amount;

  bool hasEstimatedCalories() => _estimatedCalories != null;

  // "macros" field.
  MacrosStruct? _macros;
  MacrosStruct get macros => _macros ?? MacrosStruct();
  set macros(MacrosStruct? val) => _macros = val;

  void updateMacros(Function(MacrosStruct) updateFn) {
    updateFn(_macros ??= MacrosStruct());
  }

  bool hasMacros() => _macros != null;

  // "meal_info" field.
  MealInfoStruct? _mealInfo;
  MealInfoStruct get mealInfo => _mealInfo ?? MealInfoStruct();
  set mealInfo(MealInfoStruct? val) => _mealInfo = val;

  void updateMealInfo(Function(MealInfoStruct) updateFn) {
    updateFn(_mealInfo ??= MealInfoStruct());
  }

  bool hasMealInfo() => _mealInfo != null;

  static CustomMealStruct fromMap(Map<String, dynamic> data) =>
      CustomMealStruct(
        success: data['success'] as bool?,
        mealId: castToType<int>(data['meal_id']),
        summary: data['summary'] as String?,
        estimatedCalories: castToType<int>(data['estimated_calories']),
        macros: data['macros'] is MacrosStruct
            ? data['macros']
            : MacrosStruct.maybeFromMap(data['macros']),
        mealInfo: data['meal_info'] is MealInfoStruct
            ? data['meal_info']
            : MealInfoStruct.maybeFromMap(data['meal_info']),
      );

  static CustomMealStruct? maybeFromMap(dynamic data) => data is Map
      ? CustomMealStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'success': _success,
        'meal_id': _mealId,
        'summary': _summary,
        'estimated_calories': _estimatedCalories,
        'macros': _macros?.toMap(),
        'meal_info': _mealInfo?.toMap(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'success': serializeParam(
          _success,
          ParamType.bool,
        ),
        'meal_id': serializeParam(
          _mealId,
          ParamType.int,
        ),
        'summary': serializeParam(
          _summary,
          ParamType.String,
        ),
        'estimated_calories': serializeParam(
          _estimatedCalories,
          ParamType.int,
        ),
        'macros': serializeParam(
          _macros,
          ParamType.DataStruct,
        ),
        'meal_info': serializeParam(
          _mealInfo,
          ParamType.DataStruct,
        ),
      }.withoutNulls;

  static CustomMealStruct fromSerializableMap(Map<String, dynamic> data) =>
      CustomMealStruct(
        success: deserializeParam(
          data['success'],
          ParamType.bool,
          false,
        ),
        mealId: deserializeParam(
          data['meal_id'],
          ParamType.int,
          false,
        ),
        summary: deserializeParam(
          data['summary'],
          ParamType.String,
          false,
        ),
        estimatedCalories: deserializeParam(
          data['estimated_calories'],
          ParamType.int,
          false,
        ),
        macros: deserializeStructParam(
          data['macros'],
          ParamType.DataStruct,
          false,
          structBuilder: MacrosStruct.fromSerializableMap,
        ),
        mealInfo: deserializeStructParam(
          data['meal_info'],
          ParamType.DataStruct,
          false,
          structBuilder: MealInfoStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'CustomMealStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is CustomMealStruct &&
        success == other.success &&
        mealId == other.mealId &&
        summary == other.summary &&
        estimatedCalories == other.estimatedCalories &&
        macros == other.macros &&
        mealInfo == other.mealInfo;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([success, mealId, summary, estimatedCalories, macros, mealInfo]);
}

CustomMealStruct createCustomMealStruct({
  bool? success,
  int? mealId,
  String? summary,
  int? estimatedCalories,
  MacrosStruct? macros,
  MealInfoStruct? mealInfo,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    CustomMealStruct(
      success: success,
      mealId: mealId,
      summary: summary,
      estimatedCalories: estimatedCalories,
      macros: macros ?? (clearUnsetFields ? MacrosStruct() : null),
      mealInfo: mealInfo ?? (clearUnsetFields ? MealInfoStruct() : null),
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

CustomMealStruct? updateCustomMealStruct(
  CustomMealStruct? customMeal, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    customMeal
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addCustomMealStructData(
  Map<String, dynamic> firestoreData,
  CustomMealStruct? customMeal,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (customMeal == null) {
    return;
  }
  if (customMeal.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && customMeal.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final customMealData = getCustomMealFirestoreData(customMeal, forFieldValue);
  final nestedData = customMealData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = customMeal.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getCustomMealFirestoreData(
  CustomMealStruct? customMeal, [
  bool forFieldValue = false,
]) {
  if (customMeal == null) {
    return {};
  }
  final firestoreData = mapToFirestore(customMeal.toMap());

  // Handle nested data for "macros" field.
  addMacrosStructData(
    firestoreData,
    customMeal.hasMacros() ? customMeal.macros : null,
    'macros',
    forFieldValue,
  );

  // Handle nested data for "meal_info" field.
  addMealInfoStructData(
    firestoreData,
    customMeal.hasMealInfo() ? customMeal.mealInfo : null,
    'meal_info',
    forFieldValue,
  );

  // Add any Firestore field values
  customMeal.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getCustomMealListFirestoreData(
  List<CustomMealStruct>? customMeals,
) =>
    customMeals?.map((e) => getCustomMealFirestoreData(e, true)).toList() ?? [];
