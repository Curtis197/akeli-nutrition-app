import 'dart:io';

void main() async {
  final planFile = File('docs/superpowers/plans/2026-07-23-beauty-fix-f-beauty-ui.md');
  final content = await planFile.readAsString();

  const startStr = '''Replace the entire file with (on top of Task 4's version — adds the `AppLocalizations` import, `final l10n = AppLocalizations.of(context);` at the top of `build()`, and threads `l10n` into every private builder via the `context` each already has access to as a `State` member):

  ```dart
''';
  final startIdx = content.indexOf(startStr);
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

  final targetFile = File('lib/features/beauty/beauty_analytics_page.dart');
  await targetFile.writeAsString(newContent);
  print('Replaced beauty_analytics_page.dart');
}
