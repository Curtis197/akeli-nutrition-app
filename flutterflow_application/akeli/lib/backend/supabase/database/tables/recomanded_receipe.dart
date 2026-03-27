import '../database.dart';

class RecomandedReceipeTable extends SupabaseTable<RecomandedReceipeRow> {
  @override
  String get tableName => 'recomanded_receipe';

  @override
  RecomandedReceipeRow createRow(Map<String, dynamic> data) =>
      RecomandedReceipeRow(data);
}

class RecomandedReceipeRow extends SupabaseDataRow {
  RecomandedReceipeRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RecomandedReceipeTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  int? get receipeId => getField<int>('receipe_id');
  set receipeId(int? value) => setField<int>('receipe_id', value);
}
