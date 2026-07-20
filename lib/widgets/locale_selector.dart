import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/logger.dart';
import '../core/localization/app_locale.dart';
import '../core/providers/locale_provider.dart';

final _logger = appLogger;

class LocaleSelector extends ConsumerWidget {
  final bool showFlags;
  final bool showNames;

  const LocaleSelector({
    super.key,
    this.showFlags = true,
    this.showNames = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeProvider);

    return localeAsync.when(
      loading: () => const SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const Icon(Icons.language),
      data: (locale) => DropdownButton<AppLocale>(
        value: locale,
        underline: const SizedBox(),
        items: AppLocale.supportedLocales.map((l) {
          return DropdownMenuItem<AppLocale>(
            value: l,
            child: Row(
              children: [
                if (showFlags) Text(l.flag, style: const TextStyle(fontSize: 20)),
                if (showFlags && showNames) const SizedBox(width: 8),
                if (showNames) Text(l.name),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            _logger.userAction('Language selected: ${value.code}', screen: 'LocaleSelector');
            ref.read(localeProvider.notifier).setLocale(value);
          }
        },
      ),
    );
  }
}

class LocaleListTile extends ConsumerWidget {
  const LocaleListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).valueOrNull ?? AppLocale.french;

    return ListTile(
      title: const Text('Langue'),
      subtitle: Text('${locale.flag} ${locale.name}'),
      trailing: const Icon(Icons.language),
      onTap: () => _showLanguageDialog(context, ref),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(localeProvider).valueOrNull ?? AppLocale.french;
    _logger.userAction('Language dialog opened', screen: 'LocaleListTile');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Langue'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppLocale.supportedLocales.map((locale) {
              final isSelected = locale == current;
              return RadioListTile<AppLocale>(
                title: Row(
                  children: [
                    Text(locale.flag, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(locale.name),
                  ],
                ),
                value: locale,
                groupValue: current,
                onChanged: (value) {
                  if (value != null) {
                    _logger.userAction('Language selected: ${value.code}', screen: 'LocaleListTile');
                    ref.read(localeProvider.notifier).setLocale(value);
                    context.pop();
                  }
                },
                selected: isSelected,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class LanguageButton extends ConsumerWidget {
  final VoidCallback? onTap;

  const LanguageButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).valueOrNull ?? AppLocale.french;

    return IconButton(
      icon: Text(locale.flag, style: const TextStyle(fontSize: 24)),
      tooltip: locale.name,
      onPressed: onTap ?? () => _showLanguageSheet(context, ref),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final current = ref.read(localeProvider).valueOrNull ?? AppLocale.french;
    _logger.userAction('Language sheet opened', screen: 'LanguageButton');

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Langue', style: Theme.of(context).textTheme.titleLarge),
            ),
            ...AppLocale.supportedLocales.map((locale) {
              final isSelected = locale == current;
              return ListTile(
                leading: Text(locale.flag, style: const TextStyle(fontSize: 24)),
                title: Text(locale.name),
                trailing: isSelected
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  _logger.userAction('Language selected: ${locale.code}', screen: 'LanguageButton');
                  ref.read(localeProvider.notifier).setLocale(locale);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
