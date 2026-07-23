import 'dart:io';

void main() async {
  final planFile = File('docs/superpowers/plans/2026-07-23-beauty-fix-f-beauty-ui.md');
  final content = await planFile.readAsString();

  const startStr = '''Replace the entire file with:

  ```dart
''';
  
  // Find start
  const step5Str = '- [ ] **Step 5: Replace hardcoded strings in `lib/features/beauty/widgets/beauty_checkin_sheet.dart`.**';
  final step5Idx = content.indexOf(step5Str);
  if (step5Idx == -1) {
    print('Could not find step 5');
    return;
  }
  
  final startIdx = content.indexOf(startStr, step5Idx);
  if (startIdx == -1) {
    print('Could not find start str');
    return;
  }
  
  final blockStart = startIdx + startStr.length;
  // Just find the next '  ```' block end
  final blockEnd = content.indexOf('\n  ```\n', blockStart);
  if (blockEnd == -1) {
    print('Could not find end str');
    return;
  }
  
  var newContent = content.substring(blockStart, blockEnd);
  newContent = newContent.split('\n').map((line) {
    if (line.startsWith('  ')) {
      return line.substring(2);
    }
    return line;
  }).join('\n');

  final targetFile = File('lib/features/beauty/widgets/beauty_checkin_sheet.dart');
  await targetFile.writeAsString(newContent);
  print('Replaced beauty_checkin_sheet.dart');
}
