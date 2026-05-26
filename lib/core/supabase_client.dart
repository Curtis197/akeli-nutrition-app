import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logger.dart';

const _supabaseUrl = 'https://njzqcftjzskwcpforwzf.supabase.co';
const _supabaseAnonKey = 'sb_publishable_2WUTLXygeO3s1FTvBdydwA_24zE-a6R';

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
