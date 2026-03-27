// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AddMealErrorStruct extends FFFirebaseStruct {
  AddMealErrorStruct({
    bool? success,
    String? error,
    String? uiMessage,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _success = success,
        _error = error,
        _uiMessage = uiMessage,
        super(firestoreUtilData);

  // "success" field.
  bool? _success;
  bool get success => _success ?? false;
  set success(bool? val) => _success = val;

  bool hasSuccess() => _success != null;

  // "error" field.
  String? _error;
  String get error => _error ?? '';
  set error(String? val) => _error = val;

  bool hasError() => _error != null;

  // "ui_message" field.
  String? _uiMessage;
  String get uiMessage => _uiMessage ?? '';
  set uiMessage(String? val) => _uiMessage = val;

  bool hasUiMessage() => _uiMessage != null;

  static AddMealErrorStruct fromMap(Map<String, dynamic> data) =>
      AddMealErrorStruct(
        success: data['success'] as bool?,
        error: data['error'] as String?,
        uiMessage: data['ui_message'] as String?,
      );

  static AddMealErrorStruct? maybeFromMap(dynamic data) => data is Map
      ? AddMealErrorStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'success': _success,
        'error': _error,
        'ui_message': _uiMessage,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'success': serializeParam(
          _success,
          ParamType.bool,
        ),
        'error': serializeParam(
          _error,
          ParamType.String,
        ),
        'ui_message': serializeParam(
          _uiMessage,
          ParamType.String,
        ),
      }.withoutNulls;

  static AddMealErrorStruct fromSerializableMap(Map<String, dynamic> data) =>
      AddMealErrorStruct(
        success: deserializeParam(
          data['success'],
          ParamType.bool,
          false,
        ),
        error: deserializeParam(
          data['error'],
          ParamType.String,
          false,
        ),
        uiMessage: deserializeParam(
          data['ui_message'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'AddMealErrorStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is AddMealErrorStruct &&
        success == other.success &&
        error == other.error &&
        uiMessage == other.uiMessage;
  }

  @override
  int get hashCode => const ListEquality().hash([success, error, uiMessage]);
}

AddMealErrorStruct createAddMealErrorStruct({
  bool? success,
  String? error,
  String? uiMessage,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    AddMealErrorStruct(
      success: success,
      error: error,
      uiMessage: uiMessage,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

AddMealErrorStruct? updateAddMealErrorStruct(
  AddMealErrorStruct? addMealError, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    addMealError
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addAddMealErrorStructData(
  Map<String, dynamic> firestoreData,
  AddMealErrorStruct? addMealError,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (addMealError == null) {
    return;
  }
  if (addMealError.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && addMealError.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final addMealErrorData =
      getAddMealErrorFirestoreData(addMealError, forFieldValue);
  final nestedData =
      addMealErrorData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = addMealError.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getAddMealErrorFirestoreData(
  AddMealErrorStruct? addMealError, [
  bool forFieldValue = false,
]) {
  if (addMealError == null) {
    return {};
  }
  final firestoreData = mapToFirestore(addMealError.toMap());

  // Add any Firestore field values
  addMealError.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getAddMealErrorListFirestoreData(
  List<AddMealErrorStruct>? addMealErrors,
) =>
    addMealErrors?.map((e) => getAddMealErrorFirestoreData(e, true)).toList() ??
    [];
