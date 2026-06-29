import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logger.dart';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  final _logger = appLogger;

  static const _supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('en', 'US'),
  ];

  static List<Locale> get supportedLocales => _supportedLocales;

  @override
  Locale build() {
    _logger.provider('LocaleNotifier build()');
    ref.onDispose(() => _logger.provider('LocaleNotifier disposed'));
    // Default to English; load persisted preference asynchronously
    _loadPersistedLocale();
    return const Locale('en');
  }

  Locale _parseLocale(String lang) {
    if (lang.contains('-')) {
      final parts = lang.split('-');
      return Locale(parts[0], parts[1]);
    }
    if (lang.contains('_')) {
      final parts = lang.split('_');
      return Locale(parts[0], parts[1]);
    }
    return Locale(lang);
  }

  Future<void> _loadPersistedLocale() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      _logger.db('BEFORE | table: user_profile | op: SELECT | col: locale | userId: ${LogHelper.maskUuid(userId)}');
      final data = await Supabase.instance.client
          .from('user_profile')
          .select('locale')
          .eq('id', userId)
          .maybeSingle();
      _logger.db('AFTER | table: user_profile | rows: ${data == null ? 0 : 1}');

      final lang = data?['locale'] as String?;
      if (lang != null) {
        final locale = _parseLocale(lang);
        if (_supportedLocales.any((l) => l.languageCode == locale.languageCode && l.countryCode == locale.countryCode)) {
          _logger.provider('LocaleNotifier → loaded persisted locale: $lang');
          state = locale;
        }
      }
    } on Exception catch (e, st) {
      _logger.db('ERROR | table: user_profile | locale load | $e', error: e, stackTrace: st);
    }
  }

  Future<void> setLocale(Locale locale) async {
    _logger.provider('LocaleNotifier → setLocale: ${locale.stringValue}');
    state = locale;
    _logger.userAction('Language changed', screen: 'LocaleProvider', metadata: {'lang': locale.stringValue});

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      _logger.db('BEFORE | table: user_profile | op: UPDATE | col: locale | lang: ${locale.stringValue}');
      await Supabase.instance.client
          .from('user_profile')
          .update({'locale': locale.stringValue})
          .eq('id', userId);
      _logger.db('AFTER | table: user_profile | UPDATE locale success');
    } on Exception catch (e, st) {
      _logger.db('ERROR | table: user_profile | locale save | $e', error: e, stackTrace: st);
    }
  }
}

extension LocaleExtension on Locale {
  String get stringValue {
    if (countryCode != null) {
      return '$languageCode-$countryCode';
    }
    return languageCode;
  }

  bool get isUsLocale => languageCode == 'en' && countryCode == 'US';

  String get textLocale => isUsLocale ? 'en' : languageCode;
}
