import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/logger.dart';
import '../core/localization/app_locale.dart';
import '../core/providers/locale_provider.dart';

final _logger = appLogger;

/// Dynamic Language Dropdown Selector
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
    final languagesAsync = ref.watch(supportedLanguagesProvider);

    final currentLocale = localeAsync.valueOrNull ?? AppLanguage.french;
    final availableLanguages = languagesAsync.valueOrNull ?? AppLanguage.defaultLanguages;

    return DropdownButton<AppLanguage>(
      value: availableLanguages.firstWhere(
        (l) => l.code == currentLocale.code,
        orElse: () => currentLocale,
      ),
      underline: const SizedBox(),
      items: availableLanguages.map((l) {
        return DropdownMenuItem<AppLanguage>(
          value: l,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showFlags) Text(l.flag, style: const TextStyle(fontSize: 20)),
              if (showFlags && showNames) const SizedBox(width: 8),
              if (showNames) Text(l.nativeName),
              if (l.isBeta) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'BETA',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                  ),
                ),
              ],
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
    );
  }
}

/// Dynamic Language ListTile for Settings / Profile Screen
class LocaleListTile extends ConsumerWidget {
  const LocaleListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).valueOrNull ?? AppLanguage.french;

    return ListTile(
      title: const Text('Langue / Language'),
      subtitle: Text('${locale.flag} ${locale.nativeName} (${locale.name})'),
      trailing: const Icon(Icons.language),
      onTap: () => _showLanguageDialog(context, ref),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(localeProvider).valueOrNull ?? AppLanguage.french;
    _logger.userAction('Language dialog opened', screen: 'LocaleListTile');

    showDialog(
      context: context,
      builder: (context) => _LanguagePickerDialog(currentLanguage: current),
    );
  }
}

class _LanguagePickerDialog extends ConsumerWidget {
  final AppLanguage currentLanguage;

  const _LanguagePickerDialog({required this.currentLanguage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languagesAsync = ref.watch(supportedLanguagesProvider);
    final languages = languagesAsync.valueOrNull ?? AppLanguage.defaultLanguages;

    // Group languages by region (Global, African, Asian, etc.)
    final groups = <String, List<AppLanguage>>{};
    for (var l in languages) {
      groups.putIfAbsent(l.regionGroup, () => []).add(l);
    }

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.language, color: Colors.teal),
          SizedBox(width: 8),
          Text('Langue / Language'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: groups.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...entry.value.map((locale) {
                    final isSelected = locale.code == currentLanguage.code;
                    return ListTile(
                      dense: true,
                      leading: Text(locale.flag, style: const TextStyle(fontSize: 22)),
                      title: Text(locale.nativeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(locale.name, style: const TextStyle(fontSize: 12)),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.teal)
                          : (locale.isBeta
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('BETA', style: TextStyle(fontSize: 9, color: Colors.amber.shade900)),
                                )
                              : null),
                      onTap: () {
                        _logger.userAction('Language selected: ${locale.code}', screen: '_LanguagePickerDialog');
                        ref.read(localeProvider.notifier).setLocale(locale);
                        context.pop();
                      },
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

/// Language Button Header Component
class LanguageButton extends ConsumerWidget {
  final VoidCallback? onTap;

  const LanguageButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).valueOrNull ?? AppLanguage.french;

    return IconButton(
      icon: Text(locale.flag, style: const TextStyle(fontSize: 24)),
      tooltip: locale.nativeName,
      onPressed: onTap ?? () => _showLanguageSheet(context, ref),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final current = ref.read(localeProvider).valueOrNull ?? AppLanguage.french;
    _logger.userAction('Language sheet opened', screen: 'LanguageButton');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Language / Langue', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final languagesAsync = ref.watch(supportedLanguagesProvider);
                      final languages = languagesAsync.valueOrNull ?? AppLanguage.defaultLanguages;

                      return Column(
                        children: languages.map((locale) {
                          final isSelected = locale.code == current.code;
                          return ListTile(
                            leading: Text(locale.flag, style: const TextStyle(fontSize: 24)),
                            title: Text(locale.nativeName),
                            subtitle: Text(locale.name),
                            trailing: isSelected ? const Icon(Icons.check, color: Colors.teal) : null,
                            onTap: () {
                              _logger.userAction('Language selected: ${locale.code}', screen: 'LanguageButton');
                              ref.read(localeProvider.notifier).setLocale(locale);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
