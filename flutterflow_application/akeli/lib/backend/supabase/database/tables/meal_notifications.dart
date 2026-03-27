import '../database.dart';

class MealNotificationsTable extends SupabaseTable<MealNotificationsRow> {
  @override
  String get tableName => 'meal_notifications';

  @override
  MealNotificationsRow createRow(Map<String, dynamic> data) =>
      MealNotificationsRow(data);
}

class MealNotificationsRow extends SupabaseDataRow {
  MealNotificationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MealNotificationsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int get userId => getField<int>('user_id')!;
  set userId(int value) => setField<int>('user_id', value);

  int get mealId => getField<int>('meal_id')!;
  set mealId(int value) => setField<int>('meal_id', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String get body => getField<String>('body')!;
  set body(String value) => setField<String>('body', value);

  DateTime? get sentAt => getField<DateTime>('sent_at');
  set sentAt(DateTime? value) => setField<DateTime>('sent_at', value);

  DateTime? get readAt => getField<DateTime>('read_at');
  set readAt(DateTime? value) => setField<DateTime>('read_at', value);

  DateTime? get clickedAt => getField<DateTime>('clicked_at');
  set clickedAt(DateTime? value) => setField<DateTime>('clicked_at', value);
}
