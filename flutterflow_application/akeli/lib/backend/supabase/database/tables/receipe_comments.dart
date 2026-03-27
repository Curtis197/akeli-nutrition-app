import '../database.dart';

class ReceipeCommentsTable extends SupabaseTable<ReceipeCommentsRow> {
  @override
  String get tableName => 'receipe_comments';

  @override
  ReceipeCommentsRow createRow(Map<String, dynamic> data) =>
      ReceipeCommentsRow(data);
}

class ReceipeCommentsRow extends SupabaseDataRow {
  ReceipeCommentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ReceipeCommentsTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get receipeId => getField<int>('receipe_id');
  set receipeId(int? value) => setField<int>('receipe_id', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  String? get text => getField<String>('text');
  set text(String? value) => setField<String>('text', value);

  double? get rate => getField<double>('rate');
  set rate(double? value) => setField<double>('rate', value);
}
