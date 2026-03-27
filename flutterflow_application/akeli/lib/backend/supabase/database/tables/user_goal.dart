import '../database.dart';

class UserGoalTable extends SupabaseTable<UserGoalRow> {
  @override
  String get tableName => 'user_goal';

  @override
  UserGoalRow createRow(Map<String, dynamic> data) => UserGoalRow(data);
}

class UserGoalRow extends SupabaseDataRow {
  UserGoalRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserGoalTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int? get targetWeight => getField<int>('target_weight');
  set targetWeight(int? value) => setField<int>('target_weight', value);

  double? get targetCalorie => getField<double>('target_calorie');
  set targetCalorie(double? value) => setField<double>('target_calorie', value);

  double? get targetWater => getField<double>('target_water');
  set targetWater(double? value) => setField<double>('target_water', value);

  String? get targetType => getField<String>('target_type');
  set targetType(String? value) => setField<String>('target_type', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  double? get targetFat => getField<double>('target_fat');
  set targetFat(double? value) => setField<double>('target_fat', value);

  double? get targetCarb => getField<double>('target_carb');
  set targetCarb(double? value) => setField<double>('target_carb', value);

  double? get targetProtein => getField<double>('target_protein');
  set targetProtein(double? value) => setField<double>('target_protein', value);

  double? get targetTime => getField<double>('target_time');
  set targetTime(double? value) => setField<double>('target_time', value);

  double? get breakfastCalorie => getField<double>('breakfast_calorie');
  set breakfastCalorie(double? value) =>
      setField<double>('breakfast_calorie', value);

  double? get lunchCalorie => getField<double>('lunch_calorie');
  set lunchCalorie(double? value) => setField<double>('lunch_calorie', value);

  double? get dinnerCalorie => getField<double>('dinner_calorie');
  set dinnerCalorie(double? value) => setField<double>('dinner_calorie', value);

  double? get snackCalorie => getField<double>('snack_calorie');
  set snackCalorie(double? value) => setField<double>('snack_calorie', value);

  double? get successRate => getField<double>('Success_rate');
  set successRate(double? value) => setField<double>('Success_rate', value);

  double? get weeklyWeightLoss => getField<double>('weekly_weight_loss');
  set weeklyWeightLoss(double? value) =>
      setField<double>('weekly_weight_loss', value);

  String? get objectif => getField<String>('objectif');
  set objectif(String? value) => setField<String>('objectif', value);
}
