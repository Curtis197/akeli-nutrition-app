# L10n Workflow Standard & Full Retrofit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enforce a mandatory l10n standard in CLAUDE.md and retrofit all ~15 pages/widgets that still contain hardcoded user-visible strings.

**Architecture:** CLAUDE.md is updated first (Task 1), then files are retrofitted in 4 sequential batches. Each batch: (a) add keys to both `app_en.arb` + `app_fr.arb`, (b) wire `AppLocalizations.of(context)` in each file, (c) run `flutter gen-l10n` once, (d) verify with `flutter analyze`, (e) commit.

**Tech Stack:** Flutter, `flutter_localizations`, `intl`, Riverpod, `AppLocalizations` (generated from `l10n.yaml`)

## Global Constraints

- Every new ARB key must be added to **both** `lib/l10n/app_en.arb` AND `lib/l10n/app_fr.arb` in the same step — never one without the other.
- Key naming: `<screen>_<key>` camelCase — e.g. `legalPrivacyTitle`, `cookingSessionGotIt`.
- `common_*` keys already exist for generic actions — reuse `commonCancel`, `commonSave`, `commonError`, `commonLoading`, etc. before adding new ones.
- Existing meal-type keys `mealTypeBreakfast`, `mealTypeLunch`, `mealTypeDinner`, `mealTypeSnack` must be reused wherever meal types are displayed.
- `flutter gen-l10n` is run **once per batch** after all ARB edits in that batch — not per file.
- `flutter analyze` must pass (zero errors) before committing any batch.
- Every Dart file must import `'package:akeli/l10n/app_localizations.dart'` and resolve `final l10n = AppLocalizations.of(context);` inside `build()`.
- Providers/notifiers must never resolve l10n strings — string resolution is widget-layer only.
- Logging standard from CLAUDE.md remains mandatory in all files touched.

---

## Task 1: Add L10n Standard to CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

**Interfaces:**
- Produces: the mandatory l10n rule that all future tasks and files must follow

- [ ] **Step 1: Add the l10n standard section to CLAUDE.md**

Open `CLAUDE.md` and add the following block immediately after the Logging Standard section (before any other section):

```markdown
## L10n Standard — Mandatory, Zero Exceptions

Every Dart widget and page written or modified in this project MUST use
`AppLocalizations` for every user-visible string. No hardcoded strings in UI.
Both `app_en.arb` and `app_fr.arb` must be updated together before any string
appears in Dart code.

### Rules

1. **No hardcoded user-visible strings** in any widget or page.
2. **ARB-first**: add to both `lib/l10n/app_en.arb` AND `lib/l10n/app_fr.arb`
   before referencing in code.
3. **Access pattern** — inside `build()`:
   ```dart
   import 'package:akeli/l10n/app_localizations.dart';
   // ...
   final l10n = AppLocalizations.of(context);
   ```
4. **Key naming**: `<screen>_<key>` camelCase (e.g. `legalPrivacyTitle`,
   `cookingSessionGotIt`). Shared keys use existing `common_` bucket.
5. **Outside widget tree** (FCM handlers etc.):
   ```dart
   AppLocalizations.of(rootScaffoldMessengerKey.currentContext!)
       ?.notificationSeeLabel ?? 'View'
   ```
6. **Providers and notifiers never resolve l10n strings** — widget layer only.
7. **Plurals/placeholders** use standard ARB format:
   ```json
   "screenCount": "{count, plural, one{{count} item} other{{count} items}}",
   "@screenCount": { "placeholders": { "count": { "type": "int" } } }
   ```
8. Run `flutter gen-l10n` after every ARB change before building/analyzing.
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(claude): add mandatory l10n standard"
```

---

## Task 2: Batch 1 — Shared Widgets

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/features/settings/widgets/allergen_picker_widget.dart`
- Modify: `lib/features/recipes/widgets/ingredient_detail_sheet.dart`
- Modify: `lib/features/cooking/cooking_session_bottom_sheet.dart`
- No changes needed: `lib/features/settings/widgets/settings_widgets.dart` (all labels are constructor params — already clean)
- No changes needed: `lib/features/home/home_creator_chip.dart` (no hardcoded user-visible strings)

**Interfaces:**
- Consumes: `AppLocalizations` generated class, existing `nutritionProtein` / `nutritionCarbs` / `nutritionFat` / `commonError` keys
- Produces: new ARB keys consumed by Batch 2–4

- [ ] **Step 1: Add new ARB keys to app_en.arb**

Append before the closing `}` of `lib/l10n/app_en.arb`:

```json
  "allergenPickerHint": "e.g. peanuts, nuts...",
  "@allergenPickerHint": {},

  "allergenPickerAdd": "Add \"{query}\"",
  "@allergenPickerAdd": {
    "placeholders": { "query": { "type": "String" } }
  },

  "allergenPickerSuggestionSent": "Suggestion sent for review.",
  "@allergenPickerSuggestionSent": {},

  "ingredientDetailOptional": "Optional",
  "@ingredientDetailOptional": {},

  "ingredientDetailTagHighProtein": "High protein",
  "@ingredientDetailTagHighProtein": {},

  "ingredientDetailTagLowFat": "Low fat",
  "@ingredientDetailTagLowFat": {},

  "ingredientDetailTagGlutenFree": "Gluten free",
  "@ingredientDetailTagGlutenFree": {},

  "ingredientDetailTagAfricanStaple": "African staple",
  "@ingredientDetailTagAfricanStaple": {},

  "ingredientDetailTagHardToFindEu": "Hard to find in Europe",
  "@ingredientDetailTagHardToFindEu": {},

  "ingredientDetailNutritionTitle": "Nutrition (per 100g)",
  "@ingredientDetailNutritionTitle": {},

  "ingredientDetailEnergy": "Energy",
  "@ingredientDetailEnergy": {},

  "cookingSessionTitle": "Cooking Session",
  "@cookingSessionTitle": {},

  "cookingSessionSubtitle": "Organize your meals for the week",
  "@cookingSessionSubtitle": {},

  "cookingSessionComingSoon": "Coming soon",
  "@cookingSessionComingSoon": {},

  "cookingSessionComingSoonDesc": "This feature will be available in a future update",
  "@cookingSessionComingSoonDesc": {},

  "cookingSessionGotIt": "Got it",
  "@cookingSessionGotIt": {}
```

- [ ] **Step 2: Add same keys to app_fr.arb**

Append before the closing `}` of `lib/l10n/app_fr.arb`:

```json
  "allergenPickerHint": "Ex: arachides, noix...",
  "allergenPickerAdd": "Ajouter \"{query}\"",
  "allergenPickerSuggestionSent": "Suggestion envoyée pour révision.",

  "ingredientDetailOptional": "Optionnel",
  "ingredientDetailTagHighProtein": "Riche en protéines",
  "ingredientDetailTagLowFat": "Pauvre en graisses",
  "ingredientDetailTagGlutenFree": "Sans gluten",
  "ingredientDetailTagAfricanStaple": "Aliment de base",
  "ingredientDetailTagHardToFindEu": "Difficile à trouver en Europe",
  "ingredientDetailNutritionTitle": "Valeurs nutritives (pour 100g)",
  "ingredientDetailEnergy": "Énergie",

  "cookingSessionTitle": "Session de cuisine",
  "cookingSessionSubtitle": "Organisez vos repas de la semaine",
  "cookingSessionComingSoon": "Bientôt disponible",
  "cookingSessionComingSoonDesc": "Cette fonctionnalité sera disponible dans une prochaine mise à jour",
  "cookingSessionGotIt": "Compris"
```

- [ ] **Step 3: Run flutter gen-l10n**

```bash
flutter gen-l10n
```

Expected: no errors, `lib/l10n/app_localizations_en.dart` and `app_localizations_fr.dart` regenerated.

- [ ] **Step 4: Wire allergen_picker_widget.dart**

Replace the entire file content with the l10n-wired version. Key changes:
- Add import `'package:akeli/l10n/app_localizations.dart';`
- In `build()`: `final l10n = AppLocalizations.of(context);`
- Replace `'Ex: arachides, noix...'` → `l10n.allergenPickerHint`
- Replace `'Ajouter "$_query"'` → `l10n.allergenPickerAdd(_query)`
- Replace `const SnackBar(content: Text('Suggestion envoyée pour révision.'))` → `SnackBar(content: Text(l10n.allergenPickerSuggestionSent))`
- Replace `Text('Erreur', ...)` → `Text(l10n.commonError, ...)`

Full updated `build()` method:

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final searchResultsAsync = ref.watch(searchAllergenProvider(_query));

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _focusNode,
              style: GoogleFonts.inter(fontSize: 14, color: AkeliColors.onSurface),
              decoration: InputDecoration(
                hintText: l10n.allergenPickerHint,
                filled: true,
                fillColor: AkeliColors.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AkeliRadius.md),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md, vertical: AkeliSpacing.sm),
              ),
              onSubmitted: (_) => _submitSuggestion(),
            ),
          ),
          const SizedBox(width: AkeliSpacing.sm),
          GestureDetector(
            onTap: _submitSuggestion,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AkeliColors.primary,
                borderRadius: BorderRadius.circular(AkeliRadius.md),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
      if (_query.isNotEmpty && _focusNode.hasFocus)
        Container(
          margin: const EdgeInsets.only(top: 4),
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: AkeliColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AkeliRadius.md),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: searchResultsAsync.when(
            data: (results) {
              if (results.isEmpty) {
                return ListTile(
                  title: Text(l10n.allergenPickerAdd(_query), style: GoogleFonts.inter(fontSize: 14)),
                  leading: const Icon(Icons.add, size: 20),
                  onTap: _submitSuggestion,
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, i) {
                  final a = results[i];
                  return ListTile(
                    title: Text(a.label, style: GoogleFonts.inter(fontSize: 14)),
                    onTap: () => _addAllergy(a),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(l10n.commonError, style: GoogleFonts.inter(color: Colors.red)),
            ),
          ),
        ),
      if (widget.selectedAllergens.isNotEmpty) ...[
        const SizedBox(height: AkeliSpacing.md),
        Wrap(
          spacing: AkeliSpacing.sm,
          runSpacing: AkeliSpacing.sm,
          children: widget.selectedAllergens.map((a) {
            return Chip(
              label: Text(a.label, style: GoogleFonts.inter(fontSize: 13, color: AkeliColors.onSurface)),
              backgroundColor: AkeliColors.surfaceContainerLow,
              deleteIcon: const Icon(Icons.close_rounded, size: 16),
              onDeleted: () {
                widget.onChanged(widget.selectedAllergens.where((x) => x.id != a.id).toList());
              },
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AkeliRadius.pill)),
            );
          }).toList(),
        ),
      ],
    ],
  );
}
```

Also update `_submitSuggestion()` to use l10n via a stored reference. Since `_submitSuggestion` is not inside `build()`, store context before calling async gap:

```dart
Future<void> _submitSuggestion() async {
  final txt = _query.trim();
  if (txt.isEmpty) return;

  _logger.userAction('Allergen suggested', screen: 'AllergenPicker', metadata: {'label': txt});
  _searchCtrl.clear();
  _focusNode.unfocus();

  final l10n = AppLocalizations.of(context);
  final client = ref.read(supabaseClientProvider);
  try {
    _logger.edge('submit-allergen-suggestion', 'BEFORE | label: $txt');
    await client.functions.invoke('submit-allergen-suggestion', body: {'label': txt});
    _logger.edge('submit-allergen-suggestion', 'AFTER | success');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.allergenPickerSuggestionSent)),
      );
    }
  } catch (e, st) {
    _logger.edge('submit-allergen-suggestion', 'ERROR | $e', error: e, stackTrace: st);
  }
}
```

Add the import at the top of the file:
```dart
import 'package:akeli/l10n/app_localizations.dart';
```

- [ ] **Step 5: Wire ingredient_detail_sheet.dart**

Add import:
```dart
import 'package:akeli/l10n/app_localizations.dart';
```

Update `_TagPill` — replace the static `_tagLabels` map with a method that uses l10n. Change `_TagPill` to a `ConsumerWidget` or pass labels from parent. The cleanest approach: make `_TagPill` accept a resolved `label` String from `IngredientDetailSheet.build()`.

Replace the `_tagLabels` static map in `_TagPill` and the `String get _label` getter. Instead, resolve labels in `IngredientDetailSheet.build()` and pass to `_TagPill`:

In `IngredientDetailSheet.build()`, add after `final l10n = AppLocalizations.of(context);`:

```dart
final l10n = AppLocalizations.of(context);

Map<String, String> tagLabels(AppLocalizations l) => {
  'high_protein': l.ingredientDetailTagHighProtein,
  'low_fat': l.ingredientDetailTagLowFat,
  'gluten_free': l.ingredientDetailTagGlutenFree,
  'african_staple': l.ingredientDetailTagAfricanStaple,
  'very_hard_to_find_eu': l.ingredientDetailTagHardToFindEu,
};
```

Update the tags section in `build()`:
```dart
// in the data: (detail) callback where tags are rendered:
children: detail.tags
    .map((tag) => _TagPill(
          tag: tag,
          label: tagLabels(l10n)[tag] ?? tag.replaceAll('_', ' '),
        ))
    .toList(),
```

Update `_TagPill` to accept a `label` parameter instead of computing it:
```dart
class _TagPill extends StatelessWidget {
  final String tag;
  final String label;    // <-- new, resolved by parent
  const _TagPill({required this.tag, required this.label});

  static const _tagColors = {
    'high_protein': Color(0xFF2E7D32),
    'low_fat': Color(0xFF1565C0),
    'gluten_free': Color(0xFF6A1B9A),
    'african_staple': Color(0xFFE65100),
    'very_hard_to_find_eu': Color(0xFF78350F),
  };

  @override
  Widget build(BuildContext context) {
    final color = _tagColors[tag] ?? AkeliColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AkeliRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
```

In `_NutritionSection.build()`, resolve l10n and replace hardcoded strings:
```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l10n.ingredientDetailNutritionTitle,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AkeliColors.onSurface),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          if (detail.caloriesPer100g != null)
            Expanded(
                child: _MacroChip(
                    label: l10n.ingredientDetailEnergy,
                    value: '${detail.caloriesPer100g!.toStringAsFixed(0)} kcal')),
          if (detail.proteinPer100g != null) ...[
            const SizedBox(width: 8),
            Expanded(
                child: _MacroChip(
                    label: l10n.nutritionProtein,
                    value: '${detail.proteinPer100g!.toStringAsFixed(1)} g')),
          ],
          if (detail.carbsPer100g != null) ...[
            const SizedBox(width: 8),
            Expanded(
                child: _MacroChip(
                    label: l10n.nutritionCarbs,
                    value: '${detail.carbsPer100g!.toStringAsFixed(1)} g')),
          ],
        ],
      ),
      if (detail.fatPer100g != null) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _MacroChip(
                    label: l10n.nutritionFat,
                    value: '${detail.fatPer100g!.toStringAsFixed(1)} g')),
            const SizedBox(width: 8),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 8),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
      const SizedBox(height: 24),
    ],
  );
}
```

In `IngredientDetailSheet.build()`, add `final l10n = AppLocalizations.of(context);` at the top and replace `'Optionnel'`:
```dart
child: Text(
  l10n.ingredientDetailOptional,
  style: GoogleFonts.inter(fontSize: 12, color: AkeliColors.onSurfaceVariant),
),
```

- [ ] **Step 6: Wire cooking_session_bottom_sheet.dart**

Add import:
```dart
import 'package:akeli/l10n/app_localizations.dart';
```

In `build()`, add `final l10n = AppLocalizations.of(context);` at the top and replace:
- `'Session de cuisine'` → `l10n.cookingSessionTitle`
- `'Organisez vos repas de la semaine'` → `l10n.cookingSessionSubtitle`
- `'Bientôt disponible'` → `l10n.cookingSessionComingSoon`
- `'Cette fonctionnalité sera disponible dans une prochaine mise à jour'` → `l10n.cookingSessionComingSoonDesc`
- `'Compris'` → `l10n.cookingSessionGotIt`

- [ ] **Step 7: Verify**

```bash
flutter analyze
```

Expected: no errors in any of the 3 modified files.

- [ ] **Step 8: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_fr.arb \
  lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart \
  lib/l10n/app_localizations.dart \
  lib/features/settings/widgets/allergen_picker_widget.dart \
  lib/features/recipes/widgets/ingredient_detail_sheet.dart \
  lib/features/cooking/cooking_session_bottom_sheet.dart
git commit -m "feat(l10n): retrofit batch 1 — shared widgets"
```

---

## Task 3: Batch 2 — Journey Sub-widgets

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/features/nutrition/widgets/journey/journey_calendar.dart`
- Modify: `lib/features/nutrition/widgets/journey/journey_summary_row.dart`
- Modify: `lib/features/nutrition/widgets/journey/journey_goals_card.dart`

**Interfaces:**
- Consumes: `intl` package (`DateFormat`) already in pubspec
- Produces: l10n-clean journey widgets consumed by `journey_tab.dart`

- [ ] **Step 1: Add new ARB keys to app_en.arb**

Append before the closing `}`:

```json
  "journeyCalendarLegendAll": "All",
  "@journeyCalendarLegendAll": {},

  "journeyCalendarLegendPartial": "Partial",
  "@journeyCalendarLegendPartial": {},

  "journeyCalendarLegendNone": "None",
  "@journeyCalendarLegendNone": {},

  "journeySummaryDays": "Journey days",
  "@journeySummaryDays": {},

  "journeySummaryTracked": "Days tracked",
  "@journeySummaryTracked": {},

  "journeySummaryMeals": "Meals consumed",
  "@journeySummaryMeals": {},

  "journeySummaryConsistency": "Consistency",
  "@journeySummaryConsistency": {},

  "journeyGoalsWeight": "⚖️  Weight",
  "@journeyGoalsWeight": {},

  "journeyGoalsCalories": "🎯  Calories",
  "@journeyGoalsCalories": {},

  "journeyGoalsProtein": "💪  Protein",
  "@journeyGoalsProtein": {},

  "journeyGoalsCarbs": "🌾  Carbs",
  "@journeyGoalsCarbs": {},

  "journeyGoalsFat": "🥑  Fat",
  "@journeyGoalsFat": {},

  "journeyGoalsCalorieHitSubtitle": "You hit your calorie goal {pct}% of tracked days.",
  "@journeyGoalsCalorieHitSubtitle": {
    "placeholders": { "pct": { "type": "int" } }
  }
```

- [ ] **Step 2: Add same keys to app_fr.arb**

Append before the closing `}`:

```json
  "journeyCalendarLegendAll": "Tous",
  "journeyCalendarLegendPartial": "Partiel",
  "journeyCalendarLegendNone": "Aucun",

  "journeySummaryDays": "Jours de parcours",
  "journeySummaryTracked": "Jours suivis",
  "journeySummaryMeals": "Repas consommés",
  "journeySummaryConsistency": "Régularité",

  "journeyGoalsWeight": "⚖️  Poids",
  "journeyGoalsCalories": "🎯  Calories",
  "journeyGoalsProtein": "💪  Protéines",
  "journeyGoalsCarbs": "🌾  Glucides",
  "journeyGoalsFat": "🥑  Lipides",
  "journeyGoalsCalorieHitSubtitle": "Vous avez atteint votre objectif calorique {pct}% des jours logués."
```

- [ ] **Step 3: Run flutter gen-l10n**

```bash
flutter gen-l10n
```

- [ ] **Step 4: Wire journey_calendar.dart**

Add imports at top:
```dart
import 'package:akeli/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
```

Remove the static `_monthNames` and `_dayHeaders` constants entirely.

Replace `build()` with:

```dart
@override
Widget build(BuildContext context) {
  appLogger.provider('JourneyCalendar build() | $year-$month');
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).languageCode;

  final monthName = DateFormat('MMMM', locale).format(DateTime(year, month));
  final dayHeaders = List.generate(7, (i) {
    // Jan 5 2025 = Sunday; iterate Sun→Sat
    final date = DateTime(2025, 1, 5 + i);
    final abbr = DateFormat('EE', locale).format(date);
    return abbr.length >= 2 ? abbr.substring(0, 2) : abbr;
  });

  final firstOfMonth = DateTime(year, month, 1);
  final startDow = firstOfMonth.weekday % 7;
  final daysInMonth = DateUtils.getDaysInMonth(year, month);
  final today = DateTime.now();
  final isCurrentMonth = today.year == year && today.month == month;
  final dayMap = {for (final d in days) d.date.day: d};

  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AkeliColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: AkeliColors.onSurfaceVariant),
              onPressed: onPrevMonth,
              visualDensity: VisualDensity.compact,
            ),
            Text(
              '$monthName $year',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AkeliColors.onSurface,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: canGoNext ? AkeliColors.onSurfaceVariant : AkeliColors.outlineVariant,
              ),
              onPressed: canGoNext ? onNextMonth : null,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: dayHeaders
              .map((h) => Expanded(
                    child: Center(
                      child: Text(
                        h,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AkeliColors.outlineVariant,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 0.85,
          ),
          itemCount: startDow + daysInMonth,
          itemBuilder: (context, i) {
            if (i < startDow) return const SizedBox.shrink();
            final dayNum = i - startDow + 1;
            final isToday = isCurrentMonth && dayNum == today.day;
            final isFuture = DateTime(year, month, dayNum).isAfter(today);
            final dayData = dayMap[dayNum];
            return _DayCell(
              dayNum: dayNum,
              isToday: isToday,
              isFuture: isFuture,
              planned: isFuture ? 0 : (dayData?.planned ?? 0),
              consumed: isFuture ? 0 : (dayData?.consumed ?? 0),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: const Color(0xFF4ADE80), label: l10n.journeyCalendarLegendAll),
            const SizedBox(width: 14),
            _LegendItem(color: const Color(0xFFFACC15), label: l10n.journeyCalendarLegendPartial),
            const SizedBox(width: 14),
            _LegendItem(color: const Color(0xFFEF4444), label: l10n.journeyCalendarLegendNone),
          ],
        ),
      ],
    ),
  );
}
```

Note: `_DayCell` and `_LegendItem` are unchanged (they display data-driven strings like day numbers, not hardcoded labels — except the legend labels which are now passed via `l10n`).

- [ ] **Step 5: Wire journey_summary_row.dart**

Add import:
```dart
import 'package:akeli/l10n/app_localizations.dart';
```

Update `build()`:
```dart
@override
Widget build(BuildContext context) {
  _logger.provider('JourneySummaryRow build()');
  final l10n = AppLocalizations.of(context);
  return GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    childAspectRatio: 1.6,
    children: [
      _StatCard(icon: '📅', value: '${stats.totalDays}', label: l10n.journeySummaryDays),
      _StatCard(icon: '✅', value: '${stats.daysLogged}', label: l10n.journeySummaryTracked),
      _StatCard(icon: '🍽️', value: '${stats.mealsConsumed}', label: l10n.journeySummaryMeals),
      _StatCard(icon: '📊', value: '${stats.consistencyPct}%', label: l10n.journeySummaryConsistency),
    ],
  );
}
```

- [ ] **Step 6: Wire journey_goals_card.dart**

Add import:
```dart
import 'package:akeli/l10n/app_localizations.dart';
```

Update `build()` in `JourneyGoalsCard`:
```dart
@override
Widget build(BuildContext context) {
  appLogger.provider('JourneyGoalsCard build()');
  final l10n = AppLocalizations.of(context);
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AkeliColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stats.hasWeightGoal) ...[
          _GoalBar(
            label: l10n.journeyGoalsWeight,
            value: '${stats.weightCurrentKg?.toStringAsFixed(1)} kg → ${stats.weightTargetKg?.toStringAsFixed(1)} kg',
            progress: stats.weightProgressPct,
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFFACC15), Color(0xFF4ADE80)],
            ),
          ),
          const SizedBox(height: 12),
        ],
        _GoalBar(
          label: l10n.journeyGoalsCalories,
          value: '${stats.calorieHitPct}%',
          progress: stats.calorieHitPct / 100,
          color: AkeliColors.primary,
          subtitle: l10n.journeyGoalsCalorieHitSubtitle(stats.calorieHitPct),
        ),
        const SizedBox(height: 12),
        _GoalBar(
          label: l10n.journeyGoalsProtein,
          value: '${stats.proteinHitPct}%',
          progress: stats.proteinHitPct / 100,
          color: AkeliColors.secondary,
        ),
        const SizedBox(height: 12),
        _GoalBar(
          label: l10n.journeyGoalsCarbs,
          value: '${stats.carbsHitPct}%',
          progress: stats.carbsHitPct / 100,
          color: AkeliColors.accentAmber,
        ),
        const SizedBox(height: 12),
        _GoalBar(
          label: l10n.journeyGoalsFat,
          value: '${stats.fatHitPct}%',
          progress: stats.fatHitPct / 100,
          color: AkeliColors.warning,
        ),
      ],
    ),
  );
}
```

- [ ] **Step 7: Verify**

```bash
flutter analyze
```

Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_fr.arb \
  lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart \
  lib/l10n/app_localizations.dart \
  lib/features/nutrition/widgets/journey/journey_calendar.dart \
  lib/features/nutrition/widgets/journey/journey_summary_row.dart \
  lib/features/nutrition/widgets/journey/journey_goals_card.dart
git commit -m "feat(l10n): retrofit batch 2 — journey sub-widgets"
```

---

## Task 4: Batch 3 — Feature Pages

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/features/subscription/subscription_page.dart`
- Modify: `lib/features/journaling/journaling_bottom_sheet.dart`
- Modify: `lib/features/ai_assistant/ai_chat_page.dart`
- Modify: `lib/features/referral/referral_page.dart`
- Modify: `lib/features/support/support_page.dart`
- Modify: `lib/features/settings/saved_recipes_eligibility_page.dart`

**Interfaces:**
- Consumes: existing `mealTypeBreakfast/Lunch/Dinner/Snack`, `commonSave`, `commonError`, `accountEmail`, `savedRecipesTitle`, `homeErrorGeneric`
- Produces: new keys used by the 6 retrofitted pages

- [ ] **Step 1: Add new ARB keys to app_en.arb**

Append before the closing `}`:

```json
  "subscriptionMyTitle": "My Subscription",
  "@subscriptionMyTitle": {},

  "subscriptionActiveTitle": "Active Subscription",
  "@subscriptionActiveTitle": {},

  "subscriptionPremiumBadge": "Akeli Premium",
  "@subscriptionPremiumBadge": {},

  "subscriptionActiveThankYou": "Thank you for being part of the Akeli community.",
  "@subscriptionActiveThankYou": {},

  "subscriptionTagline": "Personalized African nutrition",
  "@subscriptionTagline": {},

  "subscriptionIncludedTitle": "What's included",
  "@subscriptionIncludedTitle": {},

  "subscriptionPerMonth": "/ month",
  "@subscriptionPerMonth": {},

  "subscriptionCancelAnytime": "Cancel anytime via the Store",
  "@subscriptionCancelAnytime": {},

  "subscriptionSubscribeViaStore": "Subscribe via the Store",
  "@subscriptionSubscribeViaStore": {},

  "subscriptionMobileOnly": "Subscription available on iOS and Android only.",
  "@subscriptionMobileOnly": {},

  "subscriptionFeature1": "Personalized African recipes with AI",
  "@subscriptionFeature1": {},

  "subscriptionFeature2": "Adapted weekly meal plan",
  "@subscriptionFeature2": {},

  "subscriptionFeature3": "Detailed nutritional tracking",
  "@subscriptionFeature3": {},

  "subscriptionFeature4": "Nutritional AI assistant",
  "@subscriptionFeature4": {},

  "subscriptionFeature5": "Fan Mode — support your creators",
  "@subscriptionFeature5": {},

  "subscriptionFeature6": "Community and discussion groups",
  "@subscriptionFeature6": {},

  "subscriptionFeature7": "Automatic shopping list",
  "@subscriptionFeature7": {},

  "subscriptionActiveBadge": "Active Premium Subscription",
  "@subscriptionActiveBadge": {},

  "subscriptionRenewalDate": "Next renewal: {date}",
  "@subscriptionRenewalDate": {
    "placeholders": { "date": { "type": "String" } }
  },

  "subscriptionPlatformIos": "Subscription via App Store",
  "@subscriptionPlatformIos": {},

  "subscriptionPlatformAndroid": "Subscription via Google Play",
  "@subscriptionPlatformAndroid": {},

  "journalingNewEntry": "New entry",
  "@journalingNewEntry": {},

  "journalingNewEntrySubtitle": "Note your culinary experience",
  "@journalingNewEntrySubtitle": {},

  "journalingPhotos": "Photos",
  "@journalingPhotos": {},

  "journalingAddPhotos": "Add photos",
  "@journalingAddPhotos": {},

  "journalingMealType": "Meal type",
  "@journalingMealType": {},

  "journalingDescription": "Description",
  "@journalingDescription": {},

  "journalingDescriptionHint": "How was this meal? Tastes, textures, emotions...",
  "@journalingDescriptionHint": {},

  "journalingDescriptionRequired": "Please add a description",
  "@journalingDescriptionRequired": {},

  "journalingSaving": "Saving...",
  "@journalingSaving": {},

  "journalingSaveEntry": "Save entry",
  "@journalingSaveEntry": {},

  "journalingEntrySaved": "Entry saved successfully!",
  "@journalingEntrySaved": {},

  "journalingSaveError": "Error saving entry",
  "@journalingSaveError": {},

  "aiAssistantOnline": "Online",
  "@aiAssistantOnline": {},

  "aiAssistantNewConversation": "New conversation",
  "@aiAssistantNewConversation": {},

  "aiAssistantToday": "TODAY",
  "@aiAssistantToday": {},

  "aiAssistantError": "Sorry, an error occurred. Please try again in a moment.",
  "@aiAssistantError": {},

  "aiAssistantWelcomeTitle": "Hello, I'm your Akeli nutritional assistant.",
  "@aiAssistantWelcomeTitle": {},

  "aiAssistantWelcomeSubtitle": "Ask me your questions about nutrition, African recipes or your meal plan.",
  "@aiAssistantWelcomeSubtitle": {},

  "aiAssistantSuggestions": "Suggestions",
  "@aiAssistantSuggestions": {},

  "aiAssistantMessageHint": "Message...",
  "@aiAssistantMessageHint": {},

  "aiAssistantSuggestion1": "Which protein-rich foods suit my culture?",
  "@aiAssistantSuggestion1": {},

  "aiAssistantSuggestion2": "What is my recommended caloric intake?",
  "@aiAssistantSuggestion2": {},

  "aiAssistantSuggestion3": "How to lose weight with African cuisine?",
  "@aiAssistantSuggestion3": {},

  "aiAssistantSuggestion4": "Give me a recipe for tonight.",
  "@aiAssistantSuggestion4": {},

  "referralCodeLabel": "Your referral code",
  "@referralCodeLabel": {},

  "referralReferreeCount": "{count, plural, one{{count} referral} other{{count} referrals}}",
  "@referralReferreeCount": {
    "placeholders": { "count": { "type": "int" } }
  },

  "referralShareTitle": "Share the Oasis",
  "@referralShareTitle": {},

  "referralShareBody": "Invite your friends to discover Akeli Oasis. For every friend who signs up with your code, you'll receive an exclusive wellness ritual invitation, and they'll get a privileged welcome.",
  "@referralShareBody": {},

  "referralChangeCodeTitle": "Change code",
  "@referralChangeCodeTitle": {},

  "referralEditCode": "Edit code",
  "@referralEditCode": {},

  "referralNewCodeLabel": "New code",
  "@referralNewCodeLabel": {},

  "referralNewCodeHint": "Enter a new code",
  "@referralNewCodeHint": {},

  "referralCodeUpdated": "Code updated successfully!",
  "@referralCodeUpdated": {},

  "supportHeaderTitle": "How can we help you?",
  "@supportHeaderTitle": {},

  "supportHeaderSubtitle": "Our team is here to answer your questions",
  "@supportHeaderSubtitle": {},

  "supportSubjectLabel": "Subject",
  "@supportSubjectLabel": {},

  "supportSubjectHint": "e.g. Login issue...",
  "@supportSubjectHint": {},

  "supportSubjectRequired": "Please enter a subject",
  "@supportSubjectRequired": {},

  "supportEmailHint": "your@email.com",
  "@supportEmailHint": {},

  "supportEmailRequired": "Please enter your email",
  "@supportEmailRequired": {},

  "supportEmailInvalid": "Please enter a valid email",
  "@supportEmailInvalid": {},

  "supportMessageLabel": "Message",
  "@supportMessageLabel": {},

  "supportMessageHint": "Describe your issue...",
  "@supportMessageHint": {},

  "supportMessageRequired": "Please enter your message",
  "@supportMessageRequired": {},

  "supportMessageTooShort": "Message must be at least 10 characters",
  "@supportMessageTooShort": {},

  "supportAddScreenshot": "Add a screenshot",
  "@supportAddScreenshot": {},

  "supportSendMessage": "Send message",
  "@supportSendMessage": {},

  "supportMessageSent": "Message sent successfully!",
  "@supportMessageSent": {},

  "supportSendError": "Error sending. Please try again.",
  "@supportSendError": {},

  "supportChangeScreenshot": "Change screenshot",
  "@supportChangeScreenshot": {},

  "savedRecipesEligibilityNotLoggedIn": "Not logged in",
  "@savedRecipesEligibilityNotLoggedIn": {},

  "savedRecipesEligibilityNoData": "No data found",
  "@savedRecipesEligibilityNoData": {},

  "savedRecipesEligibilityTitle": "Generate from your favorites",
  "@savedRecipesEligibilityTitle": {},

  "savedRecipesEligibilityDesc": "If you have enough saved recipes, you can ask Akeli to generate your meal plans only from your favorites, rather than through our recommendations.",
  "@savedRecipesEligibilityDesc": {},

  "savedRecipesEligibilityProgress": "Progress",
  "@savedRecipesEligibilityProgress": {},

  "savedRecipesEligibilityMissing": "{count, plural, one{{count} recipe missing} other{{count} recipes missing}}",
  "@savedRecipesEligibilityMissing": {
    "placeholders": { "count": { "type": "int" } }
  },

  "savedRecipesEligibilityToggleTitle": "Use favorites only",
  "@savedRecipesEligibilityToggleTitle": {},

  "savedRecipesEligibilityEnabled": "Enabled",
  "@savedRecipesEligibilityEnabled": {},

  "savedRecipesEligibilityBlocked": "Locked: You must reach 7 recipes for each category above.",
  "@savedRecipesEligibilityBlocked": {}
```

- [ ] **Step 2: Add same keys to app_fr.arb**

Append before the closing `}`:

```json
  "subscriptionMyTitle": "Mon abonnement",
  "subscriptionActiveTitle": "Abonnement actif",
  "subscriptionPremiumBadge": "Akeli Premium",
  "subscriptionActiveThankYou": "Merci de faire partie de la communauté Akeli.",
  "subscriptionTagline": "Nutrition africaine personnalisée",
  "subscriptionIncludedTitle": "Ce qui est inclus",
  "subscriptionPerMonth": "/ mois",
  "subscriptionCancelAnytime": "Annulable à tout moment via le Store",
  "subscriptionSubscribeViaStore": "S'abonner via le Store",
  "subscriptionMobileOnly": "Abonnement disponible sur iOS et Android uniquement.",
  "subscriptionFeature1": "Recettes africaines personnalisées avec IA",
  "subscriptionFeature2": "Plan alimentaire hebdomadaire adapté",
  "subscriptionFeature3": "Suivi nutritionnel détaillé",
  "subscriptionFeature4": "Assistant IA nutritionnel",
  "subscriptionFeature5": "Mode Fan — soutenez vos créateurs",
  "subscriptionFeature6": "Communauté et groupes de discussion",
  "subscriptionFeature7": "Liste de courses automatique",
  "subscriptionActiveBadge": "Abonnement Premium actif",
  "subscriptionRenewalDate": "Prochain renouvellement : {date}",
  "subscriptionPlatformIos": "Abonnement via App Store",
  "subscriptionPlatformAndroid": "Abonnement via Google Play",

  "journalingNewEntry": "Nouvelle entrée",
  "journalingNewEntrySubtitle": "Notez votre expérience culinaire",
  "journalingPhotos": "Photos",
  "journalingAddPhotos": "Ajouter des photos",
  "journalingMealType": "Type de repas",
  "journalingDescription": "Description",
  "journalingDescriptionHint": "Comment s'est passé ce repas? Goûts, textures, émotions...",
  "journalingDescriptionRequired": "Veuillez ajouter une description",
  "journalingSaving": "Enregistrement...",
  "journalingSaveEntry": "Enregistrer l'entrée",
  "journalingEntrySaved": "Entrée enregistrée avec succès!",
  "journalingSaveError": "Erreur lors de l'enregistrement",

  "aiAssistantOnline": "En ligne",
  "aiAssistantNewConversation": "Nouvelle conversation",
  "aiAssistantToday": "AUJOURD'HUI",
  "aiAssistantError": "Désolé, une erreur est survenue. Réessayez dans un moment.",
  "aiAssistantWelcomeTitle": "Bonjour, je suis votre assistant nutritionnel Akeli.",
  "aiAssistantWelcomeSubtitle": "Posez-moi vos questions sur la nutrition, les recettes africaines ou votre plan alimentaire.",
  "aiAssistantSuggestions": "Suggestions",
  "aiAssistantMessageHint": "Message...",
  "aiAssistantSuggestion1": "Quels aliments riches en protéines pour ma culture ?",
  "aiAssistantSuggestion2": "Quel est mon apport calorique recommandé ?",
  "aiAssistantSuggestion3": "Comment perdre du poids avec la cuisine africaine ?",
  "aiAssistantSuggestion4": "Donne-moi une recette pour ce soir.",

  "referralCodeLabel": "Votre code de parrainage",
  "referralReferreeCount": "{count, plural, one{{count} filleul} other{{count} filleuls}}",
  "referralShareTitle": "Partagez l'Oasis",
  "referralShareBody": "Invitez vos amis à découvrir Akeli Oasis. Pour chaque ami qui s'inscrit avec votre code, vous recevrez une invitation à un rituel de bien-être exclusif, et ils bénéficieront d'un accueil privilégié.",
  "referralChangeCodeTitle": "Changer de code",
  "referralEditCode": "Modifier le code",
  "referralNewCodeLabel": "Nouveau code",
  "referralNewCodeHint": "Entrez un nouveau code",
  "referralCodeUpdated": "Code mis à jour avec succès!",

  "supportHeaderTitle": "Comment pouvons-nous vous aider?",
  "supportHeaderSubtitle": "Notre équipe est là pour répondre à vos questions",
  "supportSubjectLabel": "Sujet",
  "supportSubjectHint": "Ex: Problème de connexion...",
  "supportSubjectRequired": "Veuillez entrer un sujet",
  "supportEmailHint": "votre@email.com",
  "supportEmailRequired": "Veuillez entrer votre email",
  "supportEmailInvalid": "Veuillez entrer un email valide",
  "supportMessageLabel": "Message",
  "supportMessageHint": "Décrivez votre problème...",
  "supportMessageRequired": "Veuillez entrer votre message",
  "supportMessageTooShort": "Le message doit contenir au moins 10 caractères",
  "supportAddScreenshot": "Ajouter une capture d'écran",
  "supportSendMessage": "Envoyer le message",
  "supportMessageSent": "Message envoyé avec succès!",
  "supportSendError": "Erreur lors de l'envoi. Veuillez réessayer.",
  "supportChangeScreenshot": "Changer la capture",

  "savedRecipesEligibilityNotLoggedIn": "Non connecté",
  "savedRecipesEligibilityNoData": "Aucune donnée trouvée",
  "savedRecipesEligibilityTitle": "Générer avec vos favoris",
  "savedRecipesEligibilityDesc": "Si vous avez suffisamment de recettes enregistrées, vous pouvez demander à Akeli de générer vos plans de repas uniquement à partir de vos favoris, plutôt que via nos recommandations.",
  "savedRecipesEligibilityProgress": "Progression",
  "savedRecipesEligibilityMissing": "{count, plural, one{Il manque {count} recette} other{Il manque {count} recettes}}",
  "savedRecipesEligibilityToggleTitle": "Utiliser uniquement les favoris",
  "savedRecipesEligibilityEnabled": "Activé",
  "savedRecipesEligibilityBlocked": "Bloqué: Vous devez atteindre 7 recettes pour chaque catégorie ci-dessus."
```

- [ ] **Step 3: Run flutter gen-l10n**

```bash
flutter gen-l10n
```

- [ ] **Step 4: Wire subscription_page.dart**

Add import:
```dart
import 'package:akeli/l10n/app_localizations.dart';
```

In `build()`, add `final l10n = AppLocalizations.of(context);` at top. Replace:
- AppBar title `'Mon abonnement'` → `l10n.subscriptionMyTitle`
- `isPremium ? 'Abonnement actif' : 'Akeli Premium'` → `isPremium ? l10n.subscriptionActiveTitle : l10n.subscriptionPremiumBadge`
- `isPremium ? 'Merci...' : 'Nutrition africaine...'` → `isPremium ? l10n.subscriptionActiveThankYou : l10n.subscriptionTagline`
- `'Ce qui est inclus'` → `l10n.subscriptionIncludedTitle`
- `' / mois'` → `l10n.subscriptionPerMonth`
- `'Annulable à tout moment via le Store'` → `l10n.subscriptionCancelAnytime`
- `"S'abonner via le Store"` → `l10n.subscriptionSubscribeViaStore`
- SnackBar `'Abonnement disponible sur iOS et Android uniquement.'` → `l10n.subscriptionMobileOnly`
- The `_features` static list must become a method returning l10n strings. Remove the static const `_features` list and add:

```dart
List<String> _featuresList(AppLocalizations l) => [
  l.subscriptionFeature1,
  l.subscriptionFeature2,
  l.subscriptionFeature3,
  l.subscriptionFeature4,
  l.subscriptionFeature5,
  l.subscriptionFeature6,
  l.subscriptionFeature7,
];
```

Use `_featuresList(l10n).map(...)` instead of `_features.map(...)`.

In `_ActiveSubCard.build()`, add `final l10n = AppLocalizations.of(context);` and replace:
- `'Abonnement Premium actif'` → `l10n.subscriptionActiveBadge`
- `'Prochain renouvellement : ${_formatDate(expiresAt)}'` → `l10n.subscriptionRenewalDate(_formatDate(expiresAt))`
- `'Abonnement via ${platform == 'ios' ? 'App Store' : 'Google Play'}'` → `platform == 'ios' ? l10n.subscriptionPlatformIos : l10n.subscriptionPlatformAndroid`

- [ ] **Step 5: Wire journaling_bottom_sheet.dart**

Add import:
```dart
import 'package:akeli/l10n/app_localizations.dart';
```

Change `_selectedMealType` internal value to use English DB keys and store separately from display:

```dart
// Replace:
String _selectedMealType = 'Déjeuner';
final List<String> _mealTypes = ['Petit-déjeuner', 'Déjeuner', 'Dîner', 'Collation'];

// With:
String _selectedMealType = 'lunch'; // DB key
static const _mealTypeKeys = ['breakfast', 'lunch', 'dinner', 'snack'];
```

Add a helper to get l10n display name from key:
```dart
String _mealTypeLabel(String key, AppLocalizations l) {
  switch (key) {
    case 'breakfast': return l.mealTypeBreakfast;
    case 'lunch':     return l.mealTypeLunch;
    case 'dinner':    return l.mealTypeDinner;
    case 'snack':     return l.mealTypeSnack;
    default:          return key;
  }
}
```

In `build()`, add `final l10n = AppLocalizations.of(context);` and replace all hardcoded strings:
- `'Veuillez ajouter une description'` → `l10n.journalingDescriptionRequired`
- `'Entrée enregistrée avec succès!'` → `l10n.journalingEntrySaved`
- `"Erreur lors de l'enregistrement"` → `l10n.journalingSaveError`
- `'Nouvelle entrée'` → `l10n.journalingNewEntry`
- `'Notez votre expérience culinaire'` → `l10n.journalingNewEntrySubtitle`
- `'Photos'` → `l10n.journalingPhotos`
- `'Ajouter des photos'` → `l10n.journalingAddPhotos`
- `'Type de repas'` → `l10n.journalingMealType`
- `'Description'` → `l10n.journalingDescription`
- `"Comment s'est passé ce repas?..."` → `l10n.journalingDescriptionHint`
- `_isSaving ? 'Enregistrement...' : 'Enregistrer l\'entrée'` → `_isSaving ? l10n.journalingSaving : l10n.journalingSaveEntry`

Update `ChoiceChip` labels to use `_mealTypeLabel(type, l10n)`:
```dart
children: _mealTypeKeys.map((key) {
  final isSelected = _selectedMealType == key;
  return ChoiceChip(
    label: Text(_mealTypeLabel(key, l10n)),
    selected: isSelected,
    onSelected: (selected) {
      if (selected) {
        _logger.userAction('Meal type selected: $key', screen: 'JournalingBottomSheet');
        setState(() => _selectedMealType = key);
      }
    },
    selectedColor: AkeliColors.primary,
    labelStyle: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      color: isSelected ? AkeliColors.onPrimary : AkeliColors.onSurface,
    ),
  );
}).toList(),
```

In `_saveEntry()`, capture l10n before the async gap:
```dart
Future<void> _saveEntry() async {
  final l10n = AppLocalizations.of(context);
  if (_descriptionController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.journalingDescriptionRequired), ...),
    );
    return;
  }
  // ... rest of method using l10n.journalingEntrySaved, l10n.journalingSaveError
```

- [ ] **Step 6: Wire ai_chat_page.dart**

Add import to page section (below existing imports):
```dart
import 'package:akeli/l10n/app_localizations.dart';
```

In `AiChatNotifier.sendMessage()`, the error message is built in a provider — move it to the page layer. Change the notifier to expose an error state instead of embedding the string:

Replace the hardcoded error content in `AiChatNotifier`:
```dart
// Replace:
content: 'Désolé, une erreur est survenue. Réessayez dans un moment.',

// With a sentinel that the UI detects:
content: '__error__',
```

In `_MessageBubble.build()`, detect the sentinel and resolve via l10n:
```dart
final displayContent = message.content == '__error__'
    ? AppLocalizations.of(context).aiAssistantError
    : message.content;
// Use displayContent instead of message.content in the Text widget
```

In `_AiChatPageState.build()`, add `final l10n = AppLocalizations.of(context);` and replace:
- AppBar `'Assistant Akeli'` → `l10n.aiAssistantTitle`
- `'En ligne'` → `l10n.aiAssistantOnline`
- tooltip `'Nouvelle conversation'` → `l10n.aiAssistantNewConversation`
- `"AUJOURD'HUI"` → `l10n.aiAssistantToday`
- hintText `'Message...'` → `l10n.aiAssistantMessageHint`

In `_WelcomeView`, change `_suggestions` from a static const list to a method receiving `AppLocalizations`:
```dart
// Remove:
static const _suggestions = ['Quels aliments...', ...];

// The parent _AiChatPageState passes l10n-resolved suggestions:
```

Update `_WelcomeView` to accept suggestions as a parameter:
```dart
class _WelcomeView extends StatelessWidget {
  final void Function(String) onSuggestion;
  final List<String> suggestions;   // <-- new

  const _WelcomeView({required this.onSuggestion, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    appLogger.d('WelcomeView build()');
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      // ...same layout...
      child: Column(
        children: [
          // ...avatar + welcome text using l10n...
          Text(l10n.aiAssistantWelcomeTitle, ...),
          Text(l10n.aiAssistantWelcomeSubtitle, ...),
          // ...
          Text(l10n.aiAssistantSuggestions, ...),
          ...suggestions.map((s) => /* chip using s */ ...),
        ],
      ),
    );
  }
}
```

In `_AiChatPageState.build()`, pass suggestions:
```dart
_WelcomeView(
  onSuggestion: (s) {
    _inputCtrl.text = s;
    _sendMessage();
  },
  suggestions: [
    l10n.aiAssistantSuggestion1,
    l10n.aiAssistantSuggestion2,
    l10n.aiAssistantSuggestion3,
    l10n.aiAssistantSuggestion4,
  ],
)
```

- [ ] **Step 7: Wire referral_page.dart**

Add import:
```dart
import 'package:akeli/l10n/app_localizations.dart';
```

In `build()`, add `final l10n = AppLocalizations.of(context);` and replace:
- AppBar title `'Parrainage'` → `l10n.referralTitle`
- `'Votre code de parrainage'` → `l10n.referralCodeLabel`
- `'$_referralCount filleul(s)'` → `l10n.referralReferreeCount(_referralCount)`
- `"Partagez l'Oasis"` → `l10n.referralShareTitle`
- `"Invitez vos amis..."` → `l10n.referralShareBody`
- `'Changer de code'` → `l10n.referralChangeCodeTitle`
- `'Modifier le code'` → `l10n.referralEditCode`
- labelText `'Nouveau code'` → `l10n.referralNewCodeLabel`
- hintText `'Entrez un nouveau code'` → `l10n.referralNewCodeHint`
- `'Enregistrer'` → `l10n.commonSave`

In `_saveCode()`, capture l10n before async gap:
```dart
Future<void> _saveCode() async {
  final l10n = AppLocalizations.of(context);
  // ...
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.referralCodeUpdated), ...),
  );
```

- [ ] **Step 8: Wire support_page.dart**

Add import:
```dart
import 'package:akeli/l10n/app_localizations.dart';
```

In `build()`, add `final l10n = AppLocalizations.of(context);` and replace:
- AppBar title `'Support'` → `l10n.supportTitle`
- `'Comment pouvons-nous vous aider?'` → `l10n.supportHeaderTitle`
- `'Notre équipe est là...'` → `l10n.supportHeaderSubtitle`
- `'Sujet'` label → `l10n.supportSubjectLabel`
- validator `'Veuillez entrer un sujet'` → `l10n.supportSubjectRequired`
- `'Email'` label → `l10n.accountEmail` (reuse existing key)
- validator `'Veuillez entrer votre email'` → `l10n.supportEmailRequired`
- validator `'Veuillez entrer un email valide'` → `l10n.supportEmailInvalid`
- `'Message'` label → `l10n.supportMessageLabel`
- validator `'Veuillez entrer votre message'` → `l10n.supportMessageRequired`
- validator `'Le message doit contenir...'` → `l10n.supportMessageTooShort`
- button label `'Ajouter une capture d\'écran'` → `l10n.supportAddScreenshot`
- submit button `'Envoyer le message'` → `l10n.supportSendMessage`

Pass l10n hint through `_fieldDecoration`:
```dart
InputDecoration _fieldDecoration(String hint) { ... } // hint is now already resolved
```

Update calls: `_fieldDecoration(l10n.supportSubjectHint)`, `_fieldDecoration(l10n.supportEmailHint)`, `_fieldDecoration(l10n.supportMessageHint)`.

In `_submitForm()` and `_showErrorSnackbar()`, capture l10n before async gaps and replace:
- `'Message envoyé avec succès!'` → `l10n.supportMessageSent`
- `"Erreur lors de l'envoi. Veuillez réessayer."` → `l10n.supportSendError`

In `_ScreenshotPreview.build()`, add `final l10n = AppLocalizations.of(context);` and replace:
- `'Changer la capture'` → `l10n.supportChangeScreenshot`

- [ ] **Step 9: Wire saved_recipes_eligibility_page.dart**

Add import:
```dart
import 'package:akeli/l10n/app_localizations.dart';
```

In `build()`, add `final l10n = AppLocalizations.of(context);` and replace:
- `'Not logged in'` → `l10n.savedRecipesEligibilityNotLoggedIn`
- AppBar title `'Recettes Enregistrées'` → `l10n.savedRecipesTitle` (reuse existing key)
- `'Erreur: $e'` (in error states) → `l10n.homeErrorGeneric(e.toString())` (reuse existing key)
- `'Aucune donnée trouvée'` → `l10n.savedRecipesEligibilityNoData`
- `'Générer avec vos favoris'` → `l10n.savedRecipesEligibilityTitle`
- `'Si vous avez suffisamment...'` → `l10n.savedRecipesEligibilityDesc`
- `'Progression'` → `l10n.savedRecipesEligibilityProgress`
- `'Il manque ${p.targetCount - p.savedCount} recette(s)'` → `l10n.savedRecipesEligibilityMissing(p.targetCount - p.savedCount)`
- SwitchListTile title `'Utiliser uniquement les favoris'` → `l10n.savedRecipesEligibilityToggleTitle`
- subtitle `'Activé'` → `l10n.savedRecipesEligibilityEnabled`
- subtitle `'Bloqué: ...'` → `l10n.savedRecipesEligibilityBlocked`

- [ ] **Step 10: Verify**

```bash
flutter analyze
```

Expected: no errors in any of the 6 modified files.

- [ ] **Step 11: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_fr.arb \
  lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart \
  lib/l10n/app_localizations.dart \
  lib/features/subscription/subscription_page.dart \
  lib/features/journaling/journaling_bottom_sheet.dart \
  lib/features/ai_assistant/ai_chat_page.dart \
  lib/features/referral/referral_page.dart \
  lib/features/support/support_page.dart \
  lib/features/settings/saved_recipes_eligibility_page.dart
git commit -m "feat(l10n): retrofit batch 3 — feature pages"
```

---

## Task 5: Batch 4 — Legal Pages + main.dart Fix

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/features/legal/privacy_policy_page.dart`
- Modify: `lib/features/legal/terms_of_service_page.dart`
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: existing `notificationSeeLabel` key (already in ARB), `rootScaffoldMessengerKey` from `core/notification_handler.dart`
- Produces: fully l10n-clean codebase

- [ ] **Step 1: Add legal keys to app_en.arb**

Append before the closing `}`:

```json
  "legalPrivacyTitle": "Privacy Policy",
  "@legalPrivacyTitle": {},

  "legalPrivacyHeroTitle": "Your data is protected",
  "@legalPrivacyHeroTitle": {},

  "legalPrivacyHeroSubtitle": "We are committed to protecting your privacy in accordance with GDPR",
  "@legalPrivacyHeroSubtitle": {},

  "legalPrivacySummaryTitle": "In brief",
  "@legalPrivacySummaryTitle": {},

  "legalPrivacyCollectionTitle": "Minimal collection",
  "@legalPrivacyCollectionTitle": {},

  "legalPrivacyCollectionDesc": "Only data necessary for the app to function",
  "@legalPrivacyCollectionDesc": {},

  "legalPrivacySecurityTitle": "Maximum security",
  "@legalPrivacySecurityTitle": {},

  "legalPrivacySecurityDesc": "End-to-end encryption and secure storage",
  "@legalPrivacySecurityDesc": {},

  "legalPrivacyControlTitle": "Total control",
  "@legalPrivacyControlTitle": {},

  "legalPrivacyControlDesc": "You can access, modify or delete your data at any time",
  "@legalPrivacyControlDesc": {},

  "legalPrivacySection1Title": "1. Data collection",
  "@legalPrivacySection1Title": {},

  "legalPrivacySection1Content": "We collect only the data needed to provide you with the best experience:\n\n• Profile information (name, email, dietary preferences)\n• Navigation history within the app\n• Health data you choose to share\n• Content preferences and interactions",
  "@legalPrivacySection1Content": {},

  "legalPrivacySection2Title": "2. Data use",
  "@legalPrivacySection2Title": {},

  "legalPrivacySection2Content": "Your data allows us to:\n\n• Personalize your recipe recommendations\n• Continuously improve our service\n• Send you relevant notifications\n• Ensure the security of your account",
  "@legalPrivacySection2Content": {},

  "legalPrivacySection3Title": "3. Your GDPR rights",
  "@legalPrivacySection3Title": {},

  "legalPrivacyRightAccess": "Access",
  "@legalPrivacyRightAccess": {},

  "legalPrivacyRightAccessDesc": "View your data",
  "@legalPrivacyRightAccessDesc": {},

  "legalPrivacyRightRectification": "Rectification",
  "@legalPrivacyRightRectification": {},

  "legalPrivacyRightRectificationDesc": "Modify your information",
  "@legalPrivacyRightRectificationDesc": {},

  "legalPrivacyRightErasure": "Erasure",
  "@legalPrivacyRightErasure": {},

  "legalPrivacyRightErasureDesc": "Delete your account",
  "@legalPrivacyRightErasureDesc": {},

  "legalPrivacyRightPortability": "Portability",
  "@legalPrivacyRightPortability": {},

  "legalPrivacyRightPortabilityDesc": "Export your data",
  "@legalPrivacyRightPortabilityDesc": {},

  "legalPrivacySection4Title": "4. Data sharing",
  "@legalPrivacySection4Title": {},

  "legalPrivacySection4Content": "We never sell your personal data.\n\nIt may only be shared with:\n• Our technical providers hosted in the EU\n• Legal authorities if required by law\n• Your favourite creators (only with your explicit consent)",
  "@legalPrivacySection4Content": {},

  "legalPrivacySection5Title": "5. Retention",
  "@legalPrivacySection5Title": {},

  "legalPrivacySection5Content": "Your data is retained:\n• As long as your account is active\n• Up to 3 years after your last login\n• Immediately deleted upon account deletion request",
  "@legalPrivacySection5Content": {},

  "legalPrivacyDpoTitle": "DPO Contact",
  "@legalPrivacyDpoTitle": {},

  "legalPrivacyDpoEmail": "dpo@akeli.app",
  "@legalPrivacyDpoEmail": {},

  "legalPrivacyDpoDesc": "Our data protection officer responds within 48 business hours to any request regarding your personal data.",
  "@legalPrivacyDpoDesc": {},

  "legalPrivacyVersion": "Version 1.0 • Last updated: January 2026",
  "@legalPrivacyVersion": {},

  "legalTermsTitle": "Terms of Service",
  "@legalTermsTitle": {},

  "legalTermsHeroTitle": "Welcome to Akeli",
  "@legalTermsHeroTitle": {},

  "legalTermsHeroSubtitle": "By using our app, you accept these terms",
  "@legalTermsHeroSubtitle": {},

  "legalTermsArticle1Title": "Access to service",
  "@legalTermsArticle1Title": {},

  "legalTermsArticle1Content": "Akeli is a free mobile app dedicated to African nutrition and traditional recipes.\n\nAccess to the service requires:\n• A compatible iOS or Android smartphone\n• An internet connection to sync data\n• Creating a user account\n\nCertain premium features (Fan Mode, personalized plans) are available via subscription.",
  "@legalTermsArticle1Content": {},

  "legalTermsArticle2Title": "User account",
  "@legalTermsArticle2Title": {},

  "legalTermsArticle2Content": "You are responsible for:\n• The confidentiality of your credentials\n• The accuracy of the information provided\n• All activities carried out from your account\n\nWe reserve the right to suspend or delete any account that violates these terms.",
  "@legalTermsArticle2Content": {},

  "legalTermsArticle3Title": "Intellectual property",
  "@legalTermsArticle3Title": {},

  "legalTermsArticle3Content": "All content on Akeli (recipes, texts, images, logos) is the exclusive property of Akeli or its partners.\n\nProhibited:\n• Reproduction without authorization\n• Unauthorized commercial use\n• Modification or alteration of content\n\nCreators retain rights to their published recipes.",
  "@legalTermsArticle3Content": {},

  "legalTermsArticle4Title": "Liability",
  "@legalTermsArticle4Title": {},

  "legalTermsArticle4Content": "Akeli provides nutritional information for informational purposes only.\n\nWe cannot be held responsible for:\n• Errors in nutritional information\n• Allergic reactions or health problems related to recipes\n• Temporary service interruptions for maintenance\n\nAlways consult a healthcare professional for medical advice.",
  "@legalTermsArticle4Content": {},

  "legalTermsArticle5Title": "Subscriptions and payments",
  "@legalTermsArticle5Title": {},

  "legalTermsArticle5Content": "Fan Mode subscriptions (€3/month) are billed monthly via the stores (Google Play / App Store).\n\n• Cancellation possible at any time\n• Access maintained until the end of the paid period\n• No partial refund\n\nCreators receive 70% of revenue generated by their subscribers.",
  "@legalTermsArticle5Content": {},

  "legalTermsArticle6Title": "Modifications",
  "@legalTermsArticle6Title": {},

  "legalTermsArticle6Content": "We reserve the right to modify these terms at any time.\n\nUsers will be notified:\n• By push notification for major changes\n• By email if the modification impacts personal data\n\nContinued use constitutes acceptance of the new terms.",
  "@legalTermsArticle6Content": {},

  "legalTermsContactTitle": "Contact",
  "@legalTermsContactTitle": {},

  "legalTermsContactEmail": "legal@akeli.app",
  "@legalTermsContactEmail": {},

  "legalTermsVersion": "Version 1.0 • Last updated: January 2026",
  "@legalTermsVersion": {}
```

- [ ] **Step 2: Add same keys to app_fr.arb**

Append before the closing `}`:

```json
  "legalPrivacyTitle": "Politique de Confidentialité",
  "legalPrivacyHeroTitle": "Vos données sont protégées",
  "legalPrivacyHeroSubtitle": "Nous nous engageons à protéger votre vie privée conformément au RGPD",
  "legalPrivacySummaryTitle": "En bref",
  "legalPrivacyCollectionTitle": "Collecte minimale",
  "legalPrivacyCollectionDesc": "Seules les données nécessaires au fonctionnement de l'application",
  "legalPrivacySecurityTitle": "Sécurité maximale",
  "legalPrivacySecurityDesc": "Chiffrement de bout en bout et stockage sécurisé",
  "legalPrivacyControlTitle": "Contrôle total",
  "legalPrivacyControlDesc": "Vous pouvez accéder, modifier ou supprimer vos données à tout moment",
  "legalPrivacySection1Title": "1. Collecte de données",
  "legalPrivacySection1Content": "Nous collectons uniquement les données nécessaires pour vous offrir la meilleure expérience :\n\n• Informations de profil (nom, email, préférences alimentaires)\n• Historique de navigation dans l'application\n• Données de santé que vous choisissez de partager\n• Préférences de contenu et interactions",
  "legalPrivacySection2Title": "2. Utilisation des données",
  "legalPrivacySection2Content": "Vos données nous permettent de :\n\n• Personnaliser vos recommandations de recettes\n• Améliorer continuellement notre service\n• Vous envoyer des notifications pertinentes\n• Assurer la sécurité de votre compte",
  "legalPrivacySection3Title": "3. Vos droits RGPD",
  "legalPrivacyRightAccess": "Accès",
  "legalPrivacyRightAccessDesc": "Consulter vos données",
  "legalPrivacyRightRectification": "Rectification",
  "legalPrivacyRightRectificationDesc": "Modifier vos informations",
  "legalPrivacyRightErasure": "Effacement",
  "legalPrivacyRightErasureDesc": "Supprimer votre compte",
  "legalPrivacyRightPortability": "Portabilité",
  "legalPrivacyRightPortabilityDesc": "Exporter vos données",
  "legalPrivacySection4Title": "4. Partage des données",
  "legalPrivacySection4Content": "Nous ne vendons jamais vos données personnelles.\n\nElles peuvent être partagées uniquement avec :\n• Nos prestataires techniques hébergés en UE\n• Les autorités légales si requis par la loi\n• Vos créateurs favoris (uniquement avec votre consentement explicite)",
  "legalPrivacySection5Title": "5. Conservation",
  "legalPrivacySection5Content": "Vos données sont conservées :\n• Tant que votre compte est actif\n• Jusqu'à 3 ans après votre dernière connexion\n• Immédiatement supprimées après demande de suppression de compte",
  "legalPrivacyDpoTitle": "Contact DPO",
  "legalPrivacyDpoEmail": "dpo@akeli.app",
  "legalPrivacyDpoDesc": "Notre délégué à la protection des données répond sous 48h ouvrées à toute demande concernant vos données personnelles.",
  "legalPrivacyVersion": "Version 1.0 • Dernière mise à jour: Janvier 2026",

  "legalTermsTitle": "Conditions Générales",
  "legalTermsHeroTitle": "Bienvenue sur Akeli",
  "legalTermsHeroSubtitle": "En utilisant notre application, vous acceptez ces conditions",
  "legalTermsArticle1Title": "Accès au service",
  "legalTermsArticle1Content": "Akeli est une application mobile gratuite dédiée à la nutrition africaine et aux recettes traditionnelles.\n\nL'accès au service nécessite :\n• Un smartphone compatible iOS ou Android\n• Une connexion internet pour synchroniser les données\n• La création d'un compte utilisateur\n\nCertaines fonctionnalités premium (Fan Mode, plans personnalisés) sont accessibles via abonnement.",
  "legalTermsArticle2Title": "Compte utilisateur",
  "legalTermsArticle2Content": "Vous êtes responsable de :\n• La confidentialité de vos identifiants\n• L'exactitude des informations fournies\n• Toutes les activités effectuées depuis votre compte\n\nNous nous réservons le droit de suspendre ou supprimer tout compte en cas de violation des présentes conditions.",
  "legalTermsArticle3Title": "Propriété intellectuelle",
  "legalTermsArticle3Content": "Tous les contenus présents sur Akeli (recettes, textes, images, logos) sont la propriété exclusive d'Akeli ou de ses partenaires.\n\nInterdictions :\n• Reproduction sans autorisation\n• Utilisation commerciale non autorisée\n• Modification ou altération des contenus\n\nLes créateurs conservent les droits sur leurs recettes publiées.",
  "legalTermsArticle4Title": "Responsabilité",
  "legalTermsArticle4Content": "Akeli fournit des informations nutritionnelles à titre indicatif uniquement.\n\nNous ne pouvons être tenus responsables :\n• Des erreurs dans les informations nutritionnelles\n• Des réactions allergiques ou problèmes de santé liés aux recettes\n• Des interruptions temporaires du service pour maintenance\n\nConsultez toujours un professionnel de santé pour des conseils médicaux.",
  "legalTermsArticle5Title": "Abonnements et paiements",
  "legalTermsArticle5Content": "Les abonnements Fan Mode (€3/mois) sont facturés mensuellement via les stores (Google Play / App Store).\n\n• Résiliation possible à tout moment\n• Accès maintenu jusqu'à la fin de période payée\n• Aucun remboursement partiel\n\nLes créateurs reçoivent 70% des revenus générés par leurs abonnés.",
  "legalTermsArticle6Title": "Modifications",
  "legalTermsArticle6Content": "Nous nous réservons le droit de modifier ces conditions à tout moment.\n\nLes utilisateurs seront notifiés :\n• Par notification push pour changements majeurs\n• Par email si modification impacte les données personnelles\n\nLa poursuite de l'utilisation vaut acceptation des nouvelles conditions.",
  "legalTermsContactTitle": "Contact",
  "legalTermsContactEmail": "legal@akeli.app",
  "legalTermsVersion": "Version 1.0 • Dernière mise à jour: Janvier 2026"
```

- [ ] **Step 3: Run flutter gen-l10n**

```bash
flutter gen-l10n
```

- [ ] **Step 4: Wire privacy_policy_page.dart**

Add imports:
```dart
import 'package:akeli/l10n/app_localizations.dart';
```

In `build()`, add `final l10n = AppLocalizations.of(context);` at top.

Replace every hardcoded string. The `_buildSectionTitle`, `_buildHighlightCard`, `_buildContentCard`, `_buildRightsCard` helper methods already take `String` parameters — just pass l10n-resolved values at the call sites:

```dart
// AppBar title:
title: Text(l10n.legalPrivacyTitle, ...)

// Hero card:
Text(l10n.legalPrivacyHeroTitle, ...)
Text(l10n.legalPrivacyHeroSubtitle, ...)

// Summary section:
_buildSectionTitle(l10n.legalPrivacySummaryTitle),
_buildHighlightCard(icon: Icons.data_usage_outlined,
  title: l10n.legalPrivacyCollectionTitle,
  description: l10n.legalPrivacyCollectionDesc),
_buildHighlightCard(icon: Icons.lock_outline,
  title: l10n.legalPrivacySecurityTitle,
  description: l10n.legalPrivacySecurityDesc),
_buildHighlightCard(icon: Icons.person_outline,
  title: l10n.legalPrivacyControlTitle,
  description: l10n.legalPrivacyControlDesc),

// Section 1:
_buildSectionTitle(l10n.legalPrivacySection1Title),
_buildContentCard(content: l10n.legalPrivacySection1Content),

// Section 2:
_buildSectionTitle(l10n.legalPrivacySection2Title),
_buildContentCard(content: l10n.legalPrivacySection2Content),

// Section 3 (GDPR rights grid):
_buildSectionTitle(l10n.legalPrivacySection3Title),
// rights cards:
_buildRightsCard(icon: Icons.visibility_outlined,
  title: l10n.legalPrivacyRightAccess,
  description: l10n.legalPrivacyRightAccessDesc),
_buildRightsCard(icon: Icons.edit_outlined,
  title: l10n.legalPrivacyRightRectification,
  description: l10n.legalPrivacyRightRectificationDesc),
_buildRightsCard(icon: Icons.delete_outline,
  title: l10n.legalPrivacyRightErasure,
  description: l10n.legalPrivacyRightErasureDesc),
_buildRightsCard(icon: Icons.download_outlined,
  title: l10n.legalPrivacyRightPortability,
  description: l10n.legalPrivacyRightPortabilityDesc),

// Section 4:
_buildSectionTitle(l10n.legalPrivacySection4Title),
_buildContentCard(content: l10n.legalPrivacySection4Content),

// Section 5:
_buildSectionTitle(l10n.legalPrivacySection5Title),
_buildContentCard(content: l10n.legalPrivacySection5Content),

// DPO contact:
_buildSectionTitle(l10n.legalPrivacyDpoTitle),
// email text:
Text(l10n.legalPrivacyDpoEmail, ...)
Text(l10n.legalPrivacyDpoDesc, ...)

// Version badge:
Text(l10n.legalPrivacyVersion, ...)
```

- [ ] **Step 5: Wire terms_of_service_page.dart**

Add import:
```dart
import 'package:akeli/l10n/app_localizations.dart';
```

In `build()`, add `final l10n = AppLocalizations.of(context);` and replace:

```dart
// AppBar title:
title: Text(l10n.legalTermsTitle, ...)

// Hero card:
Text(l10n.legalTermsHeroTitle, ...)
Text(l10n.legalTermsHeroSubtitle, ...)

// Articles 1–6 (pass to _buildArticleCard which already takes String params):
_buildArticleCard(number: '1', title: l10n.legalTermsArticle1Title, content: l10n.legalTermsArticle1Content),
_buildArticleCard(number: '2', title: l10n.legalTermsArticle2Title, content: l10n.legalTermsArticle2Content),
_buildArticleCard(number: '3', title: l10n.legalTermsArticle3Title, content: l10n.legalTermsArticle3Content),
_buildArticleCard(number: '4', title: l10n.legalTermsArticle4Title, content: l10n.legalTermsArticle4Content),
_buildArticleCard(number: '5', title: l10n.legalTermsArticle5Title, content: l10n.legalTermsArticle5Content),
_buildArticleCard(number: '6', title: l10n.legalTermsArticle6Title, content: l10n.legalTermsArticle6Content),

// Contact section:
_buildSectionTitle(l10n.legalTermsContactTitle),
Text(l10n.legalTermsContactEmail, ...)

// Version badge:
Text(l10n.legalTermsVersion, ...)
```

- [ ] **Step 6: Fix main.dart hardcoded 'Voir'**

In `lib/main.dart`, find the FCM foreground handler block:

```dart
action: SnackBarAction(
  label: 'Voir',
  onPressed: () { ... },
),
```

Replace with:

```dart
action: SnackBarAction(
  label: AppLocalizations.of(rootScaffoldMessengerKey.currentContext!)
      ?.notificationSeeLabel ?? 'View',
  onPressed: () { ... },
),
```

`AppLocalizations` is already imported in `main.dart` (`import 'l10n/app_localizations.dart';`) — no new import needed.

- [ ] **Step 7: Verify**

```bash
flutter analyze
```

Expected: no errors in any of the 3 modified files.

- [ ] **Step 8: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_fr.arb \
  lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart \
  lib/l10n/app_localizations.dart \
  lib/features/legal/privacy_policy_page.dart \
  lib/features/legal/terms_of_service_page.dart \
  lib/main.dart
git commit -m "feat(l10n): retrofit batch 4 — legal pages + main.dart FCM label"
```
