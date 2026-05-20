import 'package:flutter/foundation.dart';
import 'app_locale.dart';
import '../services/translation_service.dart';

/// Provider for managing app locale state
class LocaleProvider extends ChangeNotifier {
  AppLocale _locale = AppLocale.french;
  bool _isLoading = false;

  AppLocale get locale => _locale;
  bool get isLoading => _isLoading;
  String get languageCode => _locale.code;

  /// Initialize with user's preferred language
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _locale = await translationService.loadUserPreferredLanguage();
      await translationService.loadTranslations(_locale);
    } catch (e) {
      debugPrint('Error initializing locale: $e');
      _locale = AppLocale.french;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change the app language
  Future<void> setLocale(AppLocale newLocale) async {
    if (_locale == newLocale) return;

    _isLoading = true;
    notifyListeners();

    try {
      await translationService.loadTranslations(newLocale);
      _locale = newLocale;
    } catch (e) {
      debugPrint('Error changing locale: $e');
      // Keep current locale on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get localized string
  String tr(String keyName) {
    return translationService.translate(keyName, locale: _locale);
  }

  /// Check if RTL (for future Arabic/Hebrew support)
  bool get isRTL => false;
}
