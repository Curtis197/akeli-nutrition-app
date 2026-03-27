// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class IngredientsStruct extends FFFirebaseStruct {
  IngredientsStruct({
    String? ingredientId,
    String? name,
    String? unit,
    String? category,
    int? baseQuantity,
    int? rawAdjustedQuantity,
    int? adjustedQuantity,
    int? scalingFactor,
    int? roundingDifference,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _ingredientId = ingredientId,
        _name = name,
        _unit = unit,
        _category = category,
        _baseQuantity = baseQuantity,
        _rawAdjustedQuantity = rawAdjustedQuantity,
        _adjustedQuantity = adjustedQuantity,
        _scalingFactor = scalingFactor,
        _roundingDifference = roundingDifference,
        super(firestoreUtilData);

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

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  set category(String? val) => _category = val;

  bool hasCategory() => _category != null;

  // "base_quantity" field.
  int? _baseQuantity;
  int get baseQuantity => _baseQuantity ?? 0;
  set baseQuantity(int? val) => _baseQuantity = val;

  void incrementBaseQuantity(int amount) =>
      baseQuantity = baseQuantity + amount;

  bool hasBaseQuantity() => _baseQuantity != null;

  // "raw_adjusted_quantity" field.
  int? _rawAdjustedQuantity;
  int get rawAdjustedQuantity => _rawAdjustedQuantity ?? 0;
  set rawAdjustedQuantity(int? val) => _rawAdjustedQuantity = val;

  void incrementRawAdjustedQuantity(int amount) =>
      rawAdjustedQuantity = rawAdjustedQuantity + amount;

  bool hasRawAdjustedQuantity() => _rawAdjustedQuantity != null;

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

  // "rounding_difference" field.
  int? _roundingDifference;
  int get roundingDifference => _roundingDifference ?? 0;
  set roundingDifference(int? val) => _roundingDifference = val;

  void incrementRoundingDifference(int amount) =>
      roundingDifference = roundingDifference + amount;

  bool hasRoundingDifference() => _roundingDifference != null;

  static IngredientsStruct fromMap(Map<String, dynamic> data) =>
      IngredientsStruct(
        ingredientId: data['ingredient_id'] as String?,
        name: data['name'] as String?,
        unit: data['unit'] as String?,
        category: data['category'] as String?,
        baseQuantity: castToType<int>(data['base_quantity']),
        rawAdjustedQuantity: castToType<int>(data['raw_adjusted_quantity']),
        adjustedQuantity: castToType<int>(data['adjusted_quantity']),
        scalingFactor: castToType<int>(data['scaling_factor']),
        roundingDifference: castToType<int>(data['rounding_difference']),
      );

  static IngredientsStruct? maybeFromMap(dynamic data) => data is Map
      ? IngredientsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'ingredient_id': _ingredientId,
        'name': _name,
        'unit': _unit,
        'category': _category,
        'base_quantity': _baseQuantity,
        'raw_adjusted_quantity': _rawAdjustedQuantity,
        'adjusted_quantity': _adjustedQuantity,
        'scaling_factor': _scalingFactor,
        'rounding_difference': _roundingDifference,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
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
        'category': serializeParam(
          _category,
          ParamType.String,
        ),
        'base_quantity': serializeParam(
          _baseQuantity,
          ParamType.int,
        ),
        'raw_adjusted_quantity': serializeParam(
          _rawAdjustedQuantity,
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
        'rounding_difference': serializeParam(
          _roundingDifference,
          ParamType.int,
        ),
      }.withoutNulls;

  static IngredientsStruct fromSerializableMap(Map<String, dynamic> data) =>
      IngredientsStruct(
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
        category: deserializeParam(
          data['category'],
          ParamType.String,
          false,
        ),
        baseQuantity: deserializeParam(
          data['base_quantity'],
          ParamType.int,
          false,
        ),
        rawAdjustedQuantity: deserializeParam(
          data['raw_adjusted_quantity'],
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
        roundingDifference: deserializeParam(
          data['rounding_difference'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'IngredientsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is IngredientsStruct &&
        ingredientId == other.ingredientId &&
        name == other.name &&
        unit == other.unit &&
        category == other.category &&
        baseQuantity == other.baseQuantity &&
        rawAdjustedQuantity == other.rawAdjustedQuantity &&
        adjustedQuantity == other.adjustedQuantity &&
        scalingFactor == other.scalingFactor &&
        roundingDifference == other.roundingDifference;
  }

  @override
  int get hashCode => const ListEquality().hash([
        ingredientId,
        name,
        unit,
        category,
        baseQuantity,
        rawAdjustedQuantity,
        adjustedQuantity,
        scalingFactor,
        roundingDifference
      ]);
}

IngredientsStruct createIngredientsStruct({
  String? ingredientId,
  String? name,
  String? unit,
  String? category,
  int? baseQuantity,
  int? rawAdjustedQuantity,
  int? adjustedQuantity,
  int? scalingFactor,
  int? roundingDifference,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    IngredientsStruct(
      ingredientId: ingredientId,
      name: name,
      unit: unit,
      category: category,
      baseQuantity: baseQuantity,
      rawAdjustedQuantity: rawAdjustedQuantity,
      adjustedQuantity: adjustedQuantity,
      scalingFactor: scalingFactor,
      roundingDifference: roundingDifference,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

IngredientsStruct? updateIngredientsStruct(
  IngredientsStruct? ingredients, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    ingredients
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addIngredientsStructData(
  Map<String, dynamic> firestoreData,
  IngredientsStruct? ingredients,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (ingredients == null) {
    return;
  }
  if (ingredients.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && ingredients.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final ingredientsData =
      getIngredientsFirestoreData(ingredients, forFieldValue);
  final nestedData =
      ingredientsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = ingredients.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getIngredientsFirestoreData(
  IngredientsStruct? ingredients, [
  bool forFieldValue = false,
]) {
  if (ingredients == null) {
    return {};
  }
  final firestoreData = mapToFirestore(ingredients.toMap());

  // Add any Firestore field values
  ingredients.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getIngredientsListFirestoreData(
  List<IngredientsStruct>? ingredientss,
) =>
    ingredientss?.map((e) => getIngredientsFirestoreData(e, true)).toList() ??
    [];
