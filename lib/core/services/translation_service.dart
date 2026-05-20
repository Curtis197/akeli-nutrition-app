import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_locale.dart';

/// Service to fetch and cache UI translations from Supabase
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Cache: keyName -> languageCode -> value
  final Map<String, Map<String, String>> _translations = {};
  
  bool _isLoading = false;
  String? _currentLanguage;

  bool get isLoading => _isLoading;
  String? get currentLanguage => _currentLanguage;

  /// Load all translations for a specific language
  Future<void> loadTranslations(AppLocale locale) async {
    if (_currentLanguage == locale.code && _translations.isNotEmpty) {
      return; // Already loaded
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Fetch translations from Supabase
      final response = await _supabase.rpc(
        'get_all_ui_translations',
        params: {'p_language_code': locale.code},
      );

      if (response is List) {
        _translations.clear();
        for (var item in response) {
          final keyName = item['key_name'] as String;
          final value = item['value'] as String;
          _translations[keyName] ??= {};
          _translations[keyName]![locale.code] = value;
        }
      }

      _currentLanguage = locale.code;
      
      // Save preference
      await _saveLanguagePreference(locale.code);
    } catch (e) {
      debugPrint('Error loading translations: $e');
      // Fallback to French keys
      _currentLanguage = 'fr';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get translation for a key with fallback chain
  String translate(String keyName, {AppLocale? locale}) {
    final langCode = locale?.code ?? _currentLanguage ?? 'fr';
    
    // Try requested language
    if (_translations[keyName]?.containsKey(langCode) == true) {
      return _translations[keyName]![langCode]!;
    }
    
    // Fallback to French
    if (_translations[keyName]?.containsKey('fr') == true) {
      return _translations[keyName]!['fr']!;
    }
    
    // Last resort: return key itself (for development)
    return keyName;
  }

  /// Convenience method for t() shorthand
  String t(String keyName) => translate(keyName);

  /// Get translation or null if not found
  String? translateOrNull(String keyName, {AppLocale? locale}) {
    final langCode = locale?.code ?? _currentLanguage ?? 'fr';
    return _translations[keyName]?[langCode] ?? _translations[keyName]?['fr'];
  }

  /// Check if a translation exists
  bool hasTranslation(String keyName, {AppLocale? locale}) {
    final langCode = locale?.code ?? _currentLanguage ?? 'fr';
    return _translations[keyName]?.containsKey(langCode) == true ||
           _translations[keyName]?.containsKey('fr') == true;
  }

  /// Clear cache and reload
  Future<void> refreshTranslations(AppLocale locale) async {
    _translations.clear();
    await loadTranslations(locale);
  }

  /// Save language preference to user profile
  Future<void> _saveLanguagePreference(String languageCode) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('user_profile').update({
          'locale': languageCode,
        }).eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  /// Load user's preferred language from profile
  Future<AppLocale> loadUserPreferredLanguage() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('user_profile')
            .select('locale')
            .eq('id', user.id)
            .single();
        
        if (response != null && response['locale'] != null) {
          return AppLocale.fromCode(response['locale'] as String);
        }
      }
    } catch (e) {
      debugPrint('Error loading user language preference: $e');
    }
    
    // Default to French
    return AppLocale.french;
  }

  void notifyListeners() {
    // For use with ChangeNotifier or similar patterns
  }
}

// Global instance for easy access
final translationService = TranslationService();

/// Extension for BuildContext to easily access translations
extension TranslationExtension on BuildContext {
  String tr(String keyName) {
    return translationService.translate(keyName);
  }
}
