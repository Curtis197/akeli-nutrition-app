import 'dart:convert';
import 'dart:io';

void main() async {
  final enKeys = {
    "aiAssistantBeautyTitle": "AI Beauty & Care Assistant",
    "aiAssistantBeautySuggestion1": "What is the best moisturizing routine for 4C hair?",
    "aiAssistantBeautySuggestion2": "How to use raw shea butter against acne and dark spots?",
    "aiAssistantBeautySuggestion3": "Which natural ingredients promote hair growth and stop breakage?",
    "aiAssistantBeautySuggestion4": "Suggest a homemade soothing scalp mask.",
    "nutritionPlanBeautyTitle": "My Care & Routine Program",
    "supportBeautyTitle": "Beauty & Care Support"
  };

  final frKeys = {
    "aiAssistantBeautyTitle": "Assistant Beauté & Soins IA",
    "aiAssistantBeautySuggestion1": "Quelle est la meilleure routine hydratante pour cheveux 4C ?",
    "aiAssistantBeautySuggestion2": "Comment utiliser le beurre de karité brut contre l'acné et les taches ?",
    "aiAssistantBeautySuggestion3": "Quels actifs naturels favorisent la pousse et stoppent la casse ?",
    "aiAssistantBeautySuggestion4": "Propose-moi un masque fait maison apaisant pour cuir chevelu.",
    "nutritionPlanBeautyTitle": "Mon Programme de Soins & Routines",
    "supportBeautyTitle": "Support Beauté & Soins"
  };

  await appendToArb('lib/l10n/app_en.arb', enKeys);
  await appendToArb('lib/l10n/app_fr.arb', frKeys);
  print('done');
}

Future<void> appendToArb(String path, Map<String, String> keys) async {
  final file = File(path);
  final str = await file.readAsString();
  final data = json.decode(str) as Map<String, dynamic>;

  for (final k in keys.keys) {
    data[k] = keys[k];
    if (!k.endsWith("Desc")) {
      data["@" + k] = {"description": "Added for Beauty mode"};
    }
  }

  await file.writeAsString(JsonEncoder.withIndent('  ').convert(data));
}
