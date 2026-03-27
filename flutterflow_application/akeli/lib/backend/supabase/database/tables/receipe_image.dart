import '../database.dart';

class ReceipeImageTable extends SupabaseTable<ReceipeImageRow> {
  @override
  String get tableName => 'receipe_image';

  @override
  ReceipeImageRow createRow(Map<String, dynamic> data) => ReceipeImageRow(data);
}

class ReceipeImageRow extends SupabaseDataRow {
  ReceipeImageRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ReceipeImageTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get url => getField<String>('url');
  set url(String? value) => setField<String>('url', value);

  int? get receipeId => getField<int>('receipe_id');
  set receipeId(int? value) => setField<int>('receipe_id', value);

  String? get type => getField<String>('type');
  set type(String? value) => setField<String>('type', value);

  int? get index => getField<int>('index');
  set index(int? value) => setField<int>('index', value);

  int? get temporaryReceipeId => getField<int>('temporary_receipe_id');
  set temporaryReceipeId(int? value) =>
      setField<int>('temporary_receipe_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
