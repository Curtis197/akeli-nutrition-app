// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class OriginalMacrosStruct extends FFFirebaseStruct {
  OriginalMacrosStruct({
    int? protein,
    int? carbs,
    int? fat,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _protein = protein,
        _carbs = carbs,
        _fat = fat,
        super(firestoreUtilData);

  // "protein" field.
  int? _protein;
  int get protein => _protein ?? 0;
  set protein(int? val) => _protein = val;

  void incrementProtein(int amount) => protein = protein + amount;

  bool hasProtein() => _protein != null;

  // "carbs" field.
  int? _carbs;
  int get carbs => _carbs ?? 0;
  set carbs(int? val) => _carbs = val;

  void incrementCarbs(int amount) => carbs = carbs + amount;

  bool hasCarbs() => _carbs != null;

  // "fat" field.
  int? _fat;
  int get fat => _fat ?? 0;
  set fat(int? val) => _fat = val;

  void incrementFat(int amount) => fat = fat + amount;

  bool hasFat() => _fat != null;

  static OriginalMacrosStruct fromMap(Map<String, dynamic> data) =>
      OriginalMacrosStruct(
        protein: castToType<int>(data['protein']),
        carbs: castToType<int>(data['carbs']),
        fat: castToType<int>(data['fat']),
      );

  static OriginalMacrosStruct? maybeFromMap(dynamic data) => data is Map
      ? OriginalMacrosStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'protein': _protein,
        'carbs': _carbs,
        'fat': _fat,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'protein': serializeParam(
          _protein,
          ParamType.int,
        ),
        'carbs': serializeParam(
          _carbs,
          ParamType.int,
        ),
        'fat': serializeParam(
          _fat,
          ParamType.int,
        ),
      }.withoutNulls;

  static OriginalMacrosStruct fromSerializableMap(Map<String, dynamic> data) =>
      OriginalMacrosStruct(
        protein: deserializeParam(
          data['protein'],
          ParamType.int,
          false,
        ),
        carbs: deserializeParam(
          data['carbs'],
          ParamType.int,
          false,
        ),
        fat: deserializeParam(
          data['fat'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'OriginalMacrosStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is OriginalMacrosStruct &&
        protein == other.protein &&
        carbs == other.carbs &&
        fat == other.fat;
  }

  @override
  int get hashCode => const ListEquality().hash([protein, carbs, fat]);
}

OriginalMacrosStruct createOriginalMacrosStruct({
  int? protein,
  int? carbs,
  int? fat,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    OriginalMacrosStruct(
      protein: protein,
      carbs: carbs,
      fat: fat,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

OriginalMacrosStruct? updateOriginalMacrosStruct(
  OriginalMacrosStruct? originalMacros, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    originalMacros
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addOriginalMacrosStructData(
  Map<String, dynamic> firestoreData,
  OriginalMacrosStruct? originalMacros,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (originalMacros == null) {
    return;
  }
  if (originalMacros.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && originalMacros.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final originalMacrosData =
      getOriginalMacrosFirestoreData(originalMacros, forFieldValue);
  final nestedData =
      originalMacrosData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = originalMacros.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getOriginalMacrosFirestoreData(
  OriginalMacrosStruct? originalMacros, [
  bool forFieldValue = false,
]) {
  if (originalMacros == null) {
    return {};
  }
  final firestoreData = mapToFirestore(originalMacros.toMap());

  // Add any Firestore field values
  originalMacros.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getOriginalMacrosListFirestoreData(
  List<OriginalMacrosStruct>? originalMacross,
) =>
    originalMacross
        ?.map((e) => getOriginalMacrosFirestoreData(e, true))
        .toList() ??
    [];
