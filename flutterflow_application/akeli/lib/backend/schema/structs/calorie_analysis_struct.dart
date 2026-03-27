// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CalorieAnalysisStruct extends FFFirebaseStruct {
  CalorieAnalysisStruct({
    int? targetCalories,
    int? baseCalories,
    int? plannedScalingFactor,
    int? actualScalingFactor,
    int? estimatedActualCalories,
    int? calorieDiscrepancy,
    int? discrepancyPercentage,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _targetCalories = targetCalories,
        _baseCalories = baseCalories,
        _plannedScalingFactor = plannedScalingFactor,
        _actualScalingFactor = actualScalingFactor,
        _estimatedActualCalories = estimatedActualCalories,
        _calorieDiscrepancy = calorieDiscrepancy,
        _discrepancyPercentage = discrepancyPercentage,
        super(firestoreUtilData);

  // "target_calories" field.
  int? _targetCalories;
  int get targetCalories => _targetCalories ?? 0;
  set targetCalories(int? val) => _targetCalories = val;

  void incrementTargetCalories(int amount) =>
      targetCalories = targetCalories + amount;

  bool hasTargetCalories() => _targetCalories != null;

  // "base_calories" field.
  int? _baseCalories;
  int get baseCalories => _baseCalories ?? 0;
  set baseCalories(int? val) => _baseCalories = val;

  void incrementBaseCalories(int amount) =>
      baseCalories = baseCalories + amount;

  bool hasBaseCalories() => _baseCalories != null;

  // "planned_scaling_factor" field.
  int? _plannedScalingFactor;
  int get plannedScalingFactor => _plannedScalingFactor ?? 0;
  set plannedScalingFactor(int? val) => _plannedScalingFactor = val;

  void incrementPlannedScalingFactor(int amount) =>
      plannedScalingFactor = plannedScalingFactor + amount;

  bool hasPlannedScalingFactor() => _plannedScalingFactor != null;

  // "actual_scaling_factor" field.
  int? _actualScalingFactor;
  int get actualScalingFactor => _actualScalingFactor ?? 0;
  set actualScalingFactor(int? val) => _actualScalingFactor = val;

  void incrementActualScalingFactor(int amount) =>
      actualScalingFactor = actualScalingFactor + amount;

  bool hasActualScalingFactor() => _actualScalingFactor != null;

  // "estimated_actual_calories" field.
  int? _estimatedActualCalories;
  int get estimatedActualCalories => _estimatedActualCalories ?? 0;
  set estimatedActualCalories(int? val) => _estimatedActualCalories = val;

  void incrementEstimatedActualCalories(int amount) =>
      estimatedActualCalories = estimatedActualCalories + amount;

  bool hasEstimatedActualCalories() => _estimatedActualCalories != null;

  // "calorie_discrepancy" field.
  int? _calorieDiscrepancy;
  int get calorieDiscrepancy => _calorieDiscrepancy ?? 0;
  set calorieDiscrepancy(int? val) => _calorieDiscrepancy = val;

  void incrementCalorieDiscrepancy(int amount) =>
      calorieDiscrepancy = calorieDiscrepancy + amount;

  bool hasCalorieDiscrepancy() => _calorieDiscrepancy != null;

  // "discrepancy_percentage" field.
  int? _discrepancyPercentage;
  int get discrepancyPercentage => _discrepancyPercentage ?? 0;
  set discrepancyPercentage(int? val) => _discrepancyPercentage = val;

  void incrementDiscrepancyPercentage(int amount) =>
      discrepancyPercentage = discrepancyPercentage + amount;

  bool hasDiscrepancyPercentage() => _discrepancyPercentage != null;

  static CalorieAnalysisStruct fromMap(Map<String, dynamic> data) =>
      CalorieAnalysisStruct(
        targetCalories: castToType<int>(data['target_calories']),
        baseCalories: castToType<int>(data['base_calories']),
        plannedScalingFactor: castToType<int>(data['planned_scaling_factor']),
        actualScalingFactor: castToType<int>(data['actual_scaling_factor']),
        estimatedActualCalories:
            castToType<int>(data['estimated_actual_calories']),
        calorieDiscrepancy: castToType<int>(data['calorie_discrepancy']),
        discrepancyPercentage: castToType<int>(data['discrepancy_percentage']),
      );

  static CalorieAnalysisStruct? maybeFromMap(dynamic data) => data is Map
      ? CalorieAnalysisStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'target_calories': _targetCalories,
        'base_calories': _baseCalories,
        'planned_scaling_factor': _plannedScalingFactor,
        'actual_scaling_factor': _actualScalingFactor,
        'estimated_actual_calories': _estimatedActualCalories,
        'calorie_discrepancy': _calorieDiscrepancy,
        'discrepancy_percentage': _discrepancyPercentage,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'target_calories': serializeParam(
          _targetCalories,
          ParamType.int,
        ),
        'base_calories': serializeParam(
          _baseCalories,
          ParamType.int,
        ),
        'planned_scaling_factor': serializeParam(
          _plannedScalingFactor,
          ParamType.int,
        ),
        'actual_scaling_factor': serializeParam(
          _actualScalingFactor,
          ParamType.int,
        ),
        'estimated_actual_calories': serializeParam(
          _estimatedActualCalories,
          ParamType.int,
        ),
        'calorie_discrepancy': serializeParam(
          _calorieDiscrepancy,
          ParamType.int,
        ),
        'discrepancy_percentage': serializeParam(
          _discrepancyPercentage,
          ParamType.int,
        ),
      }.withoutNulls;

  static CalorieAnalysisStruct fromSerializableMap(Map<String, dynamic> data) =>
      CalorieAnalysisStruct(
        targetCalories: deserializeParam(
          data['target_calories'],
          ParamType.int,
          false,
        ),
        baseCalories: deserializeParam(
          data['base_calories'],
          ParamType.int,
          false,
        ),
        plannedScalingFactor: deserializeParam(
          data['planned_scaling_factor'],
          ParamType.int,
          false,
        ),
        actualScalingFactor: deserializeParam(
          data['actual_scaling_factor'],
          ParamType.int,
          false,
        ),
        estimatedActualCalories: deserializeParam(
          data['estimated_actual_calories'],
          ParamType.int,
          false,
        ),
        calorieDiscrepancy: deserializeParam(
          data['calorie_discrepancy'],
          ParamType.int,
          false,
        ),
        discrepancyPercentage: deserializeParam(
          data['discrepancy_percentage'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'CalorieAnalysisStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is CalorieAnalysisStruct &&
        targetCalories == other.targetCalories &&
        baseCalories == other.baseCalories &&
        plannedScalingFactor == other.plannedScalingFactor &&
        actualScalingFactor == other.actualScalingFactor &&
        estimatedActualCalories == other.estimatedActualCalories &&
        calorieDiscrepancy == other.calorieDiscrepancy &&
        discrepancyPercentage == other.discrepancyPercentage;
  }

  @override
  int get hashCode => const ListEquality().hash([
        targetCalories,
        baseCalories,
        plannedScalingFactor,
        actualScalingFactor,
        estimatedActualCalories,
        calorieDiscrepancy,
        discrepancyPercentage
      ]);
}

CalorieAnalysisStruct createCalorieAnalysisStruct({
  int? targetCalories,
  int? baseCalories,
  int? plannedScalingFactor,
  int? actualScalingFactor,
  int? estimatedActualCalories,
  int? calorieDiscrepancy,
  int? discrepancyPercentage,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    CalorieAnalysisStruct(
      targetCalories: targetCalories,
      baseCalories: baseCalories,
      plannedScalingFactor: plannedScalingFactor,
      actualScalingFactor: actualScalingFactor,
      estimatedActualCalories: estimatedActualCalories,
      calorieDiscrepancy: calorieDiscrepancy,
      discrepancyPercentage: discrepancyPercentage,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

CalorieAnalysisStruct? updateCalorieAnalysisStruct(
  CalorieAnalysisStruct? calorieAnalysis, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    calorieAnalysis
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addCalorieAnalysisStructData(
  Map<String, dynamic> firestoreData,
  CalorieAnalysisStruct? calorieAnalysis,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (calorieAnalysis == null) {
    return;
  }
  if (calorieAnalysis.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && calorieAnalysis.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final calorieAnalysisData =
      getCalorieAnalysisFirestoreData(calorieAnalysis, forFieldValue);
  final nestedData =
      calorieAnalysisData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = calorieAnalysis.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getCalorieAnalysisFirestoreData(
  CalorieAnalysisStruct? calorieAnalysis, [
  bool forFieldValue = false,
]) {
  if (calorieAnalysis == null) {
    return {};
  }
  final firestoreData = mapToFirestore(calorieAnalysis.toMap());

  // Add any Firestore field values
  calorieAnalysis.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getCalorieAnalysisListFirestoreData(
  List<CalorieAnalysisStruct>? calorieAnalysiss,
) =>
    calorieAnalysiss
        ?.map((e) => getCalorieAnalysisFirestoreData(e, true))
        .toList() ??
    [];
