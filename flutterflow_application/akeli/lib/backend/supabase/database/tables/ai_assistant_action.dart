import '../database.dart';

class AiAssistantActionTable extends SupabaseTable<AiAssistantActionRow> {
  @override
  String get tableName => 'ai_assistant_action';

  @override
  AiAssistantActionRow createRow(Map<String, dynamic> data) =>
      AiAssistantActionRow(data);
}

class AiAssistantActionRow extends SupabaseDataRow {
  AiAssistantActionRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AiAssistantActionTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get resume => getField<String>('resume');
  set resume(String? value) => setField<String>('resume', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String? get triggerType => getField<String>('trigger_type');
  set triggerType(String? value) => setField<String>('trigger_type', value);

  String? get parameters => getField<String>('parameters');
  set parameters(String? value) => setField<String>('parameters', value);

  String? get uiEffect => getField<String>('ui_effect');
  set uiEffect(String? value) => setField<String>('ui_effect', value);

  String? get authorizationSet => getField<String>('authorization_set');
  set authorizationSet(String? value) =>
      setField<String>('authorization_set', value);
}
