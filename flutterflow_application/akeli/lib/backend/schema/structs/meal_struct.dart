// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MealStruct extends FFFirebaseStruct {
  MealStruct({
    TestInfoStruct? testInfo,
    CalorieAnalysisStruct? calorieAnalysis,
    List<IngredientsStruct>? ingredients,
    DatabaseResultsStruct? databaseResults,
    SummaryStruct? summary,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _testInfo = testInfo,
        _calorieAnalysis = calorieAnalysis,
        _ingredients = ingredients,
        _databaseResults = databaseResults,
        _summary = summary,
        super(firestoreUtilData);

  // "test_info" field.
  TestInfoStruct? _testInfo;
  TestInfoStruct get testInfo => _testInfo ?? TestInfoStruct();
  set testInfo(TestInfoStruct? val) => _testInfo = val;

  void updateTestInfo(Function(TestInfoStruct) updateFn) {
    updateFn(_testInfo ??= TestInfoStruct());
  }

  bool hasTestInfo() => _testInfo != null;

  // "calorie_analysis" field.
  CalorieAnalysisStruct? _calorieAnalysis;
  CalorieAnalysisStruct get calorieAnalysis =>
      _calorieAnalysis ?? CalorieAnalysisStruct();
  set calorieAnalysis(CalorieAnalysisStruct? val) => _calorieAnalysis = val;

  void updateCalorieAnalysis(Function(CalorieAnalysisStruct) updateFn) {
    updateFn(_calorieAnalysis ??= CalorieAnalysisStruct());
  }

  bool hasCalorieAnalysis() => _calorieAnalysis != null;

  // "ingredients" field.
  List<IngredientsStruct>? _ingredients;
  List<IngredientsStruct> get ingredients => _ingredients ?? const [];
  set ingredients(List<IngredientsStruct>? val) => _ingredients = val;

  void updateIngredients(Function(List<IngredientsStruct>) updateFn) {
    updateFn(_ingredients ??= []);
  }

  bool hasIngredients() => _ingredients != null;

  // "database_results" field.
  DatabaseResultsStruct? _databaseResults;
  DatabaseResultsStruct get databaseResults =>
      _databaseResults ?? DatabaseResultsStruct();
  set databaseResults(DatabaseResultsStruct? val) => _databaseResults = val;

  void updateDatabaseResults(Function(DatabaseResultsStruct) updateFn) {
    updateFn(_databaseResults ??= DatabaseResultsStruct());
  }

  bool hasDatabaseResults() => _databaseResults != null;

  // "summary" field.
  SummaryStruct? _summary;
  SummaryStruct get summary => _summary ?? SummaryStruct();
  set summary(SummaryStruct? val) => _summary = val;

  void updateSummary(Function(SummaryStruct) updateFn) {
    updateFn(_summary ??= SummaryStruct());
  }

  bool hasSummary() => _summary != null;

  static MealStruct fromMap(Map<String, dynamic> data) => MealStruct(
        testInfo: data['test_info'] is TestInfoStruct
            ? data['test_info']
            : TestInfoStruct.maybeFromMap(data['test_info']),
        calorieAnalysis: data['calorie_analysis'] is CalorieAnalysisStruct
            ? data['calorie_analysis']
            : CalorieAnalysisStruct.maybeFromMap(data['calorie_analysis']),
        ingredients: getStructList(
          data['ingredients'],
          IngredientsStruct.fromMap,
        ),
        databaseResults: data['database_results'] is DatabaseResultsStruct
            ? data['database_results']
            : DatabaseResultsStruct.maybeFromMap(data['database_results']),
        summary: data['summary'] is SummaryStruct
            ? data['summary']
            : SummaryStruct.maybeFromMap(data['summary']),
      );

  static MealStruct? maybeFromMap(dynamic data) =>
      data is Map ? MealStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'test_info': _testInfo?.toMap(),
        'calorie_analysis': _calorieAnalysis?.toMap(),
        'ingredients': _ingredients?.map((e) => e.toMap()).toList(),
        'database_results': _databaseResults?.toMap(),
        'summary': _summary?.toMap(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'test_info': serializeParam(
          _testInfo,
          ParamType.DataStruct,
        ),
        'calorie_analysis': serializeParam(
          _calorieAnalysis,
          ParamType.DataStruct,
        ),
        'ingredients': serializeParam(
          _ingredients,
          ParamType.DataStruct,
          isList: true,
        ),
        'database_results': serializeParam(
          _databaseResults,
          ParamType.DataStruct,
        ),
        'summary': serializeParam(
          _summary,
          ParamType.DataStruct,
        ),
      }.withoutNulls;

  static MealStruct fromSerializableMap(Map<String, dynamic> data) =>
      MealStruct(
        testInfo: deserializeStructParam(
          data['test_info'],
          ParamType.DataStruct,
          false,
          structBuilder: TestInfoStruct.fromSerializableMap,
        ),
        calorieAnalysis: deserializeStructParam(
          data['calorie_analysis'],
          ParamType.DataStruct,
          false,
          structBuilder: CalorieAnalysisStruct.fromSerializableMap,
        ),
        ingredients: deserializeStructParam<IngredientsStruct>(
          data['ingredients'],
          ParamType.DataStruct,
          true,
          structBuilder: IngredientsStruct.fromSerializableMap,
        ),
        databaseResults: deserializeStructParam(
          data['database_results'],
          ParamType.DataStruct,
          false,
          structBuilder: DatabaseResultsStruct.fromSerializableMap,
        ),
        summary: deserializeStructParam(
          data['summary'],
          ParamType.DataStruct,
          false,
          structBuilder: SummaryStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'MealStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is MealStruct &&
        testInfo == other.testInfo &&
        calorieAnalysis == other.calorieAnalysis &&
        listEquality.equals(ingredients, other.ingredients) &&
        databaseResults == other.databaseResults &&
        summary == other.summary;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([testInfo, calorieAnalysis, ingredients, databaseResults, summary]);
}

MealStruct createMealStruct({
  TestInfoStruct? testInfo,
  CalorieAnalysisStruct? calorieAnalysis,
  DatabaseResultsStruct? databaseResults,
  SummaryStruct? summary,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    MealStruct(
      testInfo: testInfo ?? (clearUnsetFields ? TestInfoStruct() : null),
      calorieAnalysis: calorieAnalysis ??
          (clearUnsetFields ? CalorieAnalysisStruct() : null),
      databaseResults: databaseResults ??
          (clearUnsetFields ? DatabaseResultsStruct() : null),
      summary: summary ?? (clearUnsetFields ? SummaryStruct() : null),
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

MealStruct? updateMealStruct(
  MealStruct? meal, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    meal
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addMealStructData(
  Map<String, dynamic> firestoreData,
  MealStruct? meal,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (meal == null) {
    return;
  }
  if (meal.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields = !forFieldValue && meal.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final mealData = getMealFirestoreData(meal, forFieldValue);
  final nestedData = mealData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = meal.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getMealFirestoreData(
  MealStruct? meal, [
  bool forFieldValue = false,
]) {
  if (meal == null) {
    return {};
  }
  final firestoreData = mapToFirestore(meal.toMap());

  // Handle nested data for "test_info" field.
  addTestInfoStructData(
    firestoreData,
    meal.hasTestInfo() ? meal.testInfo : null,
    'test_info',
    forFieldValue,
  );

  // Handle nested data for "calorie_analysis" field.
  addCalorieAnalysisStructData(
    firestoreData,
    meal.hasCalorieAnalysis() ? meal.calorieAnalysis : null,
    'calorie_analysis',
    forFieldValue,
  );

  // Handle nested data for "database_results" field.
  addDatabaseResultsStructData(
    firestoreData,
    meal.hasDatabaseResults() ? meal.databaseResults : null,
    'database_results',
    forFieldValue,
  );

  // Handle nested data for "summary" field.
  addSummaryStructData(
    firestoreData,
    meal.hasSummary() ? meal.summary : null,
    'summary',
    forFieldValue,
  );

  // Add any Firestore field values
  meal.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getMealListFirestoreData(
  List<MealStruct>? meals,
) =>
    meals?.map((e) => getMealFirestoreData(e, true)).toList() ?? [];
