// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class InsertedRecordsStruct extends FFFirebaseStruct {
  InsertedRecordsStruct({
    int? id,
    String? createdAt,
    int? mealId,
    String? ingredientId,
    String? name,
    String? unit,
    int? baseQuantity,
    int? adjustedQuantity,
    int? scalingFactor,
    String? photoUrl,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _id = id,
        _createdAt = createdAt,
        _mealId = mealId,
        _ingredientId = ingredientId,
        _name = name,
        _unit = unit,
        _baseQuantity = baseQuantity,
        _adjustedQuantity = adjustedQuantity,
        _scalingFactor = scalingFactor,
        _photoUrl = photoUrl,
        super(firestoreUtilData);

  // "id" field.
  int? _id;
  int get id => _id ?? 0;
  set id(int? val) => _id = val;

  void incrementId(int amount) => id = id + amount;

  bool hasId() => _id != null;

  // "created_at" field.
  String? _createdAt;
  String get createdAt => _createdAt ?? '';
  set createdAt(String? val) => _createdAt = val;

  bool hasCreatedAt() => _createdAt != null;

  // "meal_id" field.
  int? _mealId;
  int get mealId => _mealId ?? 0;
  set mealId(int? val) => _mealId = val;

  void incrementMealId(int amount) => mealId = mealId + amount;

  bool hasMealId() => _mealId != null;

  // "ingredient_id" field.
  String? _ingredientId;
  String get ingredientId => _ingredientId ?? '';
  set ingredientId(String? val) => _ingredientId = val;

  bool hasIngredientId() => _ingredientId != null;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  set name(String? val) => _name = val;

  bool hasName() => _name != null;

  // "unit" field.
  String? _unit;
  String get unit => _unit ?? '';
  set unit(String? val) => _unit = val;

  bool hasUnit() => _unit != null;

  // "base_quantity" field.
  int? _baseQuantity;
  int get baseQuantity => _baseQuantity ?? 0;
  set baseQuantity(int? val) => _baseQuantity = val;

  void incrementBaseQuantity(int amount) =>
      baseQuantity = baseQuantity + amount;

  bool hasBaseQuantity() => _baseQuantity != null;

  // "adjusted_quantity" field.
  int? _adjustedQuantity;
  int get adjustedQuantity => _adjustedQuantity ?? 0;
  set adjustedQuantity(int? val) => _adjustedQuantity = val;

  void incrementAdjustedQuantity(int amount) =>
      adjustedQuantity = adjustedQuantity + amount;

  bool hasAdjustedQuantity() => _adjustedQuantity != null;

  // "scaling_factor" field.
  int? _scalingFactor;
  int get scalingFactor => _scalingFactor ?? 0;
  set scalingFactor(int? val) => _scalingFactor = val;

  void incrementScalingFactor(int amount) =>
      scalingFactor = scalingFactor + amount;

  bool hasScalingFactor() => _scalingFactor != null;

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  set photoUrl(String? val) => _photoUrl = val;

  bool hasPhotoUrl() => _photoUrl != null;

  static InsertedRecordsStruct fromMap(Map<String, dynamic> data) =>
      InsertedRecordsStruct(
        id: castToType<int>(data['id']),
        createdAt: data['created_at'] as String?,
        mealId: castToType<int>(data['meal_id']),
        ingredientId: data['ingredient_id'] as String?,
        name: data['name'] as String?,
        unit: data['unit'] as String?,
        baseQuantity: castToType<int>(data['base_quantity']),
        adjustedQuantity: castToType<int>(data['adjusted_quantity']),
        scalingFactor: castToType<int>(data['scaling_factor']),
        photoUrl: data['photo_url'] as String?,
      );

  static InsertedRecordsStruct? maybeFromMap(dynamic data) => data is Map
      ? InsertedRecordsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'created_at': _createdAt,
        'meal_id': _mealId,
        'ingredient_id': _ingredientId,
        'name': _name,
        'unit': _unit,
        'base_quantity': _baseQuantity,
        'adjusted_quantity': _adjustedQuantity,
        'scaling_factor': _scalingFactor,
        'photo_url': _photoUrl,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.int,
        ),
        'created_at': serializeParam(
          _createdAt,
          ParamType.String,
        ),
        'meal_id': serializeParam(
          _mealId,
          ParamType.int,
        ),
        'ingredient_id': serializeParam(
          _ingredientId,
          ParamType.String,
        ),
        'name': serializeParam(
          _name,
          ParamType.String,
        ),
        'unit': serializeParam(
          _unit,
          ParamType.String,
        ),
        'base_quantity': serializeParam(
          _baseQuantity,
          ParamType.int,
        ),
        'adjusted_quantity': serializeParam(
          _adjustedQuantity,
          ParamType.int,
        ),
        'scaling_factor': serializeParam(
          _scalingFactor,
          ParamType.int,
        ),
        'photo_url': serializeParam(
          _photoUrl,
          ParamType.String,
        ),
      }.withoutNulls;

  static InsertedRecordsStruct fromSerializableMap(Map<String, dynamic> data) =>
      InsertedRecordsStruct(
        id: deserializeParam(
          data['id'],
          ParamType.int,
          false,
        ),
        createdAt: deserializeParam(
          data['created_at'],
          ParamType.String,
          false,
        ),
        mealId: deserializeParam(
          data['meal_id'],
          ParamType.int,
          false,
        ),
        ingredientId: deserializeParam(
          data['ingredient_id'],
          ParamType.String,
          false,
        ),
        name: deserializeParam(
          data['name'],
          ParamType.String,
          false,
        ),
        unit: deserializeParam(
          data['unit'],
          ParamType.String,
          false,
        ),
        baseQuantity: deserializeParam(
          data['base_quantity'],
          ParamType.int,
          false,
        ),
        adjustedQuantity: deserializeParam(
          data['adjusted_quantity'],
          ParamType.int,
          false,
        ),
        scalingFactor: deserializeParam(
          data['scaling_factor'],
          ParamType.int,
          false,
        ),
        photoUrl: deserializeParam(
          data['photo_url'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'InsertedRecordsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is InsertedRecordsStruct &&
        id == other.id &&
        createdAt == other.createdAt &&
        mealId == other.mealId &&
        ingredientId == other.ingredientId &&
        name == other.name &&
        unit == other.unit &&
        baseQuantity == other.baseQuantity &&
        adjustedQuantity == other.adjustedQuantity &&
        scalingFactor == other.scalingFactor &&
        photoUrl == other.photoUrl;
  }

  @override
  int get hashCode => const ListEquality().hash([
        id,
        createdAt,
        mealId,
        ingredientId,
        name,
        unit,
        baseQuantity,
        adjustedQuantity,
        scalingFactor,
        photoUrl
      ]);
}

InsertedRecordsStruct createInsertedRecordsStruct({
  int? id,
  String? createdAt,
  int? mealId,
  String? ingredientId,
  String? name,
  String? unit,
  int? baseQuantity,
  int? adjustedQuantity,
  int? scalingFactor,
  String? photoUrl,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    InsertedRecordsStruct(
      id: id,
      createdAt: createdAt,
      mealId: mealId,
      ingredientId: ingredientId,
      name: name,
      unit: unit,
      baseQuantity: baseQuantity,
      adjustedQuantity: adjustedQuantity,
      scalingFactor: scalingFactor,
      photoUrl: photoUrl,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

InsertedRecordsStruct? updateInsertedRecordsStruct(
  InsertedRecordsStruct? insertedRecords, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    insertedRecords
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addInsertedRecordsStructData(
  Map<String, dynamic> firestoreData,
  InsertedRecordsStruct? insertedRecords,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (insertedRecords == null) {
    return;
  }
  if (insertedRecords.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && insertedRecords.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final insertedRecordsData =
      getInsertedRecordsFirestoreData(insertedRecords, forFieldValue);
  final nestedData =
      insertedRecordsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = insertedRecords.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getInsertedRecordsFirestoreData(
  InsertedRecordsStruct? insertedRecords, [
  bool forFieldValue = false,
]) {
  if (insertedRecords == null) {
    return {};
  }
  final firestoreData = mapToFirestore(insertedRecords.toMap());

  // Add any Firestore field values
  insertedRecords.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getInsertedRecordsListFirestoreData(
  List<InsertedRecordsStruct>? insertedRecordss,
) =>
    insertedRecordss
        ?.map((e) => getInsertedRecordsFirestoreData(e, true))
        .toList() ??
    [];
