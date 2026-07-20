import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/logger.dart';
import '../localization/app_locale.dart';

final _logger = appLogger;

/// Local offline cache service for dynamic translations and language preferences
class LocaleCacheService {
  static const _activeLanguageKey = 'akeli_active_language_code';
  static const _cachedTranslationsKeyPrefix = 'akeli_translations_';
  static const _cachedLanguagesKey = 'akeli_supported_languages';

  /// Save active selected language code
  Future<void> saveActiveLanguageCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeLanguageKey, code);
    } catch (e) {
      _logger.e('LocaleCacheService: Failed to save active language code: $e');
    }
  }

  /// Load cached active language code
  Future<String?> getActiveLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeLanguageKey);
    } catch (e) {
      _logger.e('LocaleCacheService: Failed to load active language code: $e');
      return null;
    }
  }

  /// Save translations dictionary for a language code
  Future<void> saveTranslations(String code, Map<String, String> translations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(translations);
      await prefs.setString('$_cachedTranslationsKeyPrefix$code', encoded);
    } catch (e) {
      _logger.e('LocaleCacheService: Failed to cache translations for $code: $e');
    }
  }

  /// Load cached translations dictionary for a language code
  Future<Map<String, String>> getTranslations(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('$_cachedTranslationsKeyPrefix$code');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (e) {
      _logger.e('LocaleCacheService: Failed to load cached translations for $code: $e');
    }
    return {};
  }

  /// Cache list of supported languages from Supabase
  Future<void> saveSupportedLanguages(List<AppLanguage> languages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = languages.map((l) => l.toJson()).toList();
      await prefs.setString(_cachedLanguagesKey, jsonEncode(list));
    } catch (e) {
      _logger.e('LocaleCacheService: Failed to cache supported languages: $e');
    }
  }

  /// Load cached supported languages
  Future<List<AppLanguage>> getSupportedLanguages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cachedLanguagesKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        return decoded.map((item) => AppLanguage.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      _logger.e('LocaleCacheService: Failed to load cached supported languages: $e');
    }
    return AppLanguage.defaultLanguages;
  }
}
