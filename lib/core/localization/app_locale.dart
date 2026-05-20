import 'package:flutter/material.dart';

/// Supported languages for Akeli app
enum AppLocale {
  french('fr', 'Français', '🇫🇷'),
  english('en', 'English', '🇬🇧'),
  spanish('es', 'Español', '🇪🇸'),
  portuguese('pt', 'Português', '🇵🇹'),
  wolof('wo', 'Wolof', '🇸🇳'),
  bambara('bm', 'Bambara', '🇲🇱'),
  lingala('ln', 'Lingala', '🇨🇩');

  final String code;
  final String name;
  final String flag;

  const AppLocale(this.code, this.name, this.flag);

  static AppLocale fromCode(String code) {
    return AppLocale.values.firstWhere(
      (locale) => locale.code == code,
      orElse: () => AppLocale.french,
    );
  }

  static List<AppLocale> get supportedLocales => [
        AppLocale.french,
        AppLocale.english,
        AppLocale.spanish,
        AppLocale.portuguese,
        // African languages - future support
        // AppLocale.wolof,
        // AppLocale.bambara,
        // AppLocale.lingala,
      ];
}
