import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/locale_provider.dart';
import '../core/localization/app_locale.dart';

/// Language selector widget with dropdown
class LocaleSelector extends StatelessWidget {
  final bool showFlags;
  final bool showNames;

  const LocaleSelector({
    super.key,
    this.showFlags = true,
    this.showNames = true,
  });

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return DropdownButton<AppLocale>(
      value: localeProvider.locale,
      underline: const SizedBox(),
      items: AppLocale.supportedLocales.map((locale) {
        return DropdownMenuItem<AppLocale>(
          value: locale,
          child: Row(
            children: [
              if (showFlags) Text(locale.flag, style: const TextStyle(fontSize: 20)),
              if (showFlags && showNames) const SizedBox(width: 8),
              if (showNames) Text(locale.name),
            ],
          ),
        );
      }).toList(),
      onChanged: localeProvider.isLoading ? null : (value) {
        if (value != null) {
          localeProvider.setLocale(value);
        }
      },
    );
  }
}

/// Language selector as a list tile for settings screens
class LocaleListTile extends StatelessWidget {
  const LocaleListTile({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return ListTile(
      title: Text(localeProvider.tr('profile.language')),
      subtitle: Text(
        '${localeProvider.locale.flag} ${localeProvider.locale.name}',
      ),
      trailing: const Icon(Icons.language),
      onTap: () => _showLanguageDialog(context),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localeProvider.tr('settings.language')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppLocale.supportedLocales.map((locale) {
              final isSelected = locale == localeProvider.locale;
              return RadioListTile<AppLocale>(
                title: Row(
                  children: [
                    Text(locale.flag, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(locale.name),
                  ],
                ),
                value: locale,
                groupValue: localeProvider.locale,
                onChanged: localeProvider.isLoading ? null : (value) {
                  if (value != null) {
                    localeProvider.setLocale(value);
                    Navigator.pop(context);
                  }
                },
                selected: isSelected,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localeProvider.tr('common.close')),
          ),
        ],
      ),
    );
  }
}

/// Simple language selector button
class LanguageButton extends StatelessWidget {
  final VoidCallback? onTap;

  const LanguageButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return IconButton(
      icon: Text(localeProvider.locale.flag, style: const TextStyle(fontSize: 24)),
      tooltip: localeProvider.locale.name,
      onPressed: onTap ?? () => _showLanguageDialog(context),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                localeProvider.tr('settings.language'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...AppLocale.supportedLocales.map((locale) {
              final isSelected = locale == localeProvider.locale;
              return ListTile(
                leading: Text(locale.flag, style: const TextStyle(fontSize: 24)),
                title: Text(locale.name),
                trailing: isSelected
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  localeProvider.setLocale(locale);
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
