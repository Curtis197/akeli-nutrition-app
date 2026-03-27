import '../database.dart';

class ActivityLevelTable extends SupabaseTable<ActivityLevelRow> {
  @override
  String get tableName => 'activity_level';

  @override
  ActivityLevelRow createRow(Map<String, dynamic> data) =>
      ActivityLevelRow(data);
}

class ActivityLevelRow extends SupabaseDataRow {
  ActivityLevelRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ActivityLevelTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);
}
