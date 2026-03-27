import '../database.dart';

class UserMoodInfoTable extends SupabaseTable<UserMoodInfoRow> {
  @override
  String get tableName => 'user_mood_info';

  @override
  UserMoodInfoRow createRow(Map<String, dynamic> data) => UserMoodInfoRow(data);
}

class UserMoodInfoRow extends SupabaseDataRow {
  UserMoodInfoRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserMoodInfoTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
