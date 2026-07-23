#!/bin/bash
cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"

echo "=== TASK 12: Final end-to-end re-verification ==="
git diff --name-only origin/main...sdui -- '*.dart' '*.ts' | grep -v '^test/' > /tmp/i_files_final.txt
zero_log=0
zero_l10n_ui=0
total=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  total=$((total+1))
  logcount=$(grep -cE "appLogger\.|_logger\.|createLogger\(|logRLSCheck\(|logQueryResult\(" "$f" 2>/dev/null || true)
  [ "$logcount" = "0" ] && zero_log=$((zero_log+1)) && echo "ZERO-LOG: $f"
done < /tmp/i_files_final.txt
echo "total=$total zero_log=$zero_log"
git diff --stat origin/main...sdui -- lib/l10n/app_en.arb lib/l10n/app_fr.arb

echo "=== TASK 8: Area F ==="
for f in lib/features/beauty/beauty_analytics_page.dart \
         lib/features/beauty/beauty_onboarding_page.dart \
         lib/features/beauty/widgets/beauty_checkin_sheet.dart \
         lib/features/beauty/widgets/today_beauty_routines_widget.dart \
         lib/features/meal_planner/widgets/beauty_planner_view.dart \
         lib/shared/widgets/color_set_modal.dart \
         lib/widgets/mode_selector.dart; do
  echo "--- $f ---"
  echo "  l10n calls: $(grep -c 'AppLocalizations\|l10n\.' "$f")"
  echo "  logger calls: $(grep -c 'appLogger\.\|_logger\.' "$f")"
done
echo "Specific strings:"
grep -n "'Fermer'\|'Basculer entre Nutrition et Beauté'\|'Passé en mode" lib/widgets/mode_selector.dart || echo "(none)"
grep -n "'Teal & Amber (Nutrition)'\|'Rose & Gold (Beauty)'\|'Personnaliser le Thème de Couleurs'" lib/shared/widgets/color_set_modal.dart || echo "(none)"

echo "=== TASK 9: Area G ==="
grep -n "'Routines'\|'Remèdes'" lib/shared/widgets/main_shell.dart || echo "(none)"
echo "main_shell logger calls: $(grep -c 'appLogger\.\|_logger\.' lib/shared/widgets/main_shell.dart)"
grep -n "'Unable to load layout'\|'Unknown error'\|'Try Again'\|'No content for\|'Check back later" lib/core/sdui/widgets/dynamic_layout_page.dart || echo "(none)"

echo "=== TASK 10: Area H ==="
for f in lib/features/ai_assistant/ai_chat_page.dart lib/features/auth/onboarding_data.dart \
         lib/features/auth/onboarding_page.dart lib/features/community/community_page.dart \
         lib/features/home/home_page.dart lib/features/meal_planner/batch_cooking_page.dart \
         lib/features/meal_planner/meal_planner_page.dart lib/features/meal_planner/shopping_list_page.dart \
         lib/features/meal_planner/widgets/meal_planner_view_toggle.dart lib/features/nutrition/nutrition_page.dart \
         lib/features/nutrition_plan/nutrition_plan_page.dart lib/features/profile/profile_page.dart \
         lib/features/recipes/feed_page.dart lib/features/recipes/saved_recipes_page.dart \
         lib/features/settings/health_profile_page.dart lib/features/settings/meal_schedule_page.dart \
         lib/features/settings/preferences_page.dart lib/features/settings/settings_page.dart \
         lib/features/support/support_page.dart; do
  added_hardcoded=$(git diff origin/main...sdui -- "$f" | grep -E "^\+" | grep -cE "Text\('[A-Za-zÀ-ÿ]| '[A-ZÀ-Ÿ][a-zà-ÿ]+.*'" || true)
  echo "$f: added-hardcoded-string-lines=$added_hardcoded"
done

echo "=== Task 6: Area C ==="
grep -c "logRLSCheck(" supabase/functions/complete-beauty-onboarding/index.ts
grep -c "logQueryResult(" supabase/functions/complete-beauty-onboarding/index.ts
grep -c "stack: e.stack" supabase/functions/complete-beauty-onboarding/index.ts
ls supabase/functions/compute-monthly-beauty-revenue/index.ts 2>&1
grep -c "createLogger(\|logRLSCheck(\|logQueryResult(\|ENTRY\|EXIT" supabase/functions/compute-monthly-beauty-revenue/index.ts 2>/dev/null

echo "=== Task 7: Area E ==="
grep -c "appLogger.provider(" lib/providers/beauty_plan_provider.dart
grep -c "onDispose" lib/providers/beauty_plan_provider.dart
grep -c "BEFORE\b" lib/providers/beauty_plan_provider.dart
grep -c "AFTER\b" lib/providers/beauty_plan_provider.dart
grep -c "AFTER | success" lib/providers/user_profile_provider.dart
grep -c "BEFORE rpc | fn: complete_beauty_onboarding" lib/providers/user_profile_provider.dart
grep -c "possible RLS block on post-onboarding re-fetch" lib/providers/user_profile_provider.dart
grep -n "'Nutrition'\|'Beauté'\|'Santé'\|'Sport'\|'Famille'" lib/providers/mode_provider.dart || echo "(none)"
