import '../database.dart';

class LanguageTable extends SupabaseTable<LanguageRow> {
  @override
  String get tableName => 'language';

  @override
  LanguageRow createRow(Map<String, dynamic> data) => LanguageRow(data);
}

class LanguageRow extends SupabaseDataRow {
  LanguageRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => LanguageTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get code => getField<String>('code');
  set code(String? value) => setField<String>('code', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);
}
