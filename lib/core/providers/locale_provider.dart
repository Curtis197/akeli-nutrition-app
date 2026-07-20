import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logger.dart';
import '../localization/app_locale.dart';
import '../services/translation_service.dart';

final localeProvider = AsyncNotifierProvider<LocaleNotifier, AppLocale>(LocaleNotifier.new);

class LocaleNotifier extends AsyncNotifier<AppLocale> {
  final _logger = appLogger;

  @override
  Future<AppLocale> build() async {
    _logger.provider('LocaleNotifier build()');
    ref.onDispose(() => _logger.provider('LocaleNotifier disposed'));
    final locale = await ref.read(translationServiceProvider).loadUserPreferredLanguage();
    _logger.provider('LocaleNotifier → initial locale: ${locale.code}');
    return locale;
  }

  Future<void> setLocale(AppLocale newLocale) async {
    _logger.provider('LocaleNotifier → setLocale: ${newLocale.code}');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(translationServiceProvider).loadTranslations(newLocale);
      _logger.provider('LocaleNotifier → ${newLocale.code} loaded');
      return newLocale;
    });
  }
}
