import 'package:akeli/l10n/app_localizations.dart';

String mealTypeLabel(AppLocalizations l10n, String slug) => switch (slug.toLowerCase()) {
  'breakfast'                       => l10n.mealTypeBreakfast,
  'lunch'                           => l10n.mealTypeLunch,
  'dinner'                          => l10n.mealTypeDinner,
  'snack' || 'snack_1' || 'snack_2' || 'snack_3' => l10n.mealTypeSnack,
  _                                 => slug,
};
