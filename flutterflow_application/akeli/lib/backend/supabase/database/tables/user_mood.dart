import '../database.dart';

class UserMoodTable extends SupabaseTable<UserMoodRow> {
  @override
  String get tableName => 'user_mood';

  @override
  UserMoodRow createRow(Map<String, dynamic> data) => UserMoodRow(data);
}

class UserMoodRow extends SupabaseDataRow {
  UserMoodRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserMoodTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int get userId => getField<int>('user_id')!;
  set userId(int value) => setField<int>('user_id', value);

  double? get moodScore => getField<double>('mood_score');
  set moodScore(double? value) => setField<double>('mood_score', value);

  String? get moodType => getField<String>('mood_type');
  set moodType(String? value) => setField<String>('mood_type', value);

  DateTime? get date => getField<DateTime>('date');
  set date(DateTime? value) => setField<DateTime>('date', value);
}
