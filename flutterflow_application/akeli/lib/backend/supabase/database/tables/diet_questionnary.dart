import '../database.dart';

class DietQuestionnaryTable extends SupabaseTable<DietQuestionnaryRow> {
  @override
  String get tableName => 'diet_questionnary';

  @override
  DietQuestionnaryRow createRow(Map<String, dynamic> data) =>
      DietQuestionnaryRow(data);
}

class DietQuestionnaryRow extends SupabaseDataRow {
  DietQuestionnaryRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => DietQuestionnaryTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get fitnessGaol => getField<String>('fitness_gaol');
  set fitnessGaol(String? value) => setField<String>('fitness_gaol', value);

  String? get activityLevel => getField<String>('activity_level');
  set activityLevel(String? value) => setField<String>('activity_level', value);

  String? get cookingHabit => getField<String>('cooking_habit');
  set cookingHabit(String? value) => setField<String>('cooking_habit', value);

  double? get typicalWeeklyBudget => getField<double>('typical_weekly_budget');
  set typicalWeeklyBudget(double? value) =>
      setField<double>('typical_weekly_budget', value);

  String? get mainReason => getField<String>('main_reason');
  set mainReason(String? value) => setField<String>('main_reason', value);

  String? get favoriteMacro => getField<String>('favorite_macro');
  set favoriteMacro(String? value) => setField<String>('favorite_macro', value);
}
