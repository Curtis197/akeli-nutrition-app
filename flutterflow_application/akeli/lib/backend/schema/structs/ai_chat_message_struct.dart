// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AiChatMessageStruct extends FFFirebaseStruct {
  AiChatMessageStruct({
    String? role,
    String? message,
    String? status,
    String? time,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _role = role,
        _message = message,
        _status = status,
        _time = time,
        super(firestoreUtilData);

  // "role" field.
  String? _role;
  String get role => _role ?? '';
  set role(String? val) => _role = val;

  bool hasRole() => _role != null;

  // "message" field.
  String? _message;
  String get message => _message ?? '';
  set message(String? val) => _message = val;

  bool hasMessage() => _message != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  set status(String? val) => _status = val;

  bool hasStatus() => _status != null;

  // "time" field.
  String? _time;
  String get time => _time ?? '';
  set time(String? val) => _time = val;

  bool hasTime() => _time != null;

  static AiChatMessageStruct fromMap(Map<String, dynamic> data) =>
      AiChatMessageStruct(
        role: data['role'] as String?,
        message: data['message'] as String?,
        status: data['status'] as String?,
        time: data['time'] as String?,
      );

  static AiChatMessageStruct? maybeFromMap(dynamic data) => data is Map
      ? AiChatMessageStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'role': _role,
        'message': _message,
        'status': _status,
        'time': _time,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'role': serializeParam(
          _role,
          ParamType.String,
        ),
        'message': serializeParam(
          _message,
          ParamType.String,
        ),
        'status': serializeParam(
          _status,
          ParamType.String,
        ),
        'time': serializeParam(
          _time,
          ParamType.String,
        ),
      }.withoutNulls;

  static AiChatMessageStruct fromSerializableMap(Map<String, dynamic> data) =>
      AiChatMessageStruct(
        role: deserializeParam(
          data['role'],
          ParamType.String,
          false,
        ),
        message: deserializeParam(
          data['message'],
          ParamType.String,
          false,
        ),
        status: deserializeParam(
          data['status'],
          ParamType.String,
          false,
        ),
        time: deserializeParam(
          data['time'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'AiChatMessageStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is AiChatMessageStruct &&
        role == other.role &&
        message == other.message &&
        status == other.status &&
        time == other.time;
  }

  @override
  int get hashCode => const ListEquality().hash([role, message, status, time]);
}

AiChatMessageStruct createAiChatMessageStruct({
  String? role,
  String? message,
  String? status,
  String? time,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    AiChatMessageStruct(
      role: role,
      message: message,
      status: status,
      time: time,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

AiChatMessageStruct? updateAiChatMessageStruct(
  AiChatMessageStruct? aiChatMessage, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    aiChatMessage
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addAiChatMessageStructData(
  Map<String, dynamic> firestoreData,
  AiChatMessageStruct? aiChatMessage,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (aiChatMessage == null) {
    return;
  }
  if (aiChatMessage.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && aiChatMessage.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final aiChatMessageData =
      getAiChatMessageFirestoreData(aiChatMessage, forFieldValue);
  final nestedData =
      aiChatMessageData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = aiChatMessage.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getAiChatMessageFirestoreData(
  AiChatMessageStruct? aiChatMessage, [
  bool forFieldValue = false,
]) {
  if (aiChatMessage == null) {
    return {};
  }
  final firestoreData = mapToFirestore(aiChatMessage.toMap());

  // Add any Firestore field values
  aiChatMessage.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getAiChatMessageListFirestoreData(
  List<AiChatMessageStruct>? aiChatMessages,
) =>
    aiChatMessages
        ?.map((e) => getAiChatMessageFirestoreData(e, true))
        .toList() ??
    [];
