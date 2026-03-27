// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class NotificationMetadataStruct extends FFFirebaseStruct {
  NotificationMetadataStruct({
    String? calories,
    String? mealType,
    String? firstName,
    String? recipeName,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _calories = calories,
        _mealType = mealType,
        _firstName = firstName,
        _recipeName = recipeName,
        super(firestoreUtilData);

  // "calories" field.
  String? _calories;
  String get calories => _calories ?? '';
  set calories(String? val) => _calories = val;

  bool hasCalories() => _calories != null;

  // "meal_type" field.
  String? _mealType;
  String get mealType => _mealType ?? '';
  set mealType(String? val) => _mealType = val;

  bool hasMealType() => _mealType != null;

  // "first_name" field.
  String? _firstName;
  String get firstName => _firstName ?? '';
  set firstName(String? val) => _firstName = val;

  bool hasFirstName() => _firstName != null;

  // "recipe_name" field.
  String? _recipeName;
  String get recipeName => _recipeName ?? '';
  set recipeName(String? val) => _recipeName = val;

  bool hasRecipeName() => _recipeName != null;

  static NotificationMetadataStruct fromMap(Map<String, dynamic> data) =>
      NotificationMetadataStruct(
        calories: data['calories'] as String?,
        mealType: data['meal_type'] as String?,
        firstName: data['first_name'] as String?,
        recipeName: data['recipe_name'] as String?,
      );

  static NotificationMetadataStruct? maybeFromMap(dynamic data) => data is Map
      ? NotificationMetadataStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'calories': _calories,
        'meal_type': _mealType,
        'first_name': _firstName,
        'recipe_name': _recipeName,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'calories': serializeParam(
          _calories,
          ParamType.String,
        ),
        'meal_type': serializeParam(
          _mealType,
          ParamType.String,
        ),
        'first_name': serializeParam(
          _firstName,
          ParamType.String,
        ),
        'recipe_name': serializeParam(
          _recipeName,
          ParamType.String,
        ),
      }.withoutNulls;

  static NotificationMetadataStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      NotificationMetadataStruct(
        calories: deserializeParam(
          data['calories'],
          ParamType.String,
          false,
        ),
        mealType: deserializeParam(
          data['meal_type'],
          ParamType.String,
          false,
        ),
        firstName: deserializeParam(
          data['first_name'],
          ParamType.String,
          false,
        ),
        recipeName: deserializeParam(
          data['recipe_name'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'NotificationMetadataStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is NotificationMetadataStruct &&
        calories == other.calories &&
        mealType == other.mealType &&
        firstName == other.firstName &&
        recipeName == other.recipeName;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([calories, mealType, firstName, recipeName]);
}

NotificationMetadataStruct createNotificationMetadataStruct({
  String? calories,
  String? mealType,
  String? firstName,
  String? recipeName,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    NotificationMetadataStruct(
      calories: calories,
      mealType: mealType,
      firstName: firstName,
      recipeName: recipeName,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

NotificationMetadataStruct? updateNotificationMetadataStruct(
  NotificationMetadataStruct? notificationMetadata, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    notificationMetadata
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addNotificationMetadataStructData(
  Map<String, dynamic> firestoreData,
  NotificationMetadataStruct? notificationMetadata,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (notificationMetadata == null) {
    return;
  }
  if (notificationMetadata.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && notificationMetadata.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final notificationMetadataData =
      getNotificationMetadataFirestoreData(notificationMetadata, forFieldValue);
  final nestedData =
      notificationMetadataData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields =
      notificationMetadata.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getNotificationMetadataFirestoreData(
  NotificationMetadataStruct? notificationMetadata, [
  bool forFieldValue = false,
]) {
  if (notificationMetadata == null) {
    return {};
  }
  final firestoreData = mapToFirestore(notificationMetadata.toMap());

  // Add any Firestore field values
  notificationMetadata.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getNotificationMetadataListFirestoreData(
  List<NotificationMetadataStruct>? notificationMetadatas,
) =>
    notificationMetadatas
        ?.map((e) => getNotificationMetadataFirestoreData(e, true))
        .toList() ??
    [];
