import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';
import 'core/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appLogger.i('🚀 Akeli app starting | initializing Hive');
  
  // Initialize Hive for layout caching
  await Hive.initFlutter();
  appLogger.i('✅ Hive initialized | opening boxes');
  
  // Open layout cache box (no need for type adapters for JSON strings)
  await Hive.openBox('layout_cache');
  await Hive.openBox('mode_state');
  appLogger.i('✅ Hive boxes opened | initializing Supabase');
  
  await initializeSupabase();
  appLogger.i('✅ Supabase initialized | launching ProviderScope');

  runApp(
    const ProviderScope(
      child: AkeliApp(),
    ),
  );
}

class AkeliApp extends ConsumerWidget {
  const AkeliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.d('🔄 AkeliApp.build() | evaluating router');
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Akeli',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
