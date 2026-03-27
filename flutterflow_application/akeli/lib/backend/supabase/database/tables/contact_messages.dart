import '../database.dart';

class ContactMessagesTable extends SupabaseTable<ContactMessagesRow> {
  @override
  String get tableName => 'contact_messages';

  @override
  ContactMessagesRow createRow(Map<String, dynamic> data) =>
      ContactMessagesRow(data);
}

class ContactMessagesRow extends SupabaseDataRow {
  ContactMessagesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ContactMessagesTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  String? get message => getField<String>('message');
  set message(String? value) => setField<String>('message', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
