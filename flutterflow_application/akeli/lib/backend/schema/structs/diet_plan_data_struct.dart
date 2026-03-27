// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DietPlanDataStruct extends FFFirebaseStruct {
  DietPlanDataStruct({
    bool? success,
    int? dailyCalories,
    int? breakfast,
    int? lunch,
    int? dinner,
    int? snack,
    int? proteinGrams,
    int? carbGrams,
    int? fatGrams,
    int? waterMl,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _success = success,
        _dailyCalories = dailyCalories,
        _breakfast = breakfast,
        _lunch = lunch,
        _dinner = dinner,
        _snack = snack,
        _proteinGrams = proteinGrams,
        _carbGrams = carbGrams,
        _fatGrams = fatGrams,
        _waterMl = waterMl,
        super(firestoreUtilData);

  // "success" field.
  bool? _success;
  bool get success => _success ?? false;
  set success(bool? val) => _success = val;

  bool hasSuccess() => _success != null;

  // "daily_calories" field.
  int? _dailyCalories;
  int get dailyCalories => _dailyCalories ?? 0;
  set dailyCalories(int? val) => _dailyCalories = val;

  void incrementDailyCalories(int amount) =>
      dailyCalories = dailyCalories + amount;

  bool hasDailyCalories() => _dailyCalories != null;

  // "breakfast" field.
  int? _breakfast;
  int get breakfast => _breakfast ?? 0;
  set breakfast(int? val) => _breakfast = val;

  void incrementBreakfast(int amount) => breakfast = breakfast + amount;

  bool hasBreakfast() => _breakfast != null;

  // "lunch" field.
  int? _lunch;
  int get lunch => _lunch ?? 0;
  set lunch(int? val) => _lunch = val;

  void incrementLunch(int amount) => lunch = lunch + amount;

  bool hasLunch() => _lunch != null;

  // "dinner" field.
  int? _dinner;
  int get dinner => _dinner ?? 0;
  set dinner(int? val) => _dinner = val;

  void incrementDinner(int amount) => dinner = dinner + amount;

  bool hasDinner() => _dinner != null;

  // "snack" field.
  int? _snack;
  int get snack => _snack ?? 0;
  set snack(int? val) => _snack = val;

  void incrementSnack(int amount) => snack = snack + amount;

  bool hasSnack() => _snack != null;

  // "protein_grams" field.
  int? _proteinGrams;
  int get proteinGrams => _proteinGrams ?? 0;
  set proteinGrams(int? val) => _proteinGrams = val;

  void incrementProteinGrams(int amount) =>
      proteinGrams = proteinGrams + amount;

  bool hasProteinGrams() => _proteinGrams != null;

  // "carb_grams" field.
  int? _carbGrams;
  int get carbGrams => _carbGrams ?? 0;
  set carbGrams(int? val) => _carbGrams = val;

  void incrementCarbGrams(int amount) => carbGrams = carbGrams + amount;

  bool hasCarbGrams() => _carbGrams != null;

  // "fat_grams" field.
  int? _fatGrams;
  int get fatGrams => _fatGrams ?? 0;
  set fatGrams(int? val) => _fatGrams = val;

  void incrementFatGrams(int amount) => fatGrams = fatGrams + amount;

  bool hasFatGrams() => _fatGrams != null;

  // "water_ml" field.
  int? _waterMl;
  int get waterMl => _waterMl ?? 0;
  set waterMl(int? val) => _waterMl = val;

  void incrementWaterMl(int amount) => waterMl = waterMl + amount;

  bool hasWaterMl() => _waterMl != null;

  static DietPlanDataStruct fromMap(Map<String, dynamic> data) =>
      DietPlanDataStruct(
        success: data['success'] as bool?,
        dailyCalories: castToType<int>(data['daily_calories']),
        breakfast: castToType<int>(data['breakfast']),
        lunch: castToType<int>(data['lunch']),
        dinner: castToType<int>(data['dinner']),
        snack: castToType<int>(data['snack']),
        proteinGrams: castToType<int>(data['protein_grams']),
        carbGrams: castToType<int>(data['carb_grams']),
        fatGrams: castToType<int>(data['fat_grams']),
        waterMl: castToType<int>(data['water_ml']),
      );

  static DietPlanDataStruct? maybeFromMap(dynamic data) => data is Map
      ? DietPlanDataStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'success': _success,
        'daily_calories': _dailyCalories,
        'breakfast': _breakfast,
        'lunch': _lunch,
        'dinner': _dinner,
        'snack': _snack,
        'protein_grams': _proteinGrams,
        'carb_grams': _carbGrams,
        'fat_grams': _fatGrams,
        'water_ml': _waterMl,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'success': serializeParam(
          _success,
          ParamType.bool,
        ),
        'daily_calories': serializeParam(
          _dailyCalories,
          ParamType.int,
        ),
        'breakfast': serializeParam(
          _breakfast,
          ParamType.int,
        ),
        'lunch': serializeParam(
          _lunch,
          ParamType.int,
        ),
        'dinner': serializeParam(
          _dinner,
          ParamType.int,
        ),
        'snack': serializeParam(
          _snack,
          ParamType.int,
        ),
        'protein_grams': serializeParam(
          _proteinGrams,
          ParamType.int,
        ),
        'carb_grams': serializeParam(
          _carbGrams,
          ParamType.int,
        ),
        'fat_grams': serializeParam(
          _fatGrams,
          ParamType.int,
        ),
        'water_ml': serializeParam(
          _waterMl,
          ParamType.int,
        ),
      }.withoutNulls;

  static DietPlanDataStruct fromSerializableMap(Map<String, dynamic> data) =>
      DietPlanDataStruct(
        success: deserializeParam(
          data['success'],
          ParamType.bool,
          false,
        ),
        dailyCalories: deserializeParam(
          data['daily_calories'],
          ParamType.int,
          false,
        ),
        breakfast: deserializeParam(
          data['breakfast'],
          ParamType.int,
          false,
        ),
        lunch: deserializeParam(
          data['lunch'],
          ParamType.int,
          false,
        ),
        dinner: deserializeParam(
          data['dinner'],
          ParamType.int,
          false,
        ),
        snack: deserializeParam(
          data['snack'],
          ParamType.int,
          false,
        ),
        proteinGrams: deserializeParam(
          data['protein_grams'],
          ParamType.int,
          false,
        ),
        carbGrams: deserializeParam(
          data['carb_grams'],
          ParamType.int,
          false,
        ),
        fatGrams: deserializeParam(
          data['fat_grams'],
          ParamType.int,
          false,
        ),
        waterMl: deserializeParam(
          data['water_ml'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'DietPlanDataStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is DietPlanDataStruct &&
        success == other.success &&
        dailyCalories == other.dailyCalories &&
        breakfast == other.breakfast &&
        lunch == other.lunch &&
        dinner == other.dinner &&
        snack == other.snack &&
        proteinGrams == other.proteinGrams &&
        carbGrams == other.carbGrams &&
        fatGrams == other.fatGrams &&
        waterMl == other.waterMl;
  }

  @override
  int get hashCode => const ListEquality().hash([
        success,
        dailyCalories,
        breakfast,
        lunch,
        dinner,
        snack,
        proteinGrams,
        carbGrams,
        fatGrams,
        waterMl
      ]);
}

DietPlanDataStruct createDietPlanDataStruct({
  bool? success,
  int? dailyCalories,
  int? breakfast,
  int? lunch,
  int? dinner,
  int? snack,
  int? proteinGrams,
  int? carbGrams,
  int? fatGrams,
  int? waterMl,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    DietPlanDataStruct(
      success: success,
      dailyCalories: dailyCalories,
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      snack: snack,
      proteinGrams: proteinGrams,
      carbGrams: carbGrams,
      fatGrams: fatGrams,
      waterMl: waterMl,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

DietPlanDataStruct? updateDietPlanDataStruct(
  DietPlanDataStruct? dietPlanData, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    dietPlanData
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addDietPlanDataStructData(
  Map<String, dynamic> firestoreData,
  DietPlanDataStruct? dietPlanData,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (dietPlanData == null) {
    return;
  }
  if (dietPlanData.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && dietPlanData.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final dietPlanDataData =
      getDietPlanDataFirestoreData(dietPlanData, forFieldValue);
  final nestedData =
      dietPlanDataData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = dietPlanData.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getDietPlanDataFirestoreData(
  DietPlanDataStruct? dietPlanData, [
  bool forFieldValue = false,
]) {
  if (dietPlanData == null) {
    return {};
  }
  final firestoreData = mapToFirestore(dietPlanData.toMap());

  // Add any Firestore field values
  dietPlanData.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getDietPlanDataListFirestoreData(
  List<DietPlanDataStruct>? dietPlanDatas,
) =>
    dietPlanDatas?.map((e) => getDietPlanDataFirestoreData(e, true)).toList() ??
    [];
