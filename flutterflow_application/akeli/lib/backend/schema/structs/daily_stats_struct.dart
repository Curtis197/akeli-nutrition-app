// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DailyStatsStruct extends FFFirebaseStruct {
  DailyStatsStruct({
    String? day,
    int? planned,
    int? consumed,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _day = day,
        _planned = planned,
        _consumed = consumed,
        super(firestoreUtilData);

  // "day" field.
  String? _day;
  String get day => _day ?? '';
  set day(String? val) => _day = val;

  bool hasDay() => _day != null;

  // "planned" field.
  int? _planned;
  int get planned => _planned ?? 0;
  set planned(int? val) => _planned = val;

  void incrementPlanned(int amount) => planned = planned + amount;

  bool hasPlanned() => _planned != null;

  // "consumed" field.
  int? _consumed;
  int get consumed => _consumed ?? 0;
  set consumed(int? val) => _consumed = val;

  void incrementConsumed(int amount) => consumed = consumed + amount;

  bool hasConsumed() => _consumed != null;

  static DailyStatsStruct fromMap(Map<String, dynamic> data) =>
      DailyStatsStruct(
        day: data['day'] as String?,
        planned: castToType<int>(data['planned']),
        consumed: castToType<int>(data['consumed']),
      );

  static DailyStatsStruct? maybeFromMap(dynamic data) => data is Map
      ? DailyStatsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'day': _day,
        'planned': _planned,
        'consumed': _consumed,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'day': serializeParam(
          _day,
          ParamType.String,
        ),
        'planned': serializeParam(
          _planned,
          ParamType.int,
        ),
        'consumed': serializeParam(
          _consumed,
          ParamType.int,
        ),
      }.withoutNulls;

  static DailyStatsStruct fromSerializableMap(Map<String, dynamic> data) =>
      DailyStatsStruct(
        day: deserializeParam(
          data['day'],
          ParamType.String,
          false,
        ),
        planned: deserializeParam(
          data['planned'],
          ParamType.int,
          false,
        ),
        consumed: deserializeParam(
          data['consumed'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'DailyStatsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is DailyStatsStruct &&
        day == other.day &&
        planned == other.planned &&
        consumed == other.consumed;
  }

  @override
  int get hashCode => const ListEquality().hash([day, planned, consumed]);
}

DailyStatsStruct createDailyStatsStruct({
  String? day,
  int? planned,
  int? consumed,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    DailyStatsStruct(
      day: day,
      planned: planned,
      consumed: consumed,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

DailyStatsStruct? updateDailyStatsStruct(
  DailyStatsStruct? dailyStats, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    dailyStats
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addDailyStatsStructData(
  Map<String, dynamic> firestoreData,
  DailyStatsStruct? dailyStats,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (dailyStats == null) {
    return;
  }
  if (dailyStats.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && dailyStats.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final dailyStatsData = getDailyStatsFirestoreData(dailyStats, forFieldValue);
  final nestedData = dailyStatsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = dailyStats.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getDailyStatsFirestoreData(
  DailyStatsStruct? dailyStats, [
  bool forFieldValue = false,
]) {
  if (dailyStats == null) {
    return {};
  }
  final firestoreData = mapToFirestore(dailyStats.toMap());

  // Add any Firestore field values
  dailyStats.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getDailyStatsListFirestoreData(
  List<DailyStatsStruct>? dailyStatss,
) =>
    dailyStatss?.map((e) => getDailyStatsFirestoreData(e, true)).toList() ?? [];
