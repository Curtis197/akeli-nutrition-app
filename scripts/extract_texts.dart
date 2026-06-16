import 'dart:io';

void main() {
  final directory = Directory('lib');
  final outputFile = File('docs/app_texts_for_translation.md');
  
  if (!outputFile.parent.existsSync()) {
    outputFile.parent.createSync(recursive: true);
  }

  final buffer = StringBuffer();
  buffer.writeln('# Extracted App Texts for Translation');
  buffer.writeln('This file contains user-facing text extracted from the native Flutter components for localization.');
  buffer.writeln();

  // We look for common UI text properties.
  // We use regex to match both single (') and double (") quotes.
  // Group 1: The quote character
  // Group 2: The actual string content
  const stringPattern = r'''((?:(?!\1)[^\\]|\\.)*)''';
  
  final patterns = [
    r'''Text\(\s*(['"])''' + stringPattern + r'''\1''',
    r'''text:\s*(['"])''' + stringPattern + r'''\1''',
    r'''hintText:\s*(['"])''' + stringPattern + r'''\1''',
    r'''labelText:\s*(['"])''' + stringPattern + r'''\1''',
    r'''tooltip:\s*(['"])''' + stringPattern + r'''\1''',
    r'''label:\s*(['"])''' + stringPattern + r'''\1''',
    r'''title:\s*Text\(\s*(['"])''' + stringPattern + r'''\1''',
    r'''AkeliButton\(\s*text:\s*(['"])''' + stringPattern + r'''\1''', // Specific custom widgets
  ];

  final regexes = patterns.map((p) => RegExp(p)).toList();

  int totalStrings = 0;

  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // Skip the legacy flutterflow codebase
      if (entity.path.contains('flutterflow_application')) continue;
      // Skip generated files
      if (entity.path.endsWith('.g.dart') || entity.path.endsWith('.freezed.dart')) continue;

      final content = entity.readAsStringSync();
      
      final fileStrings = <String, Set<int>>{}; // text to line numbers

      for (final regex in regexes) {
        final matches = regex.allMatches(content);
        for (final match in matches) {
          if (match.groupCount >= 2) {
            final matchedText = match.group(2);
            if (matchedText != null && matchedText.trim().isNotEmpty) {
              // Filter out pure variable interpolations with no other text
              if (matchedText.startsWith(r'$') && !matchedText.contains(' ')) continue;
              // Skip simple icons or numbers or boolean representations if they accidentally match
              if (matchedText == 'true' || matchedText == 'false') continue;
              
              // Find line number by counting newlines before the match
              final charOffset = match.start;
              final lineNum = content.substring(0, charOffset).split('\n').length;
              
              fileStrings.putIfAbsent(matchedText, () => {}).add(lineNum);
            }
          }
        }
      }

      if (fileStrings.isNotEmpty) {
        // Standardize file paths for Windows (\ to /)
        final displayPath = entity.path.replaceAll('\\', '/');
        buffer.writeln('## File: `$displayPath`');
        for (final entry in fileStrings.entries) {
          final linesStr = entry.value.toList()..sort();
          final linesFormatted = linesStr.map((l) => 'L$l').join(', ');
          buffer.writeln('- [$linesFormatted] `${entry.key.replaceAll('\n', r'\n')}`');
          totalStrings++;
        }
        buffer.writeln();
      }
    }
  }

  outputFile.writeAsStringSync(buffer.toString());
  stdout.writeln('Successfully extracted $totalStrings text instances to docs/app_texts_for_translation.md');
}
