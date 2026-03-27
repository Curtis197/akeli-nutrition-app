// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ReceipeDataStruct extends FFFirebaseStruct {
  ReceipeDataStruct({
    List<RecipesStruct>? recipes,
    int? count,
    AppliedFiltersStruct? appliedFilters,
    bool? hasActiveFilters,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _recipes = recipes,
        _count = count,
        _appliedFilters = appliedFilters,
        _hasActiveFilters = hasActiveFilters,
        super(firestoreUtilData);

  // "recipes" field.
  List<RecipesStruct>? _recipes;
  List<RecipesStruct> get recipes => _recipes ?? const [];
  set recipes(List<RecipesStruct>? val) => _recipes = val;

  void updateRecipes(Function(List<RecipesStruct>) updateFn) {
    updateFn(_recipes ??= []);
  }

  bool hasRecipes() => _recipes != null;

  // "count" field.
  int? _count;
  int get count => _count ?? 0;
  set count(int? val) => _count = val;

  void incrementCount(int amount) => count = count + amount;

  bool hasCount() => _count != null;

  // "applied_filters" field.
  AppliedFiltersStruct? _appliedFilters;
  AppliedFiltersStruct get appliedFilters =>
      _appliedFilters ?? AppliedFiltersStruct();
  set appliedFilters(AppliedFiltersStruct? val) => _appliedFilters = val;

  void updateAppliedFilters(Function(AppliedFiltersStruct) updateFn) {
    updateFn(_appliedFilters ??= AppliedFiltersStruct());
  }

  bool hasAppliedFilters() => _appliedFilters != null;

  // "has_active_filters" field.
  bool? _hasActiveFilters;
  bool get hasActiveFilters => _hasActiveFilters ?? false;
  set hasActiveFilters(bool? val) => _hasActiveFilters = val;

  bool hasHasActiveFilters() => _hasActiveFilters != null;

  static ReceipeDataStruct fromMap(Map<String, dynamic> data) =>
      ReceipeDataStruct(
        recipes: getStructList(
          data['recipes'],
          RecipesStruct.fromMap,
        ),
        count: castToType<int>(data['count']),
        appliedFilters: data['applied_filters'] is AppliedFiltersStruct
            ? data['applied_filters']
            : AppliedFiltersStruct.maybeFromMap(data['applied_filters']),
        hasActiveFilters: data['has_active_filters'] as bool?,
      );

  static ReceipeDataStruct? maybeFromMap(dynamic data) => data is Map
      ? ReceipeDataStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'recipes': _recipes?.map((e) => e.toMap()).toList(),
        'count': _count,
        'applied_filters': _appliedFilters?.toMap(),
        'has_active_filters': _hasActiveFilters,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'recipes': serializeParam(
          _recipes,
          ParamType.DataStruct,
          isList: true,
        ),
        'count': serializeParam(
          _count,
          ParamType.int,
        ),
        'applied_filters': serializeParam(
          _appliedFilters,
          ParamType.DataStruct,
        ),
        'has_active_filters': serializeParam(
          _hasActiveFilters,
          ParamType.bool,
        ),
      }.withoutNulls;

  static ReceipeDataStruct fromSerializableMap(Map<String, dynamic> data) =>
      ReceipeDataStruct(
        recipes: deserializeStructParam<RecipesStruct>(
          data['recipes'],
          ParamType.DataStruct,
          true,
          structBuilder: RecipesStruct.fromSerializableMap,
        ),
        count: deserializeParam(
          data['count'],
          ParamType.int,
          false,
        ),
        appliedFilters: deserializeStructParam(
          data['applied_filters'],
          ParamType.DataStruct,
          false,
          structBuilder: AppliedFiltersStruct.fromSerializableMap,
        ),
        hasActiveFilters: deserializeParam(
          data['has_active_filters'],
          ParamType.bool,
          false,
        ),
      );

  @override
  String toString() => 'ReceipeDataStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is ReceipeDataStruct &&
        listEquality.equals(recipes, other.recipes) &&
        count == other.count &&
        appliedFilters == other.appliedFilters &&
        hasActiveFilters == other.hasActiveFilters;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([recipes, count, appliedFilters, hasActiveFilters]);
}

ReceipeDataStruct createReceipeDataStruct({
  int? count,
  AppliedFiltersStruct? appliedFilters,
  bool? hasActiveFilters,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    ReceipeDataStruct(
      count: count,
      appliedFilters:
          appliedFilters ?? (clearUnsetFields ? AppliedFiltersStruct() : null),
      hasActiveFilters: hasActiveFilters,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

ReceipeDataStruct? updateReceipeDataStruct(
  ReceipeDataStruct? receipeData, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    receipeData
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addReceipeDataStructData(
  Map<String, dynamic> firestoreData,
  ReceipeDataStruct? receipeData,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (receipeData == null) {
    return;
  }
  if (receipeData.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && receipeData.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final receipeDataData =
      getReceipeDataFirestoreData(receipeData, forFieldValue);
  final nestedData =
      receipeDataData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = receipeData.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getReceipeDataFirestoreData(
  ReceipeDataStruct? receipeData, [
  bool forFieldValue = false,
]) {
  if (receipeData == null) {
    return {};
  }
  final firestoreData = mapToFirestore(receipeData.toMap());

  // Handle nested data for "applied_filters" field.
  addAppliedFiltersStructData(
    firestoreData,
    receipeData.hasAppliedFilters() ? receipeData.appliedFilters : null,
    'applied_filters',
    forFieldValue,
  );

  // Add any Firestore field values
  receipeData.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getReceipeDataListFirestoreData(
  List<ReceipeDataStruct>? receipeDatas,
) =>
    receipeDatas?.map((e) => getReceipeDataFirestoreData(e, true)).toList() ??
    [];
