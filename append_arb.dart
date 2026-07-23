import 'dart:io';

void main() async {
  final planFile = File('docs/superpowers/plans/2026-07-23-beauty-fix-f-beauty-ui.md');
  final content = await planFile.readAsString();

  // Find EN block
  const enStartStr = 'Change the line `"@onboardingValidationAgeMax": {}` to end with a comma, then insert the entire block below immediately before the final `}`:\n\n  ```json\n';
  final enStartIdx = content.indexOf(enStartStr);
  if (enStartIdx == -1) {
    print('Could not find EN block');
    return;
  }
  final enBlockStart = enStartIdx + enStartStr.length;
  final enBlockEnd = content.indexOf('  ```', enBlockStart);
  final enBlock = content.substring(enBlockStart, enBlockEnd);

  final enArbFile = File('lib/l10n/app_en.arb');
  final enArb = await enArbFile.readAsString();
  final enArbNew = enArb.replaceAll('"@onboardingValidationAgeMax": {}', enBlock);
  await enArbFile.writeAsString(enArbNew);
  print('Updated app_en.arb');

  // Find FR block
  const frStartStr = 'Same mechanic: change the final `"@onboardingValidationAgeMax": {}` to end with a comma and insert this block (same keys, same order, French values — for `beautyCheckin*` this is a **translation** of the English text added in Step 1, per the finding, since this file was originally hardcoded in English while every sibling Beauty screen was hardcoded in French):\n\n  ```json\n';
  var frStartIdx = content.indexOf(frStartStr);
  if (frStartIdx == -1) {
    print('Could not find FR block exactly, using fallback search.');
    // Let's use RegExp for FR block
    final frRegex = RegExp(r'change the final `"@onboardingValidationAgeMax": \{\}` to end with a comma and insert this block.*?:\s*```json\n(.*?)\n\s*```', dotAll: true);
    final frMatch = frRegex.firstMatch(content);
    if (frMatch != null) {
      final frBlock = frMatch.group(1)!;
      final frArbFile = File('lib/l10n/app_fr.arb');
      final frArb = await frArbFile.readAsString();
      final frArbNew = frArb.replaceAll('"@onboardingValidationAgeMax": {}', frBlock);
      await frArbFile.writeAsString(frArbNew);
      print('Updated app_fr.arb via regex fallback');
    } else {
      print('Could not find FR block with fallback');
    }
  } else {
    final frBlockStart = frStartIdx + frStartStr.length;
    final frBlockEnd = content.indexOf('  ```', frBlockStart);
    final frBlock = content.substring(frBlockStart, frBlockEnd);

    final frArbFile = File('lib/l10n/app_fr.arb');
    final frArb = await frArbFile.readAsString();
    final frArbNew = frArb.replaceAll('"@onboardingValidationAgeMax": {}', frBlock);
    await frArbFile.writeAsString(frArbNew);
    print('Updated app_fr.arb');
  }
}
