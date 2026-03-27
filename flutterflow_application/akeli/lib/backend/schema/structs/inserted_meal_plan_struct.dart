// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class InsertedMealPlanStruct extends FFFirebaseStruct {
  InsertedMealPlanStruct({
    bool? success,
    String? message,
    int? mealPlanId,
    int? userId,
    String? startDate,
    String? endDate,
    bool? mealGenerated,
    bool? ingredientsGenerated,
    bool? shoppingListCreated,
    String? createdAt,
    bool? alreadyExists,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _success = success,
        _message = message,
        _mealPlanId = mealPlanId,
        _userId = userId,
        _startDate = startDate,
        _endDate = endDate,
        _mealGenerated = mealGenerated,
        _ingredientsGenerated = ingredientsGenerated,
        _shoppingListCreated = shoppingListCreated,
        _createdAt = createdAt,
        _alreadyExists = alreadyExists,
        super(firestoreUtilData);

  // "success" field.
  bool? _success;
  bool get success => _success ?? false;
  set success(bool? val) => _success = val;

  bool hasSuccess() => _success != null;

  // "message" field.
  String? _message;
  String get message => _message ?? '';
  set message(String? val) => _message = val;

  bool hasMessage() => _message != null;

  // "meal_plan_id" field.
  int? _mealPlanId;
  int get mealPlanId => _mealPlanId ?? 0;
  set mealPlanId(int? val) => _mealPlanId = val;

  void incrementMealPlanId(int amount) => mealPlanId = mealPlanId + amount;

  bool hasMealPlanId() => _mealPlanId != null;

  // "user_id" field.
  int? _userId;
  int get userId => _userId ?? 0;
  set userId(int? val) => _userId = val;

  void incrementUserId(int amount) => userId = userId + amount;

  bool hasUserId() => _userId != null;

  // "start_date" field.
  String? _startDate;
  String get startDate => _startDate ?? '';
  set startDate(String? val) => _startDate = val;

  bool hasStartDate() => _startDate != null;

  // "end_date" field.
  String? _endDate;
  String get endDate => _endDate ?? '';
  set endDate(String? val) => _endDate = val;

  bool hasEndDate() => _endDate != null;

  // "meal_generated" field.
  bool? _mealGenerated;
  bool get mealGenerated => _mealGenerated ?? false;
  set mealGenerated(bool? val) => _mealGenerated = val;

  bool hasMealGenerated() => _mealGenerated != null;

  // "ingredients_generated" field.
  bool? _ingredientsGenerated;
  bool get ingredientsGenerated => _ingredientsGenerated ?? false;
  set ingredientsGenerated(bool? val) => _ingredientsGenerated = val;

  bool hasIngredientsGenerated() => _ingredientsGenerated != null;

  // "shopping_list_created" field.
  bool? _shoppingListCreated;
  bool get shoppingListCreated => _shoppingListCreated ?? false;
  set shoppingListCreated(bool? val) => _shoppingListCreated = val;

  bool hasShoppingListCreated() => _shoppingListCreated != null;

  // "created_at" field.
  String? _createdAt;
  String get createdAt => _createdAt ?? '';
  set createdAt(String? val) => _createdAt = val;

  bool hasCreatedAt() => _createdAt != null;

  // "already_exists" field.
  bool? _alreadyExists;
  bool get alreadyExists => _alreadyExists ?? false;
  set alreadyExists(bool? val) => _alreadyExists = val;

  bool hasAlreadyExists() => _alreadyExists != null;

  static InsertedMealPlanStruct fromMap(Map<String, dynamic> data) =>
      InsertedMealPlanStruct(
        success: data['success'] as bool?,
        message: data['message'] as String?,
        mealPlanId: castToType<int>(data['meal_plan_id']),
        userId: castToType<int>(data['user_id']),
        startDate: data['start_date'] as String?,
        endDate: data['end_date'] as String?,
        mealGenerated: data['meal_generated'] as bool?,
        ingredientsGenerated: data['ingredients_generated'] as bool?,
        shoppingListCreated: data['shopping_list_created'] as bool?,
        createdAt: data['created_at'] as String?,
        alreadyExists: data['already_exists'] as bool?,
      );

  static InsertedMealPlanStruct? maybeFromMap(dynamic data) => data is Map
      ? InsertedMealPlanStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'success': _success,
        'message': _message,
        'meal_plan_id': _mealPlanId,
        'user_id': _userId,
        'start_date': _startDate,
        'end_date': _endDate,
        'meal_generated': _mealGenerated,
        'ingredients_generated': _ingredientsGenerated,
        'shopping_list_created': _shoppingListCreated,
        'created_at': _createdAt,
        'already_exists': _alreadyExists,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'success': serializeParam(
          _success,
          ParamType.bool,
        ),
        'message': serializeParam(
          _message,
          ParamType.String,
        ),
        'meal_plan_id': serializeParam(
          _mealPlanId,
          ParamType.int,
        ),
        'user_id': serializeParam(
          _userId,
          ParamType.int,
        ),
        'start_date': serializeParam(
          _startDate,
          ParamType.String,
        ),
        'end_date': serializeParam(
          _endDate,
          ParamType.String,
        ),
        'meal_generated': serializeParam(
          _mealGenerated,
          ParamType.bool,
        ),
        'ingredients_generated': serializeParam(
          _ingredientsGenerated,
          ParamType.bool,
        ),
        'shopping_list_created': serializeParam(
          _shoppingListCreated,
          ParamType.bool,
        ),
        'created_at': serializeParam(
          _createdAt,
          ParamType.String,
        ),
        'already_exists': serializeParam(
          _alreadyExists,
          ParamType.bool,
        ),
      }.withoutNulls;

  static InsertedMealPlanStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      InsertedMealPlanStruct(
        success: deserializeParam(
          data['success'],
          ParamType.bool,
          false,
        ),
        message: deserializeParam(
          data['message'],
          ParamType.String,
          false,
        ),
        mealPlanId: deserializeParam(
          data['meal_plan_id'],
          ParamType.int,
          false,
        ),
        userId: deserializeParam(
          data['user_id'],
          ParamType.int,
          false,
        ),
        startDate: deserializeParam(
          data['start_date'],
          ParamType.String,
          false,
        ),
        endDate: deserializeParam(
          data['end_date'],
          ParamType.String,
          false,
        ),
        mealGenerated: deserializeParam(
          data['meal_generated'],
          ParamType.bool,
          false,
        ),
        ingredientsGenerated: deserializeParam(
          data['ingredients_generated'],
          ParamType.bool,
          false,
        ),
        shoppingListCreated: deserializeParam(
          data['shopping_list_created'],
          ParamType.bool,
          false,
        ),
        createdAt: deserializeParam(
          data['created_at'],
          ParamType.String,
          false,
        ),
        alreadyExists: deserializeParam(
          data['already_exists'],
          ParamType.bool,
          false,
        ),
      );

  @override
  String toString() => 'InsertedMealPlanStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is InsertedMealPlanStruct &&
        success == other.success &&
        message == other.message &&
        mealPlanId == other.mealPlanId &&
        userId == other.userId &&
        startDate == other.startDate &&
        endDate == other.endDate &&
        mealGenerated == other.mealGenerated &&
        ingredientsGenerated == other.ingredientsGenerated &&
        shoppingListCreated == other.shoppingListCreated &&
        createdAt == other.createdAt &&
        alreadyExists == other.alreadyExists;
  }

  @override
  int get hashCode => const ListEquality().hash([
        success,
        message,
        mealPlanId,
        userId,
        startDate,
        endDate,
        mealGenerated,
        ingredientsGenerated,
        shoppingListCreated,
        createdAt,
        alreadyExists
      ]);
}

InsertedMealPlanStruct createInsertedMealPlanStruct({
  bool? success,
  String? message,
  int? mealPlanId,
  int? userId,
  String? startDate,
  String? endDate,
  bool? mealGenerated,
  bool? ingredientsGenerated,
  bool? shoppingListCreated,
  String? createdAt,
  bool? alreadyExists,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    InsertedMealPlanStruct(
      success: success,
      message: message,
      mealPlanId: mealPlanId,
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      mealGenerated: mealGenerated,
      ingredientsGenerated: ingredientsGenerated,
      shoppingListCreated: shoppingListCreated,
      createdAt: createdAt,
      alreadyExists: alreadyExists,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

InsertedMealPlanStruct? updateInsertedMealPlanStruct(
  InsertedMealPlanStruct? insertedMealPlan, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    insertedMealPlan
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addInsertedMealPlanStructData(
  Map<String, dynamic> firestoreData,
  InsertedMealPlanStruct? insertedMealPlan,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (insertedMealPlan == null) {
    return;
  }
  if (insertedMealPlan.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && insertedMealPlan.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final insertedMealPlanData =
      getInsertedMealPlanFirestoreData(insertedMealPlan, forFieldValue);
  final nestedData =
      insertedMealPlanData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = insertedMealPlan.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getInsertedMealPlanFirestoreData(
  InsertedMealPlanStruct? insertedMealPlan, [
  bool forFieldValue = false,
]) {
  if (insertedMealPlan == null) {
    return {};
  }
  final firestoreData = mapToFirestore(insertedMealPlan.toMap());

  // Add any Firestore field values
  insertedMealPlan.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getInsertedMealPlanListFirestoreData(
  List<InsertedMealPlanStruct>? insertedMealPlans,
) =>
    insertedMealPlans
        ?.map((e) => getInsertedMealPlanFirestoreData(e, true))
        .toList() ??
    [];
