import '../database.dart';

class RoundTypeTable extends SupabaseTable<RoundTypeRow> {
  @override
  String get tableName => 'round_type';

  @override
  RoundTypeRow createRow(Map<String, dynamic> data) => RoundTypeRow(data);
}

class RoundTypeRow extends SupabaseDataRow {
  RoundTypeRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RoundTypeTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get text => getField<String>('text');
  set text(String? value) => setField<String>('text', value);

  String? get language => getField<String>('language');
  set language(String? value) => setField<String>('language', value);

  int? get index => getField<int>('index');
  set index(int? value) => setField<int>('index', value);
}
