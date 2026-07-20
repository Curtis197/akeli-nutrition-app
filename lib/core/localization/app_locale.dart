import 'package:flutter/foundation.dart';

/// Represents a dynamically supported language in Akeli
@immutable
class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final String regionGroup;
  final bool isBeta;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.regionGroup = 'Global',
    this.isBeta = false,
  });

  /// Factory from Supabase RPC row / JSON map
  factory AppLanguage.fromJson(Map<String, dynamic> json) {
    return AppLanguage(
      code: json['code'] as String? ?? 'fr',
      name: json['name'] as String? ?? 'French',
      nativeName: json['native_name'] as String? ?? 'Français',
      flag: json['flag_emoji'] as String? ?? '🇫🇷',
      regionGroup: json['region_group'] as String? ?? 'Global',
      isBeta: json['is_beta'] as bool? ?? false,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'native_name': nativeName,
      'flag_emoji': flag,
      'region_group': regionGroup,
      'is_beta': isBeta,
    };
  }

  /// Predefined default languages for initial cold start / fallback
  static const french = AppLanguage(
    code: 'fr',
    name: 'French',
    nativeName: 'Français',
    flag: '🇫🇷',
    regionGroup: 'Global',
  );

  static const english = AppLanguage(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    flag: '🇬🇧',
    regionGroup: 'Global',
  );

  static const spanish = AppLanguage(
    code: 'es',
    name: 'Spanish',
    nativeName: 'Español',
    flag: '🇪🇸',
    regionGroup: 'Global',
  );

  static const portuguese = AppLanguage(
    code: 'pt',
    name: 'Portuguese',
    nativeName: 'Português',
    flag: '🇵🇹',
    regionGroup: 'Global',
  );

  static const wolof = AppLanguage(
    code: 'wo',
    name: 'Wolof',
    nativeName: 'Wolof',
    flag: '🇸🇳',
    regionGroup: 'African',
  );

  static const bambara = AppLanguage(
    code: 'bm',
    name: 'Bambara',
    nativeName: 'Bamanankan',
    flag: '🇲🇱',
    regionGroup: 'African',
  );

  static const lingala = AppLanguage(
    code: 'ln',
    name: 'Lingala',
    nativeName: 'Lingála',
    flag: '🇨🇩',
    regionGroup: 'African',
  );

  static const defaultLanguages = [
    french,
    english,
    spanish,
    portuguese,
    wolof,
    bambara,
    lingala,
  ];

  static AppLanguage fromCode(String code, [List<AppLanguage>? available]) {
    final list = available ?? defaultLanguages;
    return list.firstWhere(
      (lang) => lang.code.toLowerCase() == code.toLowerCase(),
      orElse: () => french,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLanguage && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'AppLanguage($code, $name, $flag)';
}
