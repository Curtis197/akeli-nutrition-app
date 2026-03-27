// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SummaryStruct extends FFFirebaseStruct {
  SummaryStruct({
    int? totalIngredients,
    int? totalBaseQuantity,
    int? totalAdjustedQuantity,
    int? averageRoundingImpact,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _totalIngredients = totalIngredients,
        _totalBaseQuantity = totalBaseQuantity,
        _totalAdjustedQuantity = totalAdjustedQuantity,
        _averageRoundingImpact = averageRoundingImpact,
        super(firestoreUtilData);

  // "total_ingredients" field.
  int? _totalIngredients;
  int get totalIngredients => _totalIngredients ?? 0;
  set totalIngredients(int? val) => _totalIngredients = val;

  void incrementTotalIngredients(int amount) =>
      totalIngredients = totalIngredients + amount;

  bool hasTotalIngredients() => _totalIngredients != null;

  // "total_base_quantity" field.
  int? _totalBaseQuantity;
  int get totalBaseQuantity => _totalBaseQuantity ?? 0;
  set totalBaseQuantity(int? val) => _totalBaseQuantity = val;

  void incrementTotalBaseQuantity(int amount) =>
      totalBaseQuantity = totalBaseQuantity + amount;

  bool hasTotalBaseQuantity() => _totalBaseQuantity != null;

  // "total_adjusted_quantity" field.
  int? _totalAdjustedQuantity;
  int get totalAdjustedQuantity => _totalAdjustedQuantity ?? 0;
  set totalAdjustedQuantity(int? val) => _totalAdjustedQuantity = val;

  void incrementTotalAdjustedQuantity(int amount) =>
      totalAdjustedQuantity = totalAdjustedQuantity + amount;

  bool hasTotalAdjustedQuantity() => _totalAdjustedQuantity != null;

  // "average_rounding_impact" field.
  int? _averageRoundingImpact;
  int get averageRoundingImpact => _averageRoundingImpact ?? 0;
  set averageRoundingImpact(int? val) => _averageRoundingImpact = val;

  void incrementAverageRoundingImpact(int amount) =>
      averageRoundingImpact = averageRoundingImpact + amount;

  bool hasAverageRoundingImpact() => _averageRoundingImpact != null;

  static SummaryStruct fromMap(Map<String, dynamic> data) => SummaryStruct(
        totalIngredients: castToType<int>(data['total_ingredients']),
        totalBaseQuantity: castToType<int>(data['total_base_quantity']),
        totalAdjustedQuantity: castToType<int>(data['total_adjusted_quantity']),
        averageRoundingImpact: castToType<int>(data['average_rounding_impact']),
      );

  static SummaryStruct? maybeFromMap(dynamic data) =>
      data is Map ? SummaryStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'total_ingredients': _totalIngredients,
        'total_base_quantity': _totalBaseQuantity,
        'total_adjusted_quantity': _totalAdjustedQuantity,
        'average_rounding_impact': _averageRoundingImpact,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'total_ingredients': serializeParam(
          _totalIngredients,
          ParamType.int,
        ),
        'total_base_quantity': serializeParam(
          _totalBaseQuantity,
          ParamType.int,
        ),
        'total_adjusted_quantity': serializeParam(
          _totalAdjustedQuantity,
          ParamType.int,
        ),
        'average_rounding_impact': serializeParam(
          _averageRoundingImpact,
          ParamType.int,
        ),
      }.withoutNulls;

  static SummaryStruct fromSerializableMap(Map<String, dynamic> data) =>
      SummaryStruct(
        totalIngredients: deserializeParam(
          data['total_ingredients'],
          ParamType.int,
          false,
        ),
        totalBaseQuantity: deserializeParam(
          data['total_base_quantity'],
          ParamType.int,
          false,
        ),
        totalAdjustedQuantity: deserializeParam(
          data['total_adjusted_quantity'],
          ParamType.int,
          false,
        ),
        averageRoundingImpact: deserializeParam(
          data['average_rounding_impact'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'SummaryStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is SummaryStruct &&
        totalIngredients == other.totalIngredients &&
        totalBaseQuantity == other.totalBaseQuantity &&
        totalAdjustedQuantity == other.totalAdjustedQuantity &&
        averageRoundingImpact == other.averageRoundingImpact;
  }

  @override
  int get hashCode => const ListEquality().hash([
        totalIngredients,
        totalBaseQuantity,
        totalAdjustedQuantity,
        averageRoundingImpact
      ]);
}

SummaryStruct createSummaryStruct({
  int? totalIngredients,
  int? totalBaseQuantity,
  int? totalAdjustedQuantity,
  int? averageRoundingImpact,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    SummaryStruct(
      totalIngredients: totalIngredients,
      totalBaseQuantity: totalBaseQuantity,
      totalAdjustedQuantity: totalAdjustedQuantity,
      averageRoundingImpact: averageRoundingImpact,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

SummaryStruct? updateSummaryStruct(
  SummaryStruct? summary, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    summary
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addSummaryStructData(
  Map<String, dynamic> firestoreData,
  SummaryStruct? summary,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (summary == null) {
    return;
  }
  if (summary.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && summary.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final summaryData = getSummaryFirestoreData(summary, forFieldValue);
  final nestedData = summaryData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = summary.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getSummaryFirestoreData(
  SummaryStruct? summary, [
  bool forFieldValue = false,
]) {
  if (summary == null) {
    return {};
  }
  final firestoreData = mapToFirestore(summary.toMap());

  // Add any Firestore field values
  summary.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getSummaryListFirestoreData(
  List<SummaryStruct>? summarys,
) =>
    summarys?.map((e) => getSummaryFirestoreData(e, true)).toList() ?? [];
