import '../database.dart';

class WaitlistTable extends SupabaseTable<WaitlistRow> {
  @override
  String get tableName => 'waitlist';

  @override
  WaitlistRow createRow(Map<String, dynamic> data) => WaitlistRow(data);
}

class WaitlistRow extends SupabaseDataRow {
  WaitlistRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => WaitlistTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get email => getField<String>('email')!;
  set email(String value) => setField<String>('email', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get userType => getField<String>('user_type');
  set userType(String? value) => setField<String>('user_type', value);
}
