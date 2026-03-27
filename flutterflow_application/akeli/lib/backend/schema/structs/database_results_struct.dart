// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DatabaseResultsStruct extends FFFirebaseStruct {
  DatabaseResultsStruct({
    bool? mealCreated,
    int? mealIngredientsInserted,
    List<InsertedRecordsStruct>? insertedRecords,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _mealCreated = mealCreated,
        _mealIngredientsInserted = mealIngredientsInserted,
        _insertedRecords = insertedRecords,
        super(firestoreUtilData);

  // "meal_created" field.
  bool? _mealCreated;
  bool get mealCreated => _mealCreated ?? false;
  set mealCreated(bool? val) => _mealCreated = val;

  bool hasMealCreated() => _mealCreated != null;

  // "meal_ingredients_inserted" field.
  int? _mealIngredientsInserted;
  int get mealIngredientsInserted => _mealIngredientsInserted ?? 0;
  set mealIngredientsInserted(int? val) => _mealIngredientsInserted = val;

  void incrementMealIngredientsInserted(int amount) =>
      mealIngredientsInserted = mealIngredientsInserted + amount;

  bool hasMealIngredientsInserted() => _mealIngredientsInserted != null;

  // "inserted_records" field.
  List<InsertedRecordsStruct>? _insertedRecords;
  List<InsertedRecordsStruct> get insertedRecords =>
      _insertedRecords ?? const [];
  set insertedRecords(List<InsertedRecordsStruct>? val) =>
      _insertedRecords = val;

  void updateInsertedRecords(Function(List<InsertedRecordsStruct>) updateFn) {
    updateFn(_insertedRecords ??= []);
  }

  bool hasInsertedRecords() => _insertedRecords != null;

  static DatabaseResultsStruct fromMap(Map<String, dynamic> data) =>
      DatabaseResultsStruct(
        mealCreated: data['meal_created'] as bool?,
        mealIngredientsInserted:
            castToType<int>(data['meal_ingredients_inserted']),
        insertedRecords: getStructList(
          data['inserted_records'],
          InsertedRecordsStruct.fromMap,
        ),
      );

  static DatabaseResultsStruct? maybeFromMap(dynamic data) => data is Map
      ? DatabaseResultsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'meal_created': _mealCreated,
        'meal_ingredients_inserted': _mealIngredientsInserted,
        'inserted_records': _insertedRecords?.map((e) => e.toMap()).toList(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'meal_created': serializeParam(
          _mealCreated,
          ParamType.bool,
        ),
        'meal_ingredients_inserted': serializeParam(
          _mealIngredientsInserted,
          ParamType.int,
        ),
        'inserted_records': serializeParam(
          _insertedRecords,
          ParamType.DataStruct,
          isList: true,
        ),
      }.withoutNulls;

  static DatabaseResultsStruct fromSerializableMap(Map<String, dynamic> data) =>
      DatabaseResultsStruct(
        mealCreated: deserializeParam(
          data['meal_created'],
          ParamType.bool,
          false,
        ),
        mealIngredientsInserted: deserializeParam(
          data['meal_ingredients_inserted'],
          ParamType.int,
          false,
        ),
        insertedRecords: deserializeStructParam<InsertedRecordsStruct>(
          data['inserted_records'],
          ParamType.DataStruct,
          true,
          structBuilder: InsertedRecordsStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'DatabaseResultsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is DatabaseResultsStruct &&
        mealCreated == other.mealCreated &&
        mealIngredientsInserted == other.mealIngredientsInserted &&
        listEquality.equals(insertedRecords, other.insertedRecords);
  }

  @override
  int get hashCode => const ListEquality()
      .hash([mealCreated, mealIngredientsInserted, insertedRecords]);
}

DatabaseResultsStruct createDatabaseResultsStruct({
  bool? mealCreated,
  int? mealIngredientsInserted,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    DatabaseResultsStruct(
      mealCreated: mealCreated,
      mealIngredientsInserted: mealIngredientsInserted,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

DatabaseResultsStruct? updateDatabaseResultsStruct(
  DatabaseResultsStruct? databaseResults, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    databaseResults
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addDatabaseResultsStructData(
  Map<String, dynamic> firestoreData,
  DatabaseResultsStruct? databaseResults,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (databaseResults == null) {
    return;
  }
  if (databaseResults.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && databaseResults.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final databaseResultsData =
      getDatabaseResultsFirestoreData(databaseResults, forFieldValue);
  final nestedData =
      databaseResultsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = databaseResults.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getDatabaseResultsFirestoreData(
  DatabaseResultsStruct? databaseResults, [
  bool forFieldValue = false,
]) {
  if (databaseResults == null) {
    return {};
  }
  final firestoreData = mapToFirestore(databaseResults.toMap());

  // Add any Firestore field values
  databaseResults.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getDatabaseResultsListFirestoreData(
  List<DatabaseResultsStruct>? databaseResultss,
) =>
    databaseResultss
        ?.map((e) => getDatabaseResultsFirestoreData(e, true))
        .toList() ??
    [];
