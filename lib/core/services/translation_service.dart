import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';
import '../localization/app_locale.dart';
import 'locale_cache_service.dart';

final localeCacheServiceProvider = Provider<LocaleCacheService>((ref) {
  return LocaleCacheService();
});

final translationServiceProvider = Provider<TranslationService>((ref) {
  final cacheService = ref.watch(localeCacheServiceProvider);
  return TranslationService(cacheService);
});

class TranslationService {
  final LocaleCacheService _cacheService;
  final _logger = appLogger;
  final Map<String, String> _dictionary = {};
  String _activeLanguageCode = 'fr';
  List<AppLanguage> _supportedLanguages = AppLanguage.defaultLanguages;

  TranslationService(this._cacheService);

  String get activeLanguageCode => _activeLanguageCode;
  List<AppLanguage> get supportedLanguages => _supportedLanguages;

  /// Initialize service on app cold start (instant offline cache load + async Supabase sync)
  Future<AppLanguage> init() async {
    _logger.provider('TranslationService init() starting');

    // 1. Load cached supported languages
    final cachedLangs = await _cacheService.getSupportedLanguages();
    if (cachedLangs.isNotEmpty) {
      _supportedLanguages = cachedLangs;
    }

    // 2. Load active language code preference
    final cachedCode = await _cacheService.getActiveLanguageCode();
    if (cachedCode != null && cachedCode.isNotEmpty) {
      _activeLanguageCode = cachedCode;
    } else {
      _activeLanguageCode = await _loadUserPreferredLanguageFromSupabase() ?? 'fr';
    }

    // 3. Load dictionary from local cache instantly
    final cachedDict = await _cacheService.getTranslations(_activeLanguageCode);
    if (cachedDict.isNotEmpty) {
      _dictionary.clear();
      _dictionary.addAll(cachedDict);
      _logger.provider('TranslationService → loaded ${cachedDict.length} cached strings for $_activeLanguageCode');
    }

    // 4. Silently refresh supported languages & active dictionary from Supabase
    _refreshLanguagesAndTranslationsAsync(_activeLanguageCode);

    return AppLanguage.fromCode(_activeLanguageCode, _supportedLanguages);
  }

  /// Fetch active supported languages from Supabase
  Future<List<AppLanguage>> fetchSupportedLanguages() async {
    final client = Supabase.instance.client;
    _logger.db('BEFORE rpc | fn: get_supported_languages');
    try {
      final response = await client.rpc('get_supported_languages');
      final list = (response as List<dynamic>)
          .map((item) => AppLanguage.fromJson(item as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) {
        _supportedLanguages = list;
        await _cacheService.saveSupportedLanguages(list);
        _logger.db('AFTER rpc | fn: get_supported_languages | count: ${list.length}');
      }
      return _supportedLanguages;
    } catch (e) {
      _logger.db('ERROR rpc | fn: get_supported_languages | fallback to local: $e');
      return _supportedLanguages;
    }
  }

  /// Load translations for a specific language
  Future<void> loadTranslations(AppLanguage language) async {
    _activeLanguageCode = language.code;
    await _cacheService.saveActiveLanguageCode(language.code);

    // Load local cache first if available
    final cached = await _cacheService.getTranslations(language.code);
    if (cached.isNotEmpty) {
      _dictionary.clear();
      _dictionary.addAll(cached);
    }

    // Fetch latest from Supabase RPC
    await _fetchAndCacheUiTranslations(language.code);
    await _saveLanguagePreferenceToSupabase(language.code);
  }

  /// Primary translation function with optional argument interpolation `{argKey}`
  String t(String keyName, [Map<String, dynamic>? args]) {
    String value = _dictionary[keyName] ?? keyName;
    if (args != null && args.isNotEmpty) {
      args.forEach((k, v) {
        value = value.replaceAll('{$k}', v.toString());
      });
    }
    return value;
  }

  /// Returns translation or null if missing
  String? translateOrNull(String keyName) {
    return _dictionary[keyName];
  }

  /// Check if translation exists in active dictionary
  bool hasTranslation(String keyName) {
    return _dictionary.containsKey(keyName);
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPERS
  // ---------------------------------------------------------------------------

  Future<void> _fetchAndCacheUiTranslations(String langCode) async {
    final client = Supabase.instance.client;
    _logger.db('BEFORE rpc | fn: get_all_ui_translations | lang: $langCode');
    try {
      final response = await client.rpc(
        'get_all_ui_translations',
        params: {'p_language_code': langCode},
      );
      final rows = response as List<dynamic>;
      _logger.db('AFTER rpc | fn: get_all_ui_translations | count: ${rows.length}');

      final newDict = <String, String>{};
      for (var item in rows) {
        final k = item['key_name'] as String;
        final v = item['value'] as String;
        newDict[k] = v;
      }

      if (newDict.isNotEmpty) {
        _dictionary.clear();
        _dictionary.addAll(newDict);
        await _cacheService.saveTranslations(langCode, newDict);
      }
    } catch (e, st) {
      _logger.db('ERROR rpc | fn: get_all_ui_translations | $e', error: e, stackTrace: st);
    }
  }

  Future<void> _refreshLanguagesAndTranslationsAsync(String langCode) async {
    try {
      await fetchSupportedLanguages();
      await _fetchAndCacheUiTranslations(langCode);
    } catch (e) {
      _logger.e('Async translation refresh error: $e');
    }
  }

  Future<void> _saveLanguagePreferenceToSupabase(String languageCode) async {
    final client = Supabase.instance.client;
    try {
      final user = client.auth.currentUser;
      if (user != null) {
        await client.from('user_profile').update({'locale': languageCode}).eq('id', user.id);
        _logger.db('AFTER | table: user_profile | updated locale to $languageCode');
      }
    } catch (e) {
      _logger.db('ERROR | table: user_profile | update locale failed: $e');
    }
  }

  Future<String?> _loadUserPreferredLanguageFromSupabase() async {
    final client = Supabase.instance.client;
    try {
      final user = client.auth.currentUser;
      if (user != null) {
        final response = await client
            .from('user_profile')
            .select('locale')
            .eq('id', user.id)
            .maybeSingle();
        if (response != null && response['locale'] != null) {
          return response['locale'] as String;
        }
      }
    } catch (e) {
      _logger.db('ERROR | table: user_profile | fetch locale failed: $e');
    }
    return null;
  }
}
