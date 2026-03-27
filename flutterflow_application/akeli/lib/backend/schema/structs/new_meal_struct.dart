// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class NewMealStruct extends FFFirebaseStruct {
  NewMealStruct({
    bool? success,
    int? mealId,
    String? mealType,
    String? mealDate,
    int? adjustedCalories,
    int? adjustedProtein,
    int? adjustedCarbs,
    int? adjustedFat,
    List<String>? ingredients,
    double? scaleFactor,
    bool? usingFallbackCalories,
    int? targetCaloriesUsed,
    bool? macrosFound,
    DebugInfoStruct? debugInfo,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _success = success,
        _mealId = mealId,
        _mealType = mealType,
        _mealDate = mealDate,
        _adjustedCalories = adjustedCalories,
        _adjustedProtein = adjustedProtein,
        _adjustedCarbs = adjustedCarbs,
        _adjustedFat = adjustedFat,
        _ingredients = ingredients,
        _scaleFactor = scaleFactor,
        _usingFallbackCalories = usingFallbackCalories,
        _targetCaloriesUsed = targetCaloriesUsed,
        _macrosFound = macrosFound,
        _debugInfo = debugInfo,
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

  // "adjusted_calories" field.
  int? _adjustedCalories;
  int get adjustedCalories => _adjustedCalories ?? 0;
  set adjustedCalories(int? val) => _adjustedCalories = val;

  void incrementAdjustedCalories(int amount) =>
      adjustedCalories = adjustedCalories + amount;

  bool hasAdjustedCalories() => _adjustedCalories != null;

  // "adjusted_protein" field.
  int? _adjustedProtein;
  int get adjustedProtein => _adjustedProtein ?? 0;
  set adjustedProtein(int? val) => _adjustedProtein = val;

  void incrementAdjustedProtein(int amount) =>
      adjustedProtein = adjustedProtein + amount;

  bool hasAdjustedProtein() => _adjustedProtein != null;

  // "adjusted_carbs" field.
  int? _adjustedCarbs;
  int get adjustedCarbs => _adjustedCarbs ?? 0;
  set adjustedCarbs(int? val) => _adjustedCarbs = val;

  void incrementAdjustedCarbs(int amount) =>
      adjustedCarbs = adjustedCarbs + amount;

  bool hasAdjustedCarbs() => _adjustedCarbs != null;

  // "adjusted_fat" field.
  int? _adjustedFat;
  int get adjustedFat => _adjustedFat ?? 0;
  set adjustedFat(int? val) => _adjustedFat = val;

  void incrementAdjustedFat(int amount) => adjustedFat = adjustedFat + amount;

  bool hasAdjustedFat() => _adjustedFat != null;

  // "ingredients" field.
  List<String>? _ingredients;
  List<String> get ingredients => _ingredients ?? const [];
  set ingredients(List<String>? val) => _ingredients = val;

  void updateIngredients(Function(List<String>) updateFn) {
    updateFn(_ingredients ??= []);
  }

  bool hasIngredients() => _ingredients != null;

  // "scale_factor" field.
  double? _scaleFactor;
  double get scaleFactor => _scaleFactor ?? 0.0;
  set scaleFactor(double? val) => _scaleFactor = val;

  void incrementScaleFactor(double amount) =>
      scaleFactor = scaleFactor + amount;

  bool hasScaleFactor() => _scaleFactor != null;

  // "using_fallback_calories" field.
  bool? _usingFallbackCalories;
  bool get usingFallbackCalories => _usingFallbackCalories ?? false;
  set usingFallbackCalories(bool? val) => _usingFallbackCalories = val;

  bool hasUsingFallbackCalories() => _usingFallbackCalories != null;

  // "target_calories_used" field.
  int? _targetCaloriesUsed;
  int get targetCaloriesUsed => _targetCaloriesUsed ?? 0;
  set targetCaloriesUsed(int? val) => _targetCaloriesUsed = val;

  void incrementTargetCaloriesUsed(int amount) =>
      targetCaloriesUsed = targetCaloriesUsed + amount;

  bool hasTargetCaloriesUsed() => _targetCaloriesUsed != null;

  // "macros_found" field.
  bool? _macrosFound;
  bool get macrosFound => _macrosFound ?? false;
  set macrosFound(bool? val) => _macrosFound = val;

  bool hasMacrosFound() => _macrosFound != null;

  // "debug_info" field.
  DebugInfoStruct? _debugInfo;
  DebugInfoStruct get debugInfo => _debugInfo ?? DebugInfoStruct();
  set debugInfo(DebugInfoStruct? val) => _debugInfo = val;

  void updateDebugInfo(Function(DebugInfoStruct) updateFn) {
    updateFn(_debugInfo ??= DebugInfoStruct());
  }

  bool hasDebugInfo() => _debugInfo != null;

  static NewMealStruct fromMap(Map<String, dynamic> data) => NewMealStruct(
        success: data['success'] as bool?,
        mealId: castToType<int>(data['meal_id']),
        mealType: data['meal_type'] as String?,
        mealDate: data['meal_date'] as String?,
        adjustedCalories: castToType<int>(data['adjusted_calories']),
        adjustedProtein: castToType<int>(data['adjusted_protein']),
        adjustedCarbs: castToType<int>(data['adjusted_carbs']),
        adjustedFat: castToType<int>(data['adjusted_fat']),
        ingredients: getDataList(data['ingredients']),
        scaleFactor: castToType<double>(data['scale_factor']),
        usingFallbackCalories: data['using_fallback_calories'] as bool?,
        targetCaloriesUsed: castToType<int>(data['target_calories_used']),
        macrosFound: data['macros_found'] as bool?,
        debugInfo: data['debug_info'] is DebugInfoStruct
            ? data['debug_info']
            : DebugInfoStruct.maybeFromMap(data['debug_info']),
      );

  static NewMealStruct? maybeFromMap(dynamic data) =>
      data is Map ? NewMealStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'success': _success,
        'meal_id': _mealId,
        'meal_type': _mealType,
        'meal_date': _mealDate,
        'adjusted_calories': _adjustedCalories,
        'adjusted_protein': _adjustedProtein,
        'adjusted_carbs': _adjustedCarbs,
        'adjusted_fat': _adjustedFat,
        'ingredients': _ingredients,
        'scale_factor': _scaleFactor,
        'using_fallback_calories': _usingFallbackCalories,
        'target_calories_used': _targetCaloriesUsed,
        'macros_found': _macrosFound,
        'debug_info': _debugInfo?.toMap(),
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
        'meal_type': serializeParam(
          _mealType,
          ParamType.String,
        ),
        'meal_date': serializeParam(
          _mealDate,
          ParamType.String,
        ),
        'adjusted_calories': serializeParam(
          _adjustedCalories,
          ParamType.int,
        ),
        'adjusted_protein': serializeParam(
          _adjustedProtein,
          ParamType.int,
        ),
        'adjusted_carbs': serializeParam(
          _adjustedCarbs,
          ParamType.int,
        ),
        'adjusted_fat': serializeParam(
          _adjustedFat,
          ParamType.int,
        ),
        'ingredients': serializeParam(
          _ingredients,
          ParamType.String,
          isList: true,
        ),
        'scale_factor': serializeParam(
          _scaleFactor,
          ParamType.double,
        ),
        'using_fallback_calories': serializeParam(
          _usingFallbackCalories,
          ParamType.bool,
        ),
        'target_calories_used': serializeParam(
          _targetCaloriesUsed,
          ParamType.int,
        ),
        'macros_found': serializeParam(
          _macrosFound,
          ParamType.bool,
        ),
        'debug_info': serializeParam(
          _debugInfo,
          ParamType.DataStruct,
        ),
      }.withoutNulls;

  static NewMealStruct fromSerializableMap(Map<String, dynamic> data) =>
      NewMealStruct(
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
        adjustedCalories: deserializeParam(
          data['adjusted_calories'],
          ParamType.int,
          false,
        ),
        adjustedProtein: deserializeParam(
          data['adjusted_protein'],
          ParamType.int,
          false,
        ),
        adjustedCarbs: deserializeParam(
          data['adjusted_carbs'],
          ParamType.int,
          false,
        ),
        adjustedFat: deserializeParam(
          data['adjusted_fat'],
          ParamType.int,
          false,
        ),
        ingredients: deserializeParam<String>(
          data['ingredients'],
          ParamType.String,
          true,
        ),
        scaleFactor: deserializeParam(
          data['scale_factor'],
          ParamType.double,
          false,
        ),
        usingFallbackCalories: deserializeParam(
          data['using_fallback_calories'],
          ParamType.bool,
          false,
        ),
        targetCaloriesUsed: deserializeParam(
          data['target_calories_used'],
          ParamType.int,
          false,
        ),
        macrosFound: deserializeParam(
          data['macros_found'],
          ParamType.bool,
          false,
        ),
        debugInfo: deserializeStructParam(
          data['debug_info'],
          ParamType.DataStruct,
          false,
          structBuilder: DebugInfoStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'NewMealStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is NewMealStruct &&
        success == other.success &&
        mealId == other.mealId &&
        mealType == other.mealType &&
        mealDate == other.mealDate &&
        adjustedCalories == other.adjustedCalories &&
        adjustedProtein == other.adjustedProtein &&
        adjustedCarbs == other.adjustedCarbs &&
        adjustedFat == other.adjustedFat &&
        listEquality.equals(ingredients, other.ingredients) &&
        scaleFactor == other.scaleFactor &&
        usingFallbackCalories == other.usingFallbackCalories &&
        targetCaloriesUsed == other.targetCaloriesUsed &&
        macrosFound == other.macrosFound &&
        debugInfo == other.debugInfo;
  }

  @override
  int get hashCode => const ListEquality().hash([
        success,
        mealId,
        mealType,
        mealDate,
        adjustedCalories,
        adjustedProtein,
        adjustedCarbs,
        adjustedFat,
        ingredients,
        scaleFactor,
        usingFallbackCalories,
        targetCaloriesUsed,
        macrosFound,
        debugInfo
      ]);
}

NewMealStruct createNewMealStruct({
  bool? success,
  int? mealId,
  String? mealType,
  String? mealDate,
  int? adjustedCalories,
  int? adjustedProtein,
  int? adjustedCarbs,
  int? adjustedFat,
  double? scaleFactor,
  bool? usingFallbackCalories,
  int? targetCaloriesUsed,
  bool? macrosFound,
  DebugInfoStruct? debugInfo,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    NewMealStruct(
      success: success,
      mealId: mealId,
      mealType: mealType,
      mealDate: mealDate,
      adjustedCalories: adjustedCalories,
      adjustedProtein: adjustedProtein,
      adjustedCarbs: adjustedCarbs,
      adjustedFat: adjustedFat,
      scaleFactor: scaleFactor,
      usingFallbackCalories: usingFallbackCalories,
      targetCaloriesUsed: targetCaloriesUsed,
      macrosFound: macrosFound,
      debugInfo: debugInfo ?? (clearUnsetFields ? DebugInfoStruct() : null),
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

NewMealStruct? updateNewMealStruct(
  NewMealStruct? newMeal, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    newMeal
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addNewMealStructData(
  Map<String, dynamic> firestoreData,
  NewMealStruct? newMeal,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (newMeal == null) {
    return;
  }
  if (newMeal.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && newMeal.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final newMealData = getNewMealFirestoreData(newMeal, forFieldValue);
  final nestedData = newMealData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = newMeal.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getNewMealFirestoreData(
  NewMealStruct? newMeal, [
  bool forFieldValue = false,
]) {
  if (newMeal == null) {
    return {};
  }
  final firestoreData = mapToFirestore(newMeal.toMap());

  // Handle nested data for "debug_info" field.
  addDebugInfoStructData(
    firestoreData,
    newMeal.hasDebugInfo() ? newMeal.debugInfo : null,
    'debug_info',
    forFieldValue,
  );

  // Add any Firestore field values
  newMeal.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getNewMealListFirestoreData(
  List<NewMealStruct>? newMeals,
) =>
    newMeals?.map((e) => getNewMealFirestoreData(e, true)).toList() ?? [];
