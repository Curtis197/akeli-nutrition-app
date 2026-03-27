import '../database.dart';

class UserAllergiesTable extends SupabaseTable<UserAllergiesRow> {
  @override
  String get tableName => 'user_allergies';

  @override
  UserAllergiesRow createRow(Map<String, dynamic> data) =>
      UserAllergiesRow(data);
}

class UserAllergiesRow extends SupabaseDataRow {
  UserAllergiesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserAllergiesTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);
}
