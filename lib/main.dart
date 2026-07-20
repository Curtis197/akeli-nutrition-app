import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'core/locale_provider.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/google_sign_in_client.dart';
import 'core/theme.dart';
import 'core/logger.dart';
import 'core/notification_handler.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appLogger.i('🚀 Akeli app starting | initializing Hive, Supabase & Firebase');

  try {
    await Hive.initFlutter();
    await Hive.openBox('layout_cache');
    await Hive.openBox('mode_state');
    appLogger.i('✅ Hive initialized');
  } catch (e) {
    appLogger.e('⚠️ Hive init failed: $e');
  }

  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('en_US', null);

  RemoteMessage? initialMessage;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    appLogger.i('✅ Firebase initialized');

    // Background handler must be registered before runApp
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Terminated state — capture before runApp; deliver after first frame
    initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      appLogger.i('FCM terminated-state message | type: ${initialMessage.data['type']}');
    }

    // Foreground: show in-app SnackBar
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      appLogger.i('FCM Foreground Message received: ${message.notification?.title}');

      final title = message.notification?.title ??
          (rootScaffoldMessengerKey.currentContext != null
              ? AppLocalizations.of(rootScaffoldMessengerKey.currentContext!).notificationDefaultTitle
              : 'Nouvelle notification');
      final body = message.notification?.body ?? '';

      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (body.isNotEmpty) Text(body),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: rootScaffoldMessengerKey.currentContext != null
                ? AppLocalizations.of(rootScaffoldMessengerKey.currentContext!).notificationSeeLabel
                : 'View',
            onPressed: () {
              rootScaffoldMessengerKey.currentContext?.push(AkeliRoutes.notifications);
            },
          ),
        ),
      );
    });
  } catch (e) {
    appLogger.e('⚠️ Firebase init failed (Please run flutterfire configure): $e');
  }

  await initializeSupabase();
  appLogger.i('✅ Supabase initialized | launching ProviderScope');

  try {
    await initializeGoogleSignIn();
  } catch (e, st) {
    appLogger.e('⚠️ GoogleSignIn init failed', error: e, stackTrace: st);
  }

  // Single ProviderContainer shared with the widget tree so the router instance
  // used by notification tap handlers is identical to the one used by GoRouter.
  final container = ProviderContainer();
  final router = container.read(routerProvider);

  // Terminated state: deliver tap after first frame so the navigator is mounted
  if (initialMessage != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleNotificationTap(initialMessage!, router);
    });
  }

  // Background state: app resumed by tapping a notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    appLogger.i('FCM background tap | type: ${message.data['type']}');
    handleNotificationTap(message, router);
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AkeliApp(),
    ),
  );
}

class AkeliApp extends ConsumerWidget {
  const AkeliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.d('🔄 AkeliApp.build() | evaluating router');
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'Akeli',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: LocaleNotifier.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
    );
  }
}
