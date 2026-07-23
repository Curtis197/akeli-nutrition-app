import 'dart:io';

void extract(String stepPrefix, String targetPath, String content) {
  final stepIdx = content.indexOf(stepPrefix);
  if (stepIdx == -1) {
    print('Could not find step prefix: \$stepPrefix');
    return;
  }

  // Look for the code block after the step
  const startStr = '```dart\n';
  final startIdx = content.indexOf(startStr, stepIdx);
  if (startIdx == -1) {
    print('Could not find start str ```dart');
    return;
  }

  final blockStart = startIdx + startStr.length;
  final blockEnd = content.indexOf('\n  ```\n', blockStart);
  final blockEnd2 = content.indexOf('\n```\n', blockStart);
  
  int end = -1;
  if (blockEnd != -1 && blockEnd2 != -1) {
    end = blockEnd < blockEnd2 ? blockEnd : blockEnd2;
  } else if (blockEnd != -1) {
    end = blockEnd;
  } else if (blockEnd2 != -1) {
    end = blockEnd2;
  }

  if (end == -1) {
    print('Could not find end str');
    return;
  }

  var newContent = content.substring(blockStart, end);
  newContent = newContent.split('\n').map((line) {
    if (line.startsWith('  ')) {
      return line.substring(2);
    }
    return line;
  }).join('\n');

  final targetFile = File(targetPath);
  targetFile.writeAsStringSync(newContent);
  print('Replaced \$targetPath');
}

void main() async {
  final planFile = File('docs/superpowers/plans/2026-07-23-beauty-fix-f-beauty-ui.md');
  final content = await planFile.readAsString();

  extract('Step 5: Update `test/features/beauty/beauty_analytics_page_test.dart`', 'test/features/beauty/beauty_analytics_page_test.dart', content);
  extract('Step 7: Update `test/features/beauty/beauty_onboarding_page_test.dart`', 'test/features/beauty/beauty_onboarding_page_test.dart', content);
  extract('Step 9: Update `test/features/beauty/widgets/beauty_checkin_sheet_test.dart`', 'test/features/beauty/widgets/beauty_checkin_sheet_test.dart', content);
  extract('Step 11: Update `test/features/beauty/widgets/today_beauty_routines_widget_test.dart`', 'test/features/beauty/widgets/today_beauty_routines_widget_test.dart', content);
  extract('Step 13: Update `test/features/meal_planner/widgets/beauty_planner_view_test.dart`', 'test/features/meal_planner/widgets/beauty_planner_view_test.dart', content);
  
  // Step 15 updates two files, I should check how they are laid out.
  // Actually, I'll extract them individually if needed or do it manually.
}
