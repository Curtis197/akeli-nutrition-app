import subprocess
import os

def run_cmd(cmd):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True, encoding="utf-8")
    return result.stdout.strip()

print("=== TASK 12: Final end-to-end re-verification ===")
files = run_cmd("git diff --name-only origin/main...sdui -- \"*.dart\" \"*.ts\" | findstr /V /B \"test/\"")
files_list = [f for f in files.split('\n') if f]
print(f"Total non-test files: {len(files_list)}")

zero_log = 0
for f in files_list:
    if os.path.exists(f):
        content = open(f, 'r', encoding='utf-8', errors='ignore').read()
        logger_count = content.count("appLogger.") + content.count("_logger.") + content.count("createLogger(") + content.count("logRLSCheck(") + content.count("logQueryResult(")
        if logger_count == 0:
            zero_log += 1
            print(f"ZERO-LOG: {f}")

print(f"Total zero log files: {zero_log}")

arb_diff = run_cmd("git diff --stat origin/main...sdui -- lib/l10n/app_en.arb lib/l10n/app_fr.arb")
print("ARB diff:\n" + arb_diff)

print("\n=== TASK 8: Area F ===")
ui_files = [
    "lib/features/beauty/beauty_analytics_page.dart",
    "lib/features/beauty/beauty_onboarding_page.dart",
    "lib/features/beauty/widgets/beauty_checkin_sheet.dart",
    "lib/features/beauty/widgets/today_beauty_routines_widget.dart",
    "lib/features/meal_planner/widgets/beauty_planner_view.dart",
    "lib/shared/widgets/color_set_modal.dart",
    "lib/widgets/mode_selector.dart"
]
for f in ui_files:
    if os.path.exists(f):
        content = open(f, 'r', encoding='utf-8', errors='ignore').read()
        l10n_calls = content.count("AppLocalizations") + content.count("l10n.")
        logger_calls = content.count("appLogger.") + content.count("_logger.")
        print(f"{f}: l10n={l10n_calls}, logger={logger_calls}")

content_mode = open("lib/widgets/mode_selector.dart", "r", encoding="utf-8", errors="ignore").read()
for s in ["'Fermer'", "'Basculer entre Nutrition et Beauté'", "'Passé en mode"]:
    if s in content_mode:
        print(f"Found hardcoded string {s} in mode_selector.dart")

content_color = open("lib/shared/widgets/color_set_modal.dart", "r", encoding="utf-8", errors="ignore").read()
for s in ["'Teal & Amber (Nutrition)'", "'Rose & Gold (Beauty)'", "'Personnaliser le Thème de Couleurs'"]:
    if s in content_color:
        print(f"Found hardcoded string {s} in color_set_modal.dart")

print("\n=== TASK 9: Area G ===")
content_main = open("lib/shared/widgets/main_shell.dart", "r", encoding="utf-8", errors="ignore").read()
for s in ["'Routines'", "'Remèdes'"]:
    if s in content_main:
        print(f"Found hardcoded string {s} in main_shell.dart")
print(f"main_shell.dart logger calls: {content_main.count('appLogger.') + content_main.count('_logger.')}")

content_dyn = open("lib/core/sdui/widgets/dynamic_layout_page.dart", "r", encoding="utf-8", errors="ignore").read()
for s in ["'Unable to load layout'", "'Unknown error'", "'Try Again'", "'No content for", "'Check back later"]:
    if s in content_dyn:
        print(f"Found hardcoded string {s} in dynamic_layout_page.dart")

print("\n=== TASK 10: Area H ===")
area_h_files = [
    "lib/features/ai_assistant/ai_chat_page.dart", "lib/features/auth/onboarding_data.dart",
    "lib/features/auth/onboarding_page.dart", "lib/features/community/community_page.dart",
    "lib/features/home/home_page.dart", "lib/features/meal_planner/batch_cooking_page.dart",
    "lib/features/meal_planner/meal_planner_page.dart", "lib/features/meal_planner/shopping_list_page.dart",
    "lib/features/meal_planner/widgets/meal_planner_view_toggle.dart", "lib/features/nutrition/nutrition_page.dart",
    "lib/features/nutrition_plan/nutrition_plan_page.dart", "lib/features/profile/profile_page.dart",
    "lib/features/recipes/feed_page.dart", "lib/features/recipes/saved_recipes_page.dart",
    "lib/features/settings/health_profile_page.dart", "lib/features/settings/meal_schedule_page.dart",
    "lib/features/settings/preferences_page.dart", "lib/features/settings/settings_page.dart",
    "lib/features/support/support_page.dart"
]
for f in area_h_files:
    diff = run_cmd(f"git diff origin/main...sdui -- {f}")
    added_lines = [l for l in diff.split('\n') if l.startswith('+') and not l.startswith('+++')]
    hardcoded = [l for l in added_lines if "Text(" in l and ("'" in l or '"' in l)] # heuristic
    print(f"{f}: added diff lines={len(added_lines)}, potential hardcoded lines={len(hardcoded)}")

print("\n=== Task 6: Area C ===")
f_c_onb = "supabase/functions/complete-beauty-onboarding/index.ts"
content_c = open(f_c_onb, "r", encoding="utf-8", errors="ignore").read() if os.path.exists(f_c_onb) else ""
print("logRLSCheck:", content_c.count("logRLSCheck("))
print("logQueryResult:", content_c.count("logQueryResult("))
print("stack:", content_c.count("stack: e.stack"))

f_c_cron = "supabase/functions/compute-monthly-beauty-revenue/index.ts"
content_cron = open(f_c_cron, "r", encoding="utf-8", errors="ignore").read() if os.path.exists(f_c_cron) else ""
print("cron exists:", os.path.exists(f_c_cron))
print("cron logging calls:", content_cron.count("createLogger(") + content_cron.count("logRLSCheck(") + content_cron.count("logQueryResult(") + content_cron.count("ENTRY") + content_cron.count("EXIT"))

print("\n=== Task 7: Area E ===")
content_bp = open("lib/providers/beauty_plan_provider.dart", "r", encoding="utf-8", errors="ignore").read()
print("beauty_plan_provider.dart logger:", content_bp.count("appLogger.provider("))
print("beauty_plan_provider.dart dispose:", content_bp.count("onDispose"))
print("beauty_plan_provider.dart BEFORE:", content_bp.count("BEFORE "))
print("beauty_plan_provider.dart AFTER:", content_bp.count("AFTER "))

content_up = open("lib/providers/user_profile_provider.dart", "r", encoding="utf-8", errors="ignore").read()
print("AFTER | success:", content_up.count("AFTER | success"))
print("BEFORE rpc:", content_up.count("BEFORE rpc | fn: complete_beauty_onboarding"))
print("RLS block note:", content_up.count("possible RLS block on post-onboarding re-fetch"))

content_mode = open("lib/providers/mode_provider.dart", "r", encoding="utf-8", errors="ignore").read()
for s in ["'Nutrition'", "'Beauté'", "'Santé'", "'Sport'", "'Famille'"]:
    if s in content_mode:
        print(f"Found hardcoded string {s} in mode_provider.dart")
