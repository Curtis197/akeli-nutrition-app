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

  extract('Step 6: Replace hardcoded strings in `lib/features/beauty/beauty_onboarding_page.dart`', 'lib/features/beauty/beauty_onboarding_page.dart', content);
  extract('Step 8: Replace hardcoded strings in `lib/features/beauty/widgets/beauty_checkin_sheet.dart`', 'lib/features/beauty/widgets/beauty_checkin_sheet.dart', content);
  extract('Step 10: Replace hardcoded strings in `lib/features/beauty/widgets/today_beauty_routines_widget.dart`', 'lib/features/beauty/widgets/today_beauty_routines_widget.dart', content);
  extract('Step 12: Replace hardcoded strings in `lib/features/meal_planner/widgets/beauty_planner_view.dart`', 'lib/features/meal_planner/widgets/beauty_planner_view.dart', content);
  extract('Step 14: Replace hardcoded strings in `lib/shared/widgets/color_set_modal.dart`', 'lib/shared/widgets/color_set_modal.dart', content);
}
