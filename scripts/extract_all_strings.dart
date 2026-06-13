import 'dart:io';

void main() {
  final directory = Directory('lib');
  final outputFile = File('docs/missed_texts_check.md');
  
  if (!outputFile.parent.existsSync()) {
    outputFile.parent.createSync(recursive: true);
  }

  final buffer = StringBuffer();
  buffer.writeln('# Missed Texts Check');
  buffer.writeln('This file contains potentially user-facing strings that might have been missed by the first extraction script.');
  buffer.writeln();

  // Pattern to match any string literal
  final stringPattern = RegExp(r'''(['"])((?:(?!\1)[^\\]|\\.)*)\1''');
  
  // Previous patterns used to extract strings, we will ignore strings that match these contexts
  final previousContexts = [
    RegExp(r'''Text\(\s*(['"])((?:(?!\1)[^\\]|\\.)*)\1'''),
    RegExp(r'''text:\s*(['"])((?:(?!\1)[^\\]|\\.)*)\1'''),
    RegExp(r'''hintText:\s*(['"])((?:(?!\1)[^\\]|\\.)*)\1'''),
    RegExp(r'''labelText:\s*(['"])((?:(?!\1)[^\\]|\\.)*)\1'''),
    RegExp(r'''tooltip:\s*(['"])((?:(?!\1)[^\\]|\\.)*)\1'''),
    RegExp(r'''label:\s*(['"])((?:(?!\1)[^\\]|\\.)*)\1'''),
    RegExp(r'''title:\s*Text\(\s*(['"])((?:(?!\1)[^\\]|\\.)*)\1'''),
    RegExp(r'''AkeliButton\(\s*text:\s*(['"])((?:(?!\1)[^\\]|\\.)*)\1'''),
  ];

  int totalFound = 0;

  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      if (entity.path.contains('flutterflow_application')) continue;
      if (entity.path.endsWith('.g.dart') || entity.path.endsWith('.freezed.dart')) continue;

      final content = entity.readAsStringSync();
      
      // Get all strings captured by previous contexts to exclude them
      final previouslyCaptured = <String>{};
      for (final regex in previousContexts) {
        for (final match in regex.allMatches(content)) {
          if (match.groupCount >= 2 && match.group(2) != null) {
            previouslyCaptured.add(match.group(2)!);
          }
        }
      }

      final fileStrings = <String, Set<int>>{};

      final matches = stringPattern.allMatches(content);
      for (final match in matches) {
        final matchedText = match.group(2);
        if (matchedText != null && matchedText.trim().isNotEmpty) {
          if (previouslyCaptured.contains(matchedText)) continue;
          
          // Filter out strings that are likely not user-facing
          if (!matchedText.contains(' ')) continue; // Must have a space to be a sentence/phrase
          if (matchedText.contains('/')) continue; // Likely a path or URL
          if (matchedText.contains('.png') || matchedText.contains('.svg')) continue;
          if (matchedText.startsWith(r'$') && matchedText.split(' ').length == 1) continue;
          if (RegExp(r'^[a-z_]+$').hasMatch(matchedText)) continue; // snake_case
          if (RegExp(r'^[a-z]+[A-Z][a-zA-Z]*$').hasMatch(matchedText)) continue; // camelCase
          if (matchedText.toUpperCase() == matchedText && matchedText.contains('_')) continue; // UPPER_SNAKE
          if (matchedText.contains('SELECT ') || matchedText.contains('FROM ')) continue; // SQL
          
          // Must contain at least one letter
          if (!RegExp(r'[a-zA-Z]').hasMatch(matchedText)) continue;

          final charOffset = match.start;
          final lineNum = content.substring(0, charOffset).split('\n').length;
          
          fileStrings.putIfAbsent(matchedText, () => {}).add(lineNum);
        }
      }

      if (fileStrings.isNotEmpty) {
        final displayPath = entity.path.replaceAll('\\', '/');
        buffer.writeln('## File: `$displayPath`');
        for (final entry in fileStrings.entries) {
          final linesStr = entry.value.toList()..sort();
          final linesFormatted = linesStr.map((l) => 'L$l').join(', ');
          buffer.writeln('- [$linesFormatted] `${entry.key.replaceAll('\n', r'\n')}`');
          totalFound++;
        }
        buffer.writeln();
      }
    }
  }

  outputFile.writeAsStringSync(buffer.toString());
  print('Found $totalFound potentially missed strings.');
}
