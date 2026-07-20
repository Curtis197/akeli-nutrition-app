import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logger.dart';
import '../localization/app_locale.dart';
import '../services/translation_service.dart';

/// Provider for list of active supported languages (Global, African, Asian, etc.)
final supportedLanguagesProvider = FutureProvider<List<AppLanguage>>((ref) async {
  final service = ref.watch(translationServiceProvider);
  return await service.fetchSupportedLanguages();
});

/// Provider for current active AppLanguage
final localeProvider = AsyncNotifierProvider<LocaleNotifier, AppLanguage>(LocaleNotifier.new);

class LocaleNotifier extends AsyncNotifier<AppLanguage> {
  final _logger = appLogger;

  @override
  Future<AppLanguage> build() async {
    _logger.provider('LocaleNotifier build() starting');
    ref.onDispose(() => _logger.provider('LocaleNotifier disposed'));
    final service = ref.read(translationServiceProvider);
    final initialLang = await service.init();
    _logger.provider('LocaleNotifier → active locale: ${initialLang.code}');
    return initialLang;
  }

  Future<void> setLocale(AppLanguage newLanguage) async {
    _logger.provider('LocaleNotifier → setLocale: ${newLanguage.code}');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(translationServiceProvider);
      await service.loadTranslations(newLanguage);
      _logger.provider('LocaleNotifier → ${newLanguage.code} loaded successfully');
      return newLanguage;
    });
  }
}
