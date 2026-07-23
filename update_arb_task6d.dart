import 'dart:convert';
import 'dart:io';

void main() async {
  final enKeys = {
    "communityPublicGroup": "Public group",
    "communityError": "Error: {error}",
    "communityMembersCount": "{count} members",
    "communityRefuseError": "Error while refusing",
    "communityRefuse": "Refuse",
    "communityAcceptError": "Error while accepting",
    "communityAccept": "Accept"
  };

  final frKeys = {
    "communityPublicGroup": "Groupe public",
    "communityError": "Erreur: {error}",
    "communityMembersCount": "{count} membres",
    "communityRefuseError": "Erreur lors du refus",
    "communityRefuse": "Refuser",
    "communityAcceptError": "Erreur lors de l'acceptation",
    "communityAccept": "Accepter"
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
      if (k == 'communityError') {
        data["@" + k] = {
          "description": "Error message with error details",
          "placeholders": {
            "error": {
              "type": "String",
              "example": "Network error"
            }
          }
        };
      } else if (k == 'communityMembersCount') {
        data["@" + k] = {
          "description": "Number of members in a group",
          "placeholders": {
            "count": {
              "type": "int",
              "example": "42"
            }
          }
        };
      } else {
        data["@" + k] = {"description": "Added for community sweep"};
      }
    }
  }

  await file.writeAsString(JsonEncoder.withIndent('  ').convert(data));
}
