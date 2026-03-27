// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DietPlanErrorStruct extends FFFirebaseStruct {
  DietPlanErrorStruct({
    bool? success,
    String? errorMessage,
    List<String>? missingTable,
    List<String>? missingFields,
    List<String>? missingFieldsFr,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _success = success,
        _errorMessage = errorMessage,
        _missingTable = missingTable,
        _missingFields = missingFields,
        _missingFieldsFr = missingFieldsFr,
        super(firestoreUtilData);

  // "success" field.
  bool? _success;
  bool get success => _success ?? false;
  set success(bool? val) => _success = val;

  bool hasSuccess() => _success != null;

  // "error_message" field.
  String? _errorMessage;
  String get errorMessage => _errorMessage ?? '';
  set errorMessage(String? val) => _errorMessage = val;

  bool hasErrorMessage() => _errorMessage != null;

  // "missing_table" field.
  List<String>? _missingTable;
  List<String> get missingTable => _missingTable ?? const [];
  set missingTable(List<String>? val) => _missingTable = val;

  void updateMissingTable(Function(List<String>) updateFn) {
    updateFn(_missingTable ??= []);
  }

  bool hasMissingTable() => _missingTable != null;

  // "missing_fields" field.
  List<String>? _missingFields;
  List<String> get missingFields => _missingFields ?? const [];
  set missingFields(List<String>? val) => _missingFields = val;

  void updateMissingFields(Function(List<String>) updateFn) {
    updateFn(_missingFields ??= []);
  }

  bool hasMissingFields() => _missingFields != null;

  // "missing_fields_fr" field.
  List<String>? _missingFieldsFr;
  List<String> get missingFieldsFr => _missingFieldsFr ?? const [];
  set missingFieldsFr(List<String>? val) => _missingFieldsFr = val;

  void updateMissingFieldsFr(Function(List<String>) updateFn) {
    updateFn(_missingFieldsFr ??= []);
  }

  bool hasMissingFieldsFr() => _missingFieldsFr != null;

  static DietPlanErrorStruct fromMap(Map<String, dynamic> data) =>
      DietPlanErrorStruct(
        success: data['success'] as bool?,
        errorMessage: data['error_message'] as String?,
        missingTable: getDataList(data['missing_table']),
        missingFields: getDataList(data['missing_fields']),
        missingFieldsFr: getDataList(data['missing_fields_fr']),
      );

  static DietPlanErrorStruct? maybeFromMap(dynamic data) => data is Map
      ? DietPlanErrorStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'success': _success,
        'error_message': _errorMessage,
        'missing_table': _missingTable,
        'missing_fields': _missingFields,
        'missing_fields_fr': _missingFieldsFr,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'success': serializeParam(
          _success,
          ParamType.bool,
        ),
        'error_message': serializeParam(
          _errorMessage,
          ParamType.String,
        ),
        'missing_table': serializeParam(
          _missingTable,
          ParamType.String,
          isList: true,
        ),
        'missing_fields': serializeParam(
          _missingFields,
          ParamType.String,
          isList: true,
        ),
        'missing_fields_fr': serializeParam(
          _missingFieldsFr,
          ParamType.String,
          isList: true,
        ),
      }.withoutNulls;

  static DietPlanErrorStruct fromSerializableMap(Map<String, dynamic> data) =>
      DietPlanErrorStruct(
        success: deserializeParam(
          data['success'],
          ParamType.bool,
          false,
        ),
        errorMessage: deserializeParam(
          data['error_message'],
          ParamType.String,
          false,
        ),
        missingTable: deserializeParam<String>(
          data['missing_table'],
          ParamType.String,
          true,
        ),
        missingFields: deserializeParam<String>(
          data['missing_fields'],
          ParamType.String,
          true,
        ),
        missingFieldsFr: deserializeParam<String>(
          data['missing_fields_fr'],
          ParamType.String,
          true,
        ),
      );

  @override
  String toString() => 'DietPlanErrorStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is DietPlanErrorStruct &&
        success == other.success &&
        errorMessage == other.errorMessage &&
        listEquality.equals(missingTable, other.missingTable) &&
        listEquality.equals(missingFields, other.missingFields) &&
        listEquality.equals(missingFieldsFr, other.missingFieldsFr);
  }

  @override
  int get hashCode => const ListEquality().hash(
      [success, errorMessage, missingTable, missingFields, missingFieldsFr]);
}

DietPlanErrorStruct createDietPlanErrorStruct({
  bool? success,
  String? errorMessage,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    DietPlanErrorStruct(
      success: success,
      errorMessage: errorMessage,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

DietPlanErrorStruct? updateDietPlanErrorStruct(
  DietPlanErrorStruct? dietPlanError, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    dietPlanError
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addDietPlanErrorStructData(
  Map<String, dynamic> firestoreData,
  DietPlanErrorStruct? dietPlanError,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (dietPlanError == null) {
    return;
  }
  if (dietPlanError.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && dietPlanError.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final dietPlanErrorData =
      getDietPlanErrorFirestoreData(dietPlanError, forFieldValue);
  final nestedData =
      dietPlanErrorData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = dietPlanError.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getDietPlanErrorFirestoreData(
  DietPlanErrorStruct? dietPlanError, [
  bool forFieldValue = false,
]) {
  if (dietPlanError == null) {
    return {};
  }
  final firestoreData = mapToFirestore(dietPlanError.toMap());

  // Add any Firestore field values
  dietPlanError.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getDietPlanErrorListFirestoreData(
  List<DietPlanErrorStruct>? dietPlanErrors,
) =>
    dietPlanErrors
        ?.map((e) => getDietPlanErrorFirestoreData(e, true))
        .toList() ??
    [];
