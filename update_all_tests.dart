import 'dart:io';

void main() async {
  final files = [
    'test/features/beauty/beauty_analytics_page_test.dart',
    'test/features/beauty/beauty_onboarding_page_test.dart',
    'test/features/beauty/widgets/beauty_checkin_sheet_test.dart',
    'test/features/beauty/widgets/today_beauty_routines_widget_test.dart',
    'test/features/meal_planner/widgets/beauty_planner_view_test.dart',
    'test/shared/widgets/color_set_modal_test.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) {
      print('File not found: \$path');
      continue;
    }
    
    var content = await file.readAsString();
    
    // Add import if missing
    if (!content.contains('app_localizations.dart')) {
      content = content.replaceFirst(
        "import 'package:flutter/material.dart';", 
        "import 'package:flutter/material.dart';\nimport 'package:akeli/l10n/app_localizations.dart';"
      );
    }
    
    // Replace MaterialApp(
    final lines = content.split('\n');
    final newLines = <String>[];
    for (int i = 0; i < lines.length; i++) {
      var line = lines[i];
      newLines.add(line);
      if (line.contains('MaterialApp(') && !line.contains('localizationsDelegates')) {
        // find indentation
        final indentMatch = RegExp(r'^(\s*)').firstMatch(line);
        final indent = indentMatch != null ? indentMatch.group(1) : '';
        
        newLines.add('\$indent  localizationsDelegates: AppLocalizations.localizationsDelegates,');
        newLines.add('\$indent  supportedLocales: AppLocalizations.supportedLocales,');
        newLines.add('\$indent  locale: const Locale(\\'fr\\'),');
      }
    }
    
    await file.writeAsString(newLines.join('\n'));
    print('Updated \$path');
  }
}
