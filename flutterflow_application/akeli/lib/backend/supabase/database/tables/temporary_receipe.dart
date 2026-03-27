import '../database.dart';

class TemporaryReceipeTable extends SupabaseTable<TemporaryReceipeRow> {
  @override
  String get tableName => 'temporary_receipe';

  @override
  TemporaryReceipeRow createRow(Map<String, dynamic> data) =>
      TemporaryReceipeRow(data);
}

class TemporaryReceipeRow extends SupabaseDataRow {
  TemporaryReceipeRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => TemporaryReceipeTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  int? get tasteRate => getField<int>('taste_rate');
  set tasteRate(int? value) => setField<int>('taste_rate', value);

  int? get tagsId => getField<int>('tags_id');
  set tagsId(int? value) => setField<int>('tags_id', value);

  int? get timeOfCookingMin => getField<int>('time_of_cooking min');
  set timeOfCookingMin(int? value) =>
      setField<int>('time_of_cooking min', value);

  int? get difficultyRate => getField<int>('difficulty_rate');
  set difficultyRate(int? value) => setField<int>('difficulty_rate', value);

  int? get sasietyRate => getField<int>('sasiety_rate');
  set sasietyRate(int? value) => setField<int>('sasiety_rate', value);

  int? get calorie => getField<int>('calorie');
  set calorie(int? value) => setField<int>('calorie', value);

  int? get totalRate => getField<int>('total_rate');
  set totalRate(int? value) => setField<int>('total_rate', value);

  bool? get sansPorc => getField<bool>('sans porc');
  set sansPorc(bool? value) => setField<bool>('sans porc', value);

  List<String> get type => getListField<String>('type');
  set type(List<String>? value) => setListField<String>('type', value);

  String? get creatorId => getField<String>('creator_id');
  set creatorId(String? value) => setField<String>('creator_id', value);

  String? get foodRegion => getField<String>('Food region');
  set foodRegion(String? value) => setField<String>('Food region', value);

  int? get timeOfCookingHour => getField<int>('time of cooking hour');
  set timeOfCookingHour(int? value) =>
      setField<int>('time of cooking hour', value);

  String? get difficulty => getField<String>('difficulty');
  set difficulty(String? value) => setField<String>('difficulty', value);

  bool? get isCleaned => getField<bool>('is_cleaned');
  set isCleaned(bool? value) => setField<bool>('is_cleaned', value);
}
