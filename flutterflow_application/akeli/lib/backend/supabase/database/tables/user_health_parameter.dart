import '../database.dart';

class UserHealthParameterTable extends SupabaseTable<UserHealthParameterRow> {
  @override
  String get tableName => 'user_health_parameter';

  @override
  UserHealthParameterRow createRow(Map<String, dynamic> data) =>
      UserHealthParameterRow(data);
}

class UserHealthParameterRow extends SupabaseDataRow {
  UserHealthParameterRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserHealthParameterTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  int? get weight => getField<int>('weight');
  set weight(int? value) => setField<int>('weight', value);

  String? get sex => getField<String>('sex');
  set sex(String? value) => setField<String>('sex', value);

  int? get age => getField<int>('age');
  set age(int? value) => setField<int>('age', value);

  double? get height => getField<double>('height');
  set height(double? value) => setField<double>('height', value);

  double? get imc => getField<double>('imc');
  set imc(double? value) => setField<double>('imc', value);

  String? get activityLevel => getField<String>('activity_level');
  set activityLevel(String? value) => setField<String>('activity_level', value);

  int? get currentWeight => getField<int>('current_weight');
  set currentWeight(int? value) => setField<int>('current_weight', value);
}
