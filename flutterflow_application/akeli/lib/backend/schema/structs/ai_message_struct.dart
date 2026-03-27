// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AiMessageStruct extends FFFirebaseStruct {
  AiMessageStruct({
    String? role,
    String? status,
    String? message,
    DateTime? time,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _role = role,
        _status = status,
        _message = message,
        _time = time,
        super(firestoreUtilData);

  // "role" field.
  String? _role;
  String get role => _role ?? '';
  set role(String? val) => _role = val;

  bool hasRole() => _role != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  set status(String? val) => _status = val;

  bool hasStatus() => _status != null;

  // "message" field.
  String? _message;
  String get message => _message ?? '';
  set message(String? val) => _message = val;

  bool hasMessage() => _message != null;

  // "time" field.
  DateTime? _time;
  DateTime? get time => _time;
  set time(DateTime? val) => _time = val;

  bool hasTime() => _time != null;

  static AiMessageStruct fromMap(Map<String, dynamic> data) => AiMessageStruct(
        role: data['role'] as String?,
        status: data['status'] as String?,
        message: data['message'] as String?,
        time: data['time'] as DateTime?,
      );

  static AiMessageStruct? maybeFromMap(dynamic data) => data is Map
      ? AiMessageStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'role': _role,
        'status': _status,
        'message': _message,
        'time': _time,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'role': serializeParam(
          _role,
          ParamType.String,
        ),
        'status': serializeParam(
          _status,
          ParamType.String,
        ),
        'message': serializeParam(
          _message,
          ParamType.String,
        ),
        'time': serializeParam(
          _time,
          ParamType.DateTime,
        ),
      }.withoutNulls;

  static AiMessageStruct fromSerializableMap(Map<String, dynamic> data) =>
      AiMessageStruct(
        role: deserializeParam(
          data['role'],
          ParamType.String,
          false,
        ),
        status: deserializeParam(
          data['status'],
          ParamType.String,
          false,
        ),
        message: deserializeParam(
          data['message'],
          ParamType.String,
          false,
        ),
        time: deserializeParam(
          data['time'],
          ParamType.DateTime,
          false,
        ),
      );

  @override
  String toString() => 'AiMessageStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is AiMessageStruct &&
        role == other.role &&
        status == other.status &&
        message == other.message &&
        time == other.time;
  }

  @override
  int get hashCode => const ListEquality().hash([role, status, message, time]);
}

AiMessageStruct createAiMessageStruct({
  String? role,
  String? status,
  String? message,
  DateTime? time,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    AiMessageStruct(
      role: role,
      status: status,
      message: message,
      time: time,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

AiMessageStruct? updateAiMessageStruct(
  AiMessageStruct? aiMessage, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    aiMessage
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addAiMessageStructData(
  Map<String, dynamic> firestoreData,
  AiMessageStruct? aiMessage,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (aiMessage == null) {
    return;
  }
  if (aiMessage.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && aiMessage.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final aiMessageData = getAiMessageFirestoreData(aiMessage, forFieldValue);
  final nestedData = aiMessageData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = aiMessage.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getAiMessageFirestoreData(
  AiMessageStruct? aiMessage, [
  bool forFieldValue = false,
]) {
  if (aiMessage == null) {
    return {};
  }
  final firestoreData = mapToFirestore(aiMessage.toMap());

  // Add any Firestore field values
  aiMessage.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getAiMessageListFirestoreData(
  List<AiMessageStruct>? aiMessages,
) =>
    aiMessages?.map((e) => getAiMessageFirestoreData(e, true)).toList() ?? [];
