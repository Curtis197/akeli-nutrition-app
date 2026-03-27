// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class RecipesStruct extends FFFirebaseStruct {
  RecipesStruct({
    int? id,
    String? createdAt,
    String? name,
    String? description,
    double? tasteRate,
    int? timeOfCookingMin,
    double? difficultyRate,
    String? sasietyRate,
    int? calorie,
    double? totalRate,
    bool? sansPorc,
    List<String>? type,
    String? creatorId,
    String? foodRegion,
    int? timeOfCookingHour,
    String? difficulty,
    int? commentCount,
    int? likeCount,
    int? mealConsumed,
    List<TagsStruct>? tags,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _id = id,
        _createdAt = createdAt,
        _name = name,
        _description = description,
        _tasteRate = tasteRate,
        _timeOfCookingMin = timeOfCookingMin,
        _difficultyRate = difficultyRate,
        _sasietyRate = sasietyRate,
        _calorie = calorie,
        _totalRate = totalRate,
        _sansPorc = sansPorc,
        _type = type,
        _creatorId = creatorId,
        _foodRegion = foodRegion,
        _timeOfCookingHour = timeOfCookingHour,
        _difficulty = difficulty,
        _commentCount = commentCount,
        _likeCount = likeCount,
        _mealConsumed = mealConsumed,
        _tags = tags,
        super(firestoreUtilData);

  // "id" field.
  int? _id;
  int get id => _id ?? 0;
  set id(int? val) => _id = val;

  void incrementId(int amount) => id = id + amount;

  bool hasId() => _id != null;

  // "created_at" field.
  String? _createdAt;
  String get createdAt => _createdAt ?? '';
  set createdAt(String? val) => _createdAt = val;

  bool hasCreatedAt() => _createdAt != null;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  set name(String? val) => _name = val;

  bool hasName() => _name != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  set description(String? val) => _description = val;

  bool hasDescription() => _description != null;

  // "taste_rate" field.
  double? _tasteRate;
  double get tasteRate => _tasteRate ?? 0.0;
  set tasteRate(double? val) => _tasteRate = val;

  void incrementTasteRate(double amount) => tasteRate = tasteRate + amount;

  bool hasTasteRate() => _tasteRate != null;

  // "time_of_cooking_min" field.
  int? _timeOfCookingMin;
  int get timeOfCookingMin => _timeOfCookingMin ?? 0;
  set timeOfCookingMin(int? val) => _timeOfCookingMin = val;

  void incrementTimeOfCookingMin(int amount) =>
      timeOfCookingMin = timeOfCookingMin + amount;

  bool hasTimeOfCookingMin() => _timeOfCookingMin != null;

  // "difficulty_rate" field.
  double? _difficultyRate;
  double get difficultyRate => _difficultyRate ?? 0.0;
  set difficultyRate(double? val) => _difficultyRate = val;

  void incrementDifficultyRate(double amount) =>
      difficultyRate = difficultyRate + amount;

  bool hasDifficultyRate() => _difficultyRate != null;

  // "sasiety_rate" field.
  String? _sasietyRate;
  String get sasietyRate => _sasietyRate ?? '';
  set sasietyRate(String? val) => _sasietyRate = val;

  bool hasSasietyRate() => _sasietyRate != null;

  // "calorie" field.
  int? _calorie;
  int get calorie => _calorie ?? 0;
  set calorie(int? val) => _calorie = val;

  void incrementCalorie(int amount) => calorie = calorie + amount;

  bool hasCalorie() => _calorie != null;

  // "total_rate" field.
  double? _totalRate;
  double get totalRate => _totalRate ?? 0.0;
  set totalRate(double? val) => _totalRate = val;

  void incrementTotalRate(double amount) => totalRate = totalRate + amount;

  bool hasTotalRate() => _totalRate != null;

  // "sans_porc" field.
  bool? _sansPorc;
  bool get sansPorc => _sansPorc ?? false;
  set sansPorc(bool? val) => _sansPorc = val;

  bool hasSansPorc() => _sansPorc != null;

  // "type" field.
  List<String>? _type;
  List<String> get type => _type ?? const [];
  set type(List<String>? val) => _type = val;

  void updateType(Function(List<String>) updateFn) {
    updateFn(_type ??= []);
  }

  bool hasType() => _type != null;

  // "creator_id" field.
  String? _creatorId;
  String get creatorId => _creatorId ?? '';
  set creatorId(String? val) => _creatorId = val;

  bool hasCreatorId() => _creatorId != null;

  // "Food_Region" field.
  String? _foodRegion;
  String get foodRegion => _foodRegion ?? '';
  set foodRegion(String? val) => _foodRegion = val;

  bool hasFoodRegion() => _foodRegion != null;

  // "time_of_cooking_hour" field.
  int? _timeOfCookingHour;
  int get timeOfCookingHour => _timeOfCookingHour ?? 0;
  set timeOfCookingHour(int? val) => _timeOfCookingHour = val;

  void incrementTimeOfCookingHour(int amount) =>
      timeOfCookingHour = timeOfCookingHour + amount;

  bool hasTimeOfCookingHour() => _timeOfCookingHour != null;

  // "difficulty" field.
  String? _difficulty;
  String get difficulty => _difficulty ?? '';
  set difficulty(String? val) => _difficulty = val;

  bool hasDifficulty() => _difficulty != null;

  // "comment_count" field.
  int? _commentCount;
  int get commentCount => _commentCount ?? 0;
  set commentCount(int? val) => _commentCount = val;

  void incrementCommentCount(int amount) =>
      commentCount = commentCount + amount;

  bool hasCommentCount() => _commentCount != null;

  // "like_count" field.
  int? _likeCount;
  int get likeCount => _likeCount ?? 0;
  set likeCount(int? val) => _likeCount = val;

  void incrementLikeCount(int amount) => likeCount = likeCount + amount;

  bool hasLikeCount() => _likeCount != null;

  // "meal_consumed" field.
  int? _mealConsumed;
  int get mealConsumed => _mealConsumed ?? 0;
  set mealConsumed(int? val) => _mealConsumed = val;

  void incrementMealConsumed(int amount) =>
      mealConsumed = mealConsumed + amount;

  bool hasMealConsumed() => _mealConsumed != null;

  // "tags" field.
  List<TagsStruct>? _tags;
  List<TagsStruct> get tags => _tags ?? const [];
  set tags(List<TagsStruct>? val) => _tags = val;

  void updateTags(Function(List<TagsStruct>) updateFn) {
    updateFn(_tags ??= []);
  }

  bool hasTags() => _tags != null;

  static RecipesStruct fromMap(Map<String, dynamic> data) => RecipesStruct(
        id: castToType<int>(data['id']),
        createdAt: data['created_at'] as String?,
        name: data['name'] as String?,
        description: data['description'] as String?,
        tasteRate: castToType<double>(data['taste_rate']),
        timeOfCookingMin: castToType<int>(data['time_of_cooking_min']),
        difficultyRate: castToType<double>(data['difficulty_rate']),
        sasietyRate: data['sasiety_rate'] as String?,
        calorie: castToType<int>(data['calorie']),
        totalRate: castToType<double>(data['total_rate']),
        sansPorc: data['sans_porc'] as bool?,
        type: getDataList(data['type']),
        creatorId: data['creator_id'] as String?,
        foodRegion: data['Food_Region'] as String?,
        timeOfCookingHour: castToType<int>(data['time_of_cooking_hour']),
        difficulty: data['difficulty'] as String?,
        commentCount: castToType<int>(data['comment_count']),
        likeCount: castToType<int>(data['like_count']),
        mealConsumed: castToType<int>(data['meal_consumed']),
        tags: getStructList(
          data['tags'],
          TagsStruct.fromMap,
        ),
      );

  static RecipesStruct? maybeFromMap(dynamic data) =>
      data is Map ? RecipesStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'created_at': _createdAt,
        'name': _name,
        'description': _description,
        'taste_rate': _tasteRate,
        'time_of_cooking_min': _timeOfCookingMin,
        'difficulty_rate': _difficultyRate,
        'sasiety_rate': _sasietyRate,
        'calorie': _calorie,
        'total_rate': _totalRate,
        'sans_porc': _sansPorc,
        'type': _type,
        'creator_id': _creatorId,
        'Food_Region': _foodRegion,
        'time_of_cooking_hour': _timeOfCookingHour,
        'difficulty': _difficulty,
        'comment_count': _commentCount,
        'like_count': _likeCount,
        'meal_consumed': _mealConsumed,
        'tags': _tags?.map((e) => e.toMap()).toList(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.int,
        ),
        'created_at': serializeParam(
          _createdAt,
          ParamType.String,
        ),
        'name': serializeParam(
          _name,
          ParamType.String,
        ),
        'description': serializeParam(
          _description,
          ParamType.String,
        ),
        'taste_rate': serializeParam(
          _tasteRate,
          ParamType.double,
        ),
        'time_of_cooking_min': serializeParam(
          _timeOfCookingMin,
          ParamType.int,
        ),
        'difficulty_rate': serializeParam(
          _difficultyRate,
          ParamType.double,
        ),
        'sasiety_rate': serializeParam(
          _sasietyRate,
          ParamType.String,
        ),
        'calorie': serializeParam(
          _calorie,
          ParamType.int,
        ),
        'total_rate': serializeParam(
          _totalRate,
          ParamType.double,
        ),
        'sans_porc': serializeParam(
          _sansPorc,
          ParamType.bool,
        ),
        'type': serializeParam(
          _type,
          ParamType.String,
          isList: true,
        ),
        'creator_id': serializeParam(
          _creatorId,
          ParamType.String,
        ),
        'Food_Region': serializeParam(
          _foodRegion,
          ParamType.String,
        ),
        'time_of_cooking_hour': serializeParam(
          _timeOfCookingHour,
          ParamType.int,
        ),
        'difficulty': serializeParam(
          _difficulty,
          ParamType.String,
        ),
        'comment_count': serializeParam(
          _commentCount,
          ParamType.int,
        ),
        'like_count': serializeParam(
          _likeCount,
          ParamType.int,
        ),
        'meal_consumed': serializeParam(
          _mealConsumed,
          ParamType.int,
        ),
        'tags': serializeParam(
          _tags,
          ParamType.DataStruct,
          isList: true,
        ),
      }.withoutNulls;

  static RecipesStruct fromSerializableMap(Map<String, dynamic> data) =>
      RecipesStruct(
        id: deserializeParam(
          data['id'],
          ParamType.int,
          false,
        ),
        createdAt: deserializeParam(
          data['created_at'],
          ParamType.String,
          false,
        ),
        name: deserializeParam(
          data['name'],
          ParamType.String,
          false,
        ),
        description: deserializeParam(
          data['description'],
          ParamType.String,
          false,
        ),
        tasteRate: deserializeParam(
          data['taste_rate'],
          ParamType.double,
          false,
        ),
        timeOfCookingMin: deserializeParam(
          data['time_of_cooking_min'],
          ParamType.int,
          false,
        ),
        difficultyRate: deserializeParam(
          data['difficulty_rate'],
          ParamType.double,
          false,
        ),
        sasietyRate: deserializeParam(
          data['sasiety_rate'],
          ParamType.String,
          false,
        ),
        calorie: deserializeParam(
          data['calorie'],
          ParamType.int,
          false,
        ),
        totalRate: deserializeParam(
          data['total_rate'],
          ParamType.double,
          false,
        ),
        sansPorc: deserializeParam(
          data['sans_porc'],
          ParamType.bool,
          false,
        ),
        type: deserializeParam<String>(
          data['type'],
          ParamType.String,
          true,
        ),
        creatorId: deserializeParam(
          data['creator_id'],
          ParamType.String,
          false,
        ),
        foodRegion: deserializeParam(
          data['Food_Region'],
          ParamType.String,
          false,
        ),
        timeOfCookingHour: deserializeParam(
          data['time_of_cooking_hour'],
          ParamType.int,
          false,
        ),
        difficulty: deserializeParam(
          data['difficulty'],
          ParamType.String,
          false,
        ),
        commentCount: deserializeParam(
          data['comment_count'],
          ParamType.int,
          false,
        ),
        likeCount: deserializeParam(
          data['like_count'],
          ParamType.int,
          false,
        ),
        mealConsumed: deserializeParam(
          data['meal_consumed'],
          ParamType.int,
          false,
        ),
        tags: deserializeStructParam<TagsStruct>(
          data['tags'],
          ParamType.DataStruct,
          true,
          structBuilder: TagsStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'RecipesStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is RecipesStruct &&
        id == other.id &&
        createdAt == other.createdAt &&
        name == other.name &&
        description == other.description &&
        tasteRate == other.tasteRate &&
        timeOfCookingMin == other.timeOfCookingMin &&
        difficultyRate == other.difficultyRate &&
        sasietyRate == other.sasietyRate &&
        calorie == other.calorie &&
        totalRate == other.totalRate &&
        sansPorc == other.sansPorc &&
        listEquality.equals(type, other.type) &&
        creatorId == other.creatorId &&
        foodRegion == other.foodRegion &&
        timeOfCookingHour == other.timeOfCookingHour &&
        difficulty == other.difficulty &&
        commentCount == other.commentCount &&
        likeCount == other.likeCount &&
        mealConsumed == other.mealConsumed &&
        listEquality.equals(tags, other.tags);
  }

  @override
  int get hashCode => const ListEquality().hash([
        id,
        createdAt,
        name,
        description,
        tasteRate,
        timeOfCookingMin,
        difficultyRate,
        sasietyRate,
        calorie,
        totalRate,
        sansPorc,
        type,
        creatorId,
        foodRegion,
        timeOfCookingHour,
        difficulty,
        commentCount,
        likeCount,
        mealConsumed,
        tags
      ]);
}

RecipesStruct createRecipesStruct({
  int? id,
  String? createdAt,
  String? name,
  String? description,
  double? tasteRate,
  int? timeOfCookingMin,
  double? difficultyRate,
  String? sasietyRate,
  int? calorie,
  double? totalRate,
  bool? sansPorc,
  String? creatorId,
  String? foodRegion,
  int? timeOfCookingHour,
  String? difficulty,
  int? commentCount,
  int? likeCount,
  int? mealConsumed,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    RecipesStruct(
      id: id,
      createdAt: createdAt,
      name: name,
      description: description,
      tasteRate: tasteRate,
      timeOfCookingMin: timeOfCookingMin,
      difficultyRate: difficultyRate,
      sasietyRate: sasietyRate,
      calorie: calorie,
      totalRate: totalRate,
      sansPorc: sansPorc,
      creatorId: creatorId,
      foodRegion: foodRegion,
      timeOfCookingHour: timeOfCookingHour,
      difficulty: difficulty,
      commentCount: commentCount,
      likeCount: likeCount,
      mealConsumed: mealConsumed,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

RecipesStruct? updateRecipesStruct(
  RecipesStruct? recipes, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    recipes
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addRecipesStructData(
  Map<String, dynamic> firestoreData,
  RecipesStruct? recipes,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (recipes == null) {
    return;
  }
  if (recipes.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && recipes.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final recipesData = getRecipesFirestoreData(recipes, forFieldValue);
  final nestedData = recipesData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = recipes.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getRecipesFirestoreData(
  RecipesStruct? recipes, [
  bool forFieldValue = false,
]) {
  if (recipes == null) {
    return {};
  }
  final firestoreData = mapToFirestore(recipes.toMap());

  // Add any Firestore field values
  recipes.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getRecipesListFirestoreData(
  List<RecipesStruct>? recipess,
) =>
    recipess?.map((e) => getRecipesFirestoreData(e, true)).toList() ?? [];
