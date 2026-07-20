import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';
import '../localization/app_locale.dart';

final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService();
});

class TranslationService {
  final _logger = appLogger;
  final Map<String, Map<String, String>> _translations = {};
  String? _currentLanguage;

  String? get currentLanguage => _currentLanguage;

  Future<void> loadTranslations(AppLocale locale) async {
    if (_currentLanguage == locale.code && _translations.isNotEmpty) return;

    final client = Supabase.instance.client;
    _logger.db('BEFORE rpc | fn: get_all_ui_translations | locale: ${locale.code}');
    try {
      final response = await client.rpc(
        'get_all_ui_translations',
        params: {'p_language_code': locale.code},
      );
      _logger.db('AFTER rpc | fn: get_all_ui_translations | rows: ${(response as List).length}');

      _translations.clear();
      for (var item in response) {
        final keyName = item['key_name'] as String;
        final value = item['value'] as String;
        _translations[keyName] ??= {};
        _translations[keyName]![locale.code] = value;
      }
      _currentLanguage = locale.code;
      await _saveLanguagePreference(locale.code);
    } on PostgrestException catch (e, st) {
      _logger.db('ERROR rpc | fn: get_all_ui_translations | ${e.message}', error: e, stackTrace: st);
      rethrow;
    } catch (e, st) {
      _logger.db('ERROR rpc | fn: get_all_ui_translations | unexpected | $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  String translate(String keyName, {AppLocale? locale}) {
    final langCode = locale?.code ?? _currentLanguage ?? 'fr';
    if (_translations[keyName]?.containsKey(langCode) == true) {
      return _translations[keyName]![langCode]!;
    }
    if (_translations[keyName]?.containsKey('fr') == true) {
      return _translations[keyName]!['fr']!;
    }
    return keyName;
  }

  String t(String keyName) => translate(keyName);

  String? translateOrNull(String keyName, {AppLocale? locale}) {
    final langCode = locale?.code ?? _currentLanguage ?? 'fr';
    return _translations[keyName]?[langCode] ?? _translations[keyName]?['fr'];
  }

  bool hasTranslation(String keyName, {AppLocale? locale}) {
    final langCode = locale?.code ?? _currentLanguage ?? 'fr';
    return _translations[keyName]?.containsKey(langCode) == true ||
        _translations[keyName]?.containsKey('fr') == true;
  }

  Future<void> refreshTranslations(AppLocale locale) async {
    _translations.clear();
    await loadTranslations(locale);
  }

  Future<void> _saveLanguagePreference(String languageCode) async {
    final client = Supabase.instance.client;
    try {
      final user = client.auth.currentUser;
      if (user != null) {
        _logger.db('BEFORE | table: user_profile | op: UPDATE locale | userId: ${user.id}');
        await client.from('user_profile').update({'locale': languageCode}).eq('id', user.id);
        _logger.db('AFTER | table: user_profile | locale updated');
      }
    } on PostgrestException catch (e, st) {
      _logger.db('ERROR | table: user_profile | locale save | ${e.code}', error: e, stackTrace: st);
    }
  }

  Future<AppLocale> loadUserPreferredLanguage() async {
    final client = Supabase.instance.client;
    try {
      final user = client.auth.currentUser;
      if (user != null) {
        _logger.db('BEFORE | table: user_profile | op: SELECT locale | userId: ${user.id}');
        final response = await client
            .from('user_profile')
            .select('locale')
            .eq('id', user.id)
            .single();
        _logger.db('AFTER | table: user_profile | rows: 1');
        if (response['locale'] != null) {
          return AppLocale.fromCode(response['locale'] as String);
        }
      }
    } on PostgrestException catch (e, st) {
      _logger.db('ERROR | table: user_profile | loadUserPreferredLanguage | ${e.code}', error: e, stackTrace: st);
    }
    return AppLocale.french;
  }
}
