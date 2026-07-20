import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/translation_service.dart';

/// Extension on BuildContext for quick string translation lookup
extension TranslationExtension on BuildContext {
  /// Translate a string key dynamically via Riverpod TranslationService
  String t(String keyName, [Map<String, dynamic>? args]) {
    try {
      final container = ProviderScope.containerOf(this, listen: false);
      final service = container.read(translationServiceProvider);
      return service.t(keyName, args);
    } catch (_) {
      return keyName;
    }
  }
}

/// Extension on WidgetRef for watching translations in Riverpod widgets
extension WidgetRefTranslationExtension on WidgetRef {
  /// Watch translations and re-render widget when locale changes
  String t(String keyName, [Map<String, dynamic>? args]) {
    final service = watch(translationServiceProvider);
    return service.t(keyName, args);
  }
}
