import '../database.dart';

class UpdatedWeightTable extends SupabaseTable<UpdatedWeightRow> {
  @override
  String get tableName => 'updated_weight';

  @override
  UpdatedWeightRow createRow(Map<String, dynamic> data) =>
      UpdatedWeightRow(data);
}

class UpdatedWeightRow extends SupabaseDataRow {
  UpdatedWeightRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UpdatedWeightTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  int? get weight => getField<int>('weight');
  set weight(int? value) => setField<int>('weight', value);

  DateTime? get date => getField<DateTime>('date');
  set date(DateTime? value) => setField<DateTime>('date', value);
}
