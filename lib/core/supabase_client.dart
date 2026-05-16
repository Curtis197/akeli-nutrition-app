import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'http://127.0.0.1:54321';
// Publishable anon key — safe to commit; never use service_role key here.
const _supabaseAnonKey =
    'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  ref.keepAlive();
  return Supabase.instance.client;
});
