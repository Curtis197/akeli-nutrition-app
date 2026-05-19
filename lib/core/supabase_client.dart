import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logger.dart';

const _supabaseUrl = 'http://127.0.0.1:54321';
const _supabaseAnonKey = 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';

Future<void> initializeSupabase() async {
  appLogger.d('📡 Supabase: initializing | url: $_supabaseUrl');
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );
  appLogger.i('✅ Supabase: client ready');
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  ref.keepAlive();
  appLogger.d('🔄 Provider: supabaseClientProvider created (keepAlive)');
  return Supabase.instance.client;
});
