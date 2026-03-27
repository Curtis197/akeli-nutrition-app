import '../database.dart';

class AiPlanFeedbackTable extends SupabaseTable<AiPlanFeedbackRow> {
  @override
  String get tableName => 'ai_plan_feedback';

  @override
  AiPlanFeedbackRow createRow(Map<String, dynamic> data) =>
      AiPlanFeedbackRow(data);
}

class AiPlanFeedbackRow extends SupabaseDataRow {
  AiPlanFeedbackRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AiPlanFeedbackTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  String? get userTrackId => getField<String>('user_track_id');
  set userTrackId(String? value) => setField<String>('user_track_id', value);

  int? get mealTypeId => getField<int>('meal_type_id');
  set mealTypeId(int? value) => setField<int>('meal_type_id', value);

  String? get feedback => getField<String>('feedback');
  set feedback(String? value) => setField<String>('feedback', value);

  String? get aiResponse => getField<String>('ai_response');
  set aiResponse(String? value) => setField<String>('ai_response', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
