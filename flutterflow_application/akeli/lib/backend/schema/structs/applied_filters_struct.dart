// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AppliedFiltersStruct extends FFFirebaseStruct {
  AppliedFiltersStruct({
    int? calorieGte,
    int? calorieLte,
    List<String>? type,
    String? typeLogic,
    List<String>? tags,
    String? tagLogic,
    String? foodRegion,
    List<String>? difficultyLevels,
    String? difficultyLogic,
    int? totalCookingTimeMinutesLte,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _calorieGte = calorieGte,
        _calorieLte = calorieLte,
        _type = type,
        _typeLogic = typeLogic,
        _tags = tags,
        _tagLogic = tagLogic,
        _foodRegion = foodRegion,
        _difficultyLevels = difficultyLevels,
        _difficultyLogic = difficultyLogic,
        _totalCookingTimeMinutesLte = totalCookingTimeMinutesLte,
        super(firestoreUtilData);

  // "calorie_gte" field.
  int? _calorieGte;
  int get calorieGte => _calorieGte ?? 0;
  set calorieGte(int? val) => _calorieGte = val;

  void incrementCalorieGte(int amount) => calorieGte = calorieGte + amount;

  bool hasCalorieGte() => _calorieGte != null;

  // "calorie_lte" field.
  int? _calorieLte;
  int get calorieLte => _calorieLte ?? 0;
  set calorieLte(int? val) => _calorieLte = val;

  void incrementCalorieLte(int amount) => calorieLte = calorieLte + amount;

  bool hasCalorieLte() => _calorieLte != null;

  // "type" field.
  List<String>? _type;
  List<String> get type => _type ?? const [];
  set type(List<String>? val) => _type = val;

  void updateType(Function(List<String>) updateFn) {
    updateFn(_type ??= []);
  }

  bool hasType() => _type != null;

  // "type_logic" field.
  String? _typeLogic;
  String get typeLogic => _typeLogic ?? '';
  set typeLogic(String? val) => _typeLogic = val;

  bool hasTypeLogic() => _typeLogic != null;

  // "tags" field.
  List<String>? _tags;
  List<String> get tags => _tags ?? const [];
  set tags(List<String>? val) => _tags = val;

  void updateTags(Function(List<String>) updateFn) {
    updateFn(_tags ??= []);
  }

  bool hasTags() => _tags != null;

  // "tag_logic" field.
  String? _tagLogic;
  String get tagLogic => _tagLogic ?? '';
  set tagLogic(String? val) => _tagLogic = val;

  bool hasTagLogic() => _tagLogic != null;

  // "food_region" field.
  String? _foodRegion;
  String get foodRegion => _foodRegion ?? '';
  set foodRegion(String? val) => _foodRegion = val;

  bool hasFoodRegion() => _foodRegion != null;

  // "difficulty_levels" field.
  List<String>? _difficultyLevels;
  List<String> get difficultyLevels => _difficultyLevels ?? const [];
  set difficultyLevels(List<String>? val) => _difficultyLevels = val;

  void updateDifficultyLevels(Function(List<String>) updateFn) {
    updateFn(_difficultyLevels ??= []);
  }

  bool hasDifficultyLevels() => _difficultyLevels != null;

  // "difficulty_logic" field.
  String? _difficultyLogic;
  String get difficultyLogic => _difficultyLogic ?? '';
  set difficultyLogic(String? val) => _difficultyLogic = val;

  bool hasDifficultyLogic() => _difficultyLogic != null;

  // "total_cooking_time_minutes_lte" field.
  int? _totalCookingTimeMinutesLte;
  int get totalCookingTimeMinutesLte => _totalCookingTimeMinutesLte ?? 0;
  set totalCookingTimeMinutesLte(int? val) => _totalCookingTimeMinutesLte = val;

  void incrementTotalCookingTimeMinutesLte(int amount) =>
      totalCookingTimeMinutesLte = totalCookingTimeMinutesLte + amount;

  bool hasTotalCookingTimeMinutesLte() => _totalCookingTimeMinutesLte != null;

  static AppliedFiltersStruct fromMap(Map<String, dynamic> data) =>
      AppliedFiltersStruct(
        calorieGte: castToType<int>(data['calorie_gte']),
        calorieLte: castToType<int>(data['calorie_lte']),
        type: getDataList(data['type']),
        typeLogic: data['type_logic'] as String?,
        tags: getDataList(data['tags']),
        tagLogic: data['tag_logic'] as String?,
        foodRegion: data['food_region'] as String?,
        difficultyLevels: getDataList(data['difficulty_levels']),
        difficultyLogic: data['difficulty_logic'] as String?,
        totalCookingTimeMinutesLte:
            castToType<int>(data['total_cooking_time_minutes_lte']),
      );

  static AppliedFiltersStruct? maybeFromMap(dynamic data) => data is Map
      ? AppliedFiltersStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'calorie_gte': _calorieGte,
        'calorie_lte': _calorieLte,
        'type': _type,
        'type_logic': _typeLogic,
        'tags': _tags,
        'tag_logic': _tagLogic,
        'food_region': _foodRegion,
        'difficulty_levels': _difficultyLevels,
        'difficulty_logic': _difficultyLogic,
        'total_cooking_time_minutes_lte': _totalCookingTimeMinutesLte,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'calorie_gte': serializeParam(
          _calorieGte,
          ParamType.int,
        ),
        'calorie_lte': serializeParam(
          _calorieLte,
          ParamType.int,
        ),
        'type': serializeParam(
          _type,
          ParamType.String,
          isList: true,
        ),
        'type_logic': serializeParam(
          _typeLogic,
          ParamType.String,
        ),
        'tags': serializeParam(
          _tags,
          ParamType.String,
          isList: true,
        ),
        'tag_logic': serializeParam(
          _tagLogic,
          ParamType.String,
        ),
        'food_region': serializeParam(
          _foodRegion,
          ParamType.String,
        ),
        'difficulty_levels': serializeParam(
          _difficultyLevels,
          ParamType.String,
          isList: true,
        ),
        'difficulty_logic': serializeParam(
          _difficultyLogic,
          ParamType.String,
        ),
        'total_cooking_time_minutes_lte': serializeParam(
          _totalCookingTimeMinutesLte,
          ParamType.int,
        ),
      }.withoutNulls;

  static AppliedFiltersStruct fromSerializableMap(Map<String, dynamic> data) =>
      AppliedFiltersStruct(
        calorieGte: deserializeParam(
          data['calorie_gte'],
          ParamType.int,
          false,
        ),
        calorieLte: deserializeParam(
          data['calorie_lte'],
          ParamType.int,
          false,
        ),
        type: deserializeParam<String>(
          data['type'],
          ParamType.String,
          true,
        ),
        typeLogic: deserializeParam(
          data['type_logic'],
          ParamType.String,
          false,
        ),
        tags: deserializeParam<String>(
          data['tags'],
          ParamType.String,
          true,
        ),
        tagLogic: deserializeParam(
          data['tag_logic'],
          ParamType.String,
          false,
        ),
        foodRegion: deserializeParam(
          data['food_region'],
          ParamType.String,
          false,
        ),
        difficultyLevels: deserializeParam<String>(
          data['difficulty_levels'],
          ParamType.String,
          true,
        ),
        difficultyLogic: deserializeParam(
          data['difficulty_logic'],
          ParamType.String,
          false,
        ),
        totalCookingTimeMinutesLte: deserializeParam(
          data['total_cooking_time_minutes_lte'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'AppliedFiltersStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is AppliedFiltersStruct &&
        calorieGte == other.calorieGte &&
        calorieLte == other.calorieLte &&
        listEquality.equals(type, other.type) &&
        typeLogic == other.typeLogic &&
        listEquality.equals(tags, other.tags) &&
        tagLogic == other.tagLogic &&
        foodRegion == other.foodRegion &&
        listEquality.equals(difficultyLevels, other.difficultyLevels) &&
        difficultyLogic == other.difficultyLogic &&
        totalCookingTimeMinutesLte == other.totalCookingTimeMinutesLte;
  }

  @override
  int get hashCode => const ListEquality().hash([
        calorieGte,
        calorieLte,
        type,
        typeLogic,
        tags,
        tagLogic,
        foodRegion,
        difficultyLevels,
        difficultyLogic,
        totalCookingTimeMinutesLte
      ]);
}

AppliedFiltersStruct createAppliedFiltersStruct({
  int? calorieGte,
  int? calorieLte,
  String? typeLogic,
  String? tagLogic,
  String? foodRegion,
  String? difficultyLogic,
  int? totalCookingTimeMinutesLte,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    AppliedFiltersStruct(
      calorieGte: calorieGte,
      calorieLte: calorieLte,
      typeLogic: typeLogic,
      tagLogic: tagLogic,
      foodRegion: foodRegion,
      difficultyLogic: difficultyLogic,
      totalCookingTimeMinutesLte: totalCookingTimeMinutesLte,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

AppliedFiltersStruct? updateAppliedFiltersStruct(
  AppliedFiltersStruct? appliedFilters, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    appliedFilters
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addAppliedFiltersStructData(
  Map<String, dynamic> firestoreData,
  AppliedFiltersStruct? appliedFilters,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (appliedFilters == null) {
    return;
  }
  if (appliedFilters.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && appliedFilters.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final appliedFiltersData =
      getAppliedFiltersFirestoreData(appliedFilters, forFieldValue);
  final nestedData =
      appliedFiltersData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = appliedFilters.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getAppliedFiltersFirestoreData(
  AppliedFiltersStruct? appliedFilters, [
  bool forFieldValue = false,
]) {
  if (appliedFilters == null) {
    return {};
  }
  final firestoreData = mapToFirestore(appliedFilters.toMap());

  // Add any Firestore field values
  appliedFilters.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getAppliedFiltersListFirestoreData(
  List<AppliedFiltersStruct>? appliedFilterss,
) =>
    appliedFilterss
        ?.map((e) => getAppliedFiltersFirestoreData(e, true))
        .toList() ??
    [];
