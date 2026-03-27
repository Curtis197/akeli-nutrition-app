// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DebugInfoStruct extends FFFirebaseStruct {
  DebugInfoStruct({
    int? macrosRowsFound,
    int? receipeIdSearched,
    OriginalMacrosStruct? originalMacros,
    ScaledMacrosStruct? scaledMacros,
    double? scaleFactor,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _macrosRowsFound = macrosRowsFound,
        _receipeIdSearched = receipeIdSearched,
        _originalMacros = originalMacros,
        _scaledMacros = scaledMacros,
        _scaleFactor = scaleFactor,
        super(firestoreUtilData);

  // "macros_rows_found" field.
  int? _macrosRowsFound;
  int get macrosRowsFound => _macrosRowsFound ?? 0;
  set macrosRowsFound(int? val) => _macrosRowsFound = val;

  void incrementMacrosRowsFound(int amount) =>
      macrosRowsFound = macrosRowsFound + amount;

  bool hasMacrosRowsFound() => _macrosRowsFound != null;

  // "receipe_id_searched" field.
  int? _receipeIdSearched;
  int get receipeIdSearched => _receipeIdSearched ?? 0;
  set receipeIdSearched(int? val) => _receipeIdSearched = val;

  void incrementReceipeIdSearched(int amount) =>
      receipeIdSearched = receipeIdSearched + amount;

  bool hasReceipeIdSearched() => _receipeIdSearched != null;

  // "original_macros" field.
  OriginalMacrosStruct? _originalMacros;
  OriginalMacrosStruct get originalMacros =>
      _originalMacros ?? OriginalMacrosStruct();
  set originalMacros(OriginalMacrosStruct? val) => _originalMacros = val;

  void updateOriginalMacros(Function(OriginalMacrosStruct) updateFn) {
    updateFn(_originalMacros ??= OriginalMacrosStruct());
  }

  bool hasOriginalMacros() => _originalMacros != null;

  // "scaled_macros" field.
  ScaledMacrosStruct? _scaledMacros;
  ScaledMacrosStruct get scaledMacros => _scaledMacros ?? ScaledMacrosStruct();
  set scaledMacros(ScaledMacrosStruct? val) => _scaledMacros = val;

  void updateScaledMacros(Function(ScaledMacrosStruct) updateFn) {
    updateFn(_scaledMacros ??= ScaledMacrosStruct());
  }

  bool hasScaledMacros() => _scaledMacros != null;

  // "scale_factor" field.
  double? _scaleFactor;
  double get scaleFactor => _scaleFactor ?? 0.0;
  set scaleFactor(double? val) => _scaleFactor = val;

  void incrementScaleFactor(double amount) =>
      scaleFactor = scaleFactor + amount;

  bool hasScaleFactor() => _scaleFactor != null;

  static DebugInfoStruct fromMap(Map<String, dynamic> data) => DebugInfoStruct(
        macrosRowsFound: castToType<int>(data['macros_rows_found']),
        receipeIdSearched: castToType<int>(data['receipe_id_searched']),
        originalMacros: data['original_macros'] is OriginalMacrosStruct
            ? data['original_macros']
            : OriginalMacrosStruct.maybeFromMap(data['original_macros']),
        scaledMacros: data['scaled_macros'] is ScaledMacrosStruct
            ? data['scaled_macros']
            : ScaledMacrosStruct.maybeFromMap(data['scaled_macros']),
        scaleFactor: castToType<double>(data['scale_factor']),
      );

  static DebugInfoStruct? maybeFromMap(dynamic data) => data is Map
      ? DebugInfoStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'macros_rows_found': _macrosRowsFound,
        'receipe_id_searched': _receipeIdSearched,
        'original_macros': _originalMacros?.toMap(),
        'scaled_macros': _scaledMacros?.toMap(),
        'scale_factor': _scaleFactor,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'macros_rows_found': serializeParam(
          _macrosRowsFound,
          ParamType.int,
        ),
        'receipe_id_searched': serializeParam(
          _receipeIdSearched,
          ParamType.int,
        ),
        'original_macros': serializeParam(
          _originalMacros,
          ParamType.DataStruct,
        ),
        'scaled_macros': serializeParam(
          _scaledMacros,
          ParamType.DataStruct,
        ),
        'scale_factor': serializeParam(
          _scaleFactor,
          ParamType.double,
        ),
      }.withoutNulls;

  static DebugInfoStruct fromSerializableMap(Map<String, dynamic> data) =>
      DebugInfoStruct(
        macrosRowsFound: deserializeParam(
          data['macros_rows_found'],
          ParamType.int,
          false,
        ),
        receipeIdSearched: deserializeParam(
          data['receipe_id_searched'],
          ParamType.int,
          false,
        ),
        originalMacros: deserializeStructParam(
          data['original_macros'],
          ParamType.DataStruct,
          false,
          structBuilder: OriginalMacrosStruct.fromSerializableMap,
        ),
        scaledMacros: deserializeStructParam(
          data['scaled_macros'],
          ParamType.DataStruct,
          false,
          structBuilder: ScaledMacrosStruct.fromSerializableMap,
        ),
        scaleFactor: deserializeParam(
          data['scale_factor'],
          ParamType.double,
          false,
        ),
      );

  @override
  String toString() => 'DebugInfoStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is DebugInfoStruct &&
        macrosRowsFound == other.macrosRowsFound &&
        receipeIdSearched == other.receipeIdSearched &&
        originalMacros == other.originalMacros &&
        scaledMacros == other.scaledMacros &&
        scaleFactor == other.scaleFactor;
  }

  @override
  int get hashCode => const ListEquality().hash([
        macrosRowsFound,
        receipeIdSearched,
        originalMacros,
        scaledMacros,
        scaleFactor
      ]);
}

DebugInfoStruct createDebugInfoStruct({
  int? macrosRowsFound,
  int? receipeIdSearched,
  OriginalMacrosStruct? originalMacros,
  ScaledMacrosStruct? scaledMacros,
  double? scaleFactor,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    DebugInfoStruct(
      macrosRowsFound: macrosRowsFound,
      receipeIdSearched: receipeIdSearched,
      originalMacros:
          originalMacros ?? (clearUnsetFields ? OriginalMacrosStruct() : null),
      scaledMacros:
          scaledMacros ?? (clearUnsetFields ? ScaledMacrosStruct() : null),
      scaleFactor: scaleFactor,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

DebugInfoStruct? updateDebugInfoStruct(
  DebugInfoStruct? debugInfo, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    debugInfo
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addDebugInfoStructData(
  Map<String, dynamic> firestoreData,
  DebugInfoStruct? debugInfo,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (debugInfo == null) {
    return;
  }
  if (debugInfo.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && debugInfo.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final debugInfoData = getDebugInfoFirestoreData(debugInfo, forFieldValue);
  final nestedData = debugInfoData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = debugInfo.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getDebugInfoFirestoreData(
  DebugInfoStruct? debugInfo, [
  bool forFieldValue = false,
]) {
  if (debugInfo == null) {
    return {};
  }
  final firestoreData = mapToFirestore(debugInfo.toMap());

  // Handle nested data for "original_macros" field.
  addOriginalMacrosStructData(
    firestoreData,
    debugInfo.hasOriginalMacros() ? debugInfo.originalMacros : null,
    'original_macros',
    forFieldValue,
  );

  // Handle nested data for "scaled_macros" field.
  addScaledMacrosStructData(
    firestoreData,
    debugInfo.hasScaledMacros() ? debugInfo.scaledMacros : null,
    'scaled_macros',
    forFieldValue,
  );

  // Add any Firestore field values
  debugInfo.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getDebugInfoListFirestoreData(
  List<DebugInfoStruct>? debugInfos,
) =>
    debugInfos?.map((e) => getDebugInfoFirestoreData(e, true)).toList() ?? [];
