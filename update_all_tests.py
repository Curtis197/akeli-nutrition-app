import os
import re

files = [
    'test/features/beauty/beauty_analytics_page_test.dart',
    'test/features/beauty/beauty_onboarding_page_test.dart',
    'test/features/beauty/widgets/beauty_checkin_sheet_test.dart',
    'test/features/beauty/widgets/today_beauty_routines_widget_test.dart',
    'test/features/meal_planner/widgets/beauty_planner_view_test.dart',
    'test/shared/widgets/color_set_modal_test.dart',
]

for path in files:
    if not os.path.exists(path):
        print(f'File not found: {path}')
        continue
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Add import if missing
    if 'app_localizations.dart' not in content:
        content = content.replace(
            "import 'package:flutter/material.dart';", 
            "import 'package:flutter/material.dart';\nimport 'package:akeli/l10n/app_localizations.dart';"
        )
        
    lines = content.split('\n')
    new_lines = []
    
    for line in lines:
        new_lines.append(line)
        if 'MaterialApp(' in line and 'localizationsDelegates' not in line:
            match = re.match(r'^(\s*)', line)
            indent = match.group(1) if match else ''
            new_lines.append(f'{indent}  localizationsDelegates: AppLocalizations.localizationsDelegates,')
            new_lines.append(f'{indent}  supportedLocales: AppLocalizations.supportedLocales,')
            new_lines.append(f"{indent}  locale: const Locale('fr'),")
            
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_lines))
        
    print(f'Updated {path}')
