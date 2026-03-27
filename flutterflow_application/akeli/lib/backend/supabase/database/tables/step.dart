import '../database.dart';

class StepTable extends SupabaseTable<StepRow> {
  @override
  String get tableName => 'step';

  @override
  StepRow createRow(Map<String, dynamic> data) => StepRow(data);
}

class StepRow extends SupabaseDataRow {
  StepRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => StepTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get text => getField<String>('text');
  set text(String? value) => setField<String>('text', value);

  int? get number => getField<int>('number');
  set number(int? value) => setField<int>('number', value);

  int? get receipeId => getField<int>('receipe_id');
  set receipeId(int? value) => setField<int>('receipe_id', value);

  int? get temproraryReceipeId => getField<int>('temprorary_receipe_id');
  set temproraryReceipeId(int? value) =>
      setField<int>('temprorary_receipe_id', value);

  int? get index => getField<int>('index');
  set index(int? value) => setField<int>('index', value);

  bool? get title => getField<bool>('title');
  set title(bool? value) => setField<bool>('title', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
