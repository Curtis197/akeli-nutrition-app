import '../database.dart';

class LastMessageTimeTable extends SupabaseTable<LastMessageTimeRow> {
  @override
  String get tableName => 'last_message_time';

  @override
  LastMessageTimeRow createRow(Map<String, dynamic> data) =>
      LastMessageTimeRow(data);
}

class LastMessageTimeRow extends SupabaseDataRow {
  LastMessageTimeRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => LastMessageTimeTable();

  int? get id => getField<int>('id');
  set id(int? value) => setField<int>('id', value);

  DateTime? get lastMessageTime => getField<DateTime>('last_message_time');
  set lastMessageTime(DateTime? value) =>
      setField<DateTime>('last_message_time', value);

  DateTime? get localLastMessageTime =>
      getField<DateTime>('local_last_message_time');
  set localLastMessageTime(DateTime? value) =>
      setField<DateTime>('local_last_message_time', value);
}
