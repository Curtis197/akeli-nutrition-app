import '../database.dart';

class SupportTable extends SupabaseTable<SupportRow> {
  @override
  String get tableName => 'support';

  @override
  SupportRow createRow(Map<String, dynamic> data) => SupportRow(data);
}

class SupportRow extends SupabaseDataRow {
  SupportRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SupportTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get mail => getField<String>('mail');
  set mail(String? value) => setField<String>('mail', value);

  String? get text => getField<String>('text');
  set text(String? value) => setField<String>('text', value);

  String? get screenshotUrl => getField<String>('screenshot_url');
  set screenshotUrl(String? value) => setField<String>('screenshot_url', value);
}
