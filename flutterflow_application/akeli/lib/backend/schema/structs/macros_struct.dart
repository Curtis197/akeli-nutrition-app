// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MacrosStruct extends FFFirebaseStruct {
  MacrosStruct({
    int? fat,
    int? carbs,
    int? protein,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _fat = fat,
        _carbs = carbs,
        _protein = protein,
        super(firestoreUtilData);

  // "fat" field.
  int? _fat;
  int get fat => _fat ?? 0;
  set fat(int? val) => _fat = val;

  void incrementFat(int amount) => fat = fat + amount;

  bool hasFat() => _fat != null;

  // "carbs" field.
  int? _carbs;
  int get carbs => _carbs ?? 0;
  set carbs(int? val) => _carbs = val;

  void incrementCarbs(int amount) => carbs = carbs + amount;

  bool hasCarbs() => _carbs != null;

  // "protein" field.
  int? _protein;
  int get protein => _protein ?? 0;
  set protein(int? val) => _protein = val;

  void incrementProtein(int amount) => protein = protein + amount;

  bool hasProtein() => _protein != null;

  static MacrosStruct fromMap(Map<String, dynamic> data) => MacrosStruct(
        fat: castToType<int>(data['fat']),
        carbs: castToType<int>(data['carbs']),
        protein: castToType<int>(data['protein']),
      );

  static MacrosStruct? maybeFromMap(dynamic data) =>
      data is Map ? MacrosStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'fat': _fat,
        'carbs': _carbs,
        'protein': _protein,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'fat': serializeParam(
          _fat,
          ParamType.int,
        ),
        'carbs': serializeParam(
          _carbs,
          ParamType.int,
        ),
        'protein': serializeParam(
          _protein,
          ParamType.int,
        ),
      }.withoutNulls;

  static MacrosStruct fromSerializableMap(Map<String, dynamic> data) =>
      MacrosStruct(
        fat: deserializeParam(
          data['fat'],
          ParamType.int,
          false,
        ),
        carbs: deserializeParam(
          data['carbs'],
          ParamType.int,
          false,
        ),
        protein: deserializeParam(
          data['protein'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'MacrosStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is MacrosStruct &&
        fat == other.fat &&
        carbs == other.carbs &&
        protein == other.protein;
  }

  @override
  int get hashCode => const ListEquality().hash([fat, carbs, protein]);
}

MacrosStruct createMacrosStruct({
  int? fat,
  int? carbs,
  int? protein,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    MacrosStruct(
      fat: fat,
      carbs: carbs,
      protein: protein,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

MacrosStruct? updateMacrosStruct(
  MacrosStruct? macros, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    macros
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addMacrosStructData(
  Map<String, dynamic> firestoreData,
  MacrosStruct? macros,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (macros == null) {
    return;
  }
  if (macros.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && macros.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final macrosData = getMacrosFirestoreData(macros, forFieldValue);
  final nestedData = macrosData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = macros.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getMacrosFirestoreData(
  MacrosStruct? macros, [
  bool forFieldValue = false,
]) {
  if (macros == null) {
    return {};
  }
  final firestoreData = mapToFirestore(macros.toMap());

  // Add any Firestore field values
  macros.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getMacrosListFirestoreData(
  List<MacrosStruct>? macross,
) =>
    macross?.map((e) => getMacrosFirestoreData(e, true)).toList() ?? [];
