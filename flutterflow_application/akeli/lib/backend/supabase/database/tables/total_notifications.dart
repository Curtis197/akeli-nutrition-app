import '../database.dart';

class TotalNotificationsTable extends SupabaseTable<TotalNotificationsRow> {
  @override
  String get tableName => 'total_notifications';

  @override
  TotalNotificationsRow createRow(Map<String, dynamic> data) =>
      TotalNotificationsRow(data);
}

class TotalNotificationsRow extends SupabaseDataRow {
  TotalNotificationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => TotalNotificationsTable();

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  int? get totalNotification => getField<int>('total_notification');
  set totalNotification(int? value) =>
      setField<int>('total_notification', value);

  int? get chatCount => getField<int>('chat_count');
  set chatCount(int? value) => setField<int>('chat_count', value);

  int? get demandCount => getField<int>('demand_count');
  set demandCount(int? value) => setField<int>('demand_count', value);

  int? get mealCount => getField<int>('meal_count');
  set mealCount(int? value) => setField<int>('meal_count', value);
}
