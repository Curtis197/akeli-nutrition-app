import 'dart:io';

void main() async {
  print('=== TASK 12: Final end-to-end re-verification ===');
  var result = await Process.run('git', ['diff', '--name-only', 'origin/main...sdui', '--', '*.dart', '*.ts']);
  var lines = result.stdout.toString().split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty && !l.startsWith('test/')).toList();
  print('Total non-test files: ${lines.length}');
  
  int zeroLog = 0;
  for (var f in lines) {
    var file = File(f);
    if (file.existsSync()) {
      var content = file.readAsStringSync();
      int count = RegExp(r'appLogger\.|_logger\.|createLogger\(|logRLSCheck\(|logQueryResult\(').allMatches(content).length;
      if (count == 0) {
        zeroLog++;
        print('ZERO-LOG: $f');
      }
    }
  }
  print('Total zero log files: $zeroLog');
  
  var arbDiff = await Process.run('git', ['diff', '--stat', 'origin/main...sdui', '--', 'lib/l10n/app_en.arb', 'lib/l10n/app_fr.arb']);
  print('ARB diff:\n${arbDiff.stdout}');
  
  print('\n=== TASK 8: Area F ===');
  var uiFiles = [
    'lib/features/beauty/beauty_analytics_page.dart',
    'lib/features/beauty/beauty_onboarding_page.dart',
    'lib/features/beauty/widgets/beauty_checkin_sheet.dart',
    'lib/features/beauty/widgets/today_beauty_routines_widget.dart',
    'lib/features/meal_planner/widgets/beauty_planner_view.dart',
    'lib/shared/widgets/color_set_modal.dart',
    'lib/widgets/mode_selector.dart'
  ];
  for (var f in uiFiles) {
    var file = File(f);
    if (file.existsSync()) {
      var content = file.readAsStringSync();
      int l10n = RegExp(r'AppLocalizations|l10n\.').allMatches(content).length;
      int logger = RegExp(r'appLogger\.|_logger\.').allMatches(content).length;
      print('$f: l10n=$l10n, logger=$logger');
    }
  }
  
  var modeContent = File('lib/widgets/mode_selector.dart').existsSync() ? File('lib/widgets/mode_selector.dart').readAsStringSync() : '';
  for (var s in ["'Fermer'", "'Basculer entre Nutrition et Beauté'", "'Passé en mode"]) {
    if (modeContent.contains(s)) print('Found hardcoded string $s in mode_selector.dart');
  }
  
  var colorContent = File('lib/shared/widgets/color_set_modal.dart').existsSync() ? File('lib/shared/widgets/color_set_modal.dart').readAsStringSync() : '';
  for (var s in ["'Teal & Amber (Nutrition)'", "'Rose & Gold (Beauty)'", "'Personnaliser le Thème de Couleurs'"]) {
    if (colorContent.contains(s)) print('Found hardcoded string $s in color_set_modal.dart');
  }
  
  print('\n=== TASK 9: Area G ===');
  var mainContent = File('lib/shared/widgets/main_shell.dart').existsSync() ? File('lib/shared/widgets/main_shell.dart').readAsStringSync() : '';
  for (var s in ["'Routines'", "'Remèdes'"]) {
    if (mainContent.contains(s)) print('Found hardcoded string $s in main_shell.dart');
  }
  print('main_shell.dart logger calls: ${RegExp(r"appLogger\.|_logger\.").allMatches(mainContent).length}');
  
  var dynContent = File('lib/core/sdui/widgets/dynamic_layout_page.dart').existsSync() ? File('lib/core/sdui/widgets/dynamic_layout_page.dart').readAsStringSync() : '';
  for (var s in ["'Unable to load layout'", "'Unknown error'", "'Try Again'", "'No content for", "'Check back later"]) {
    if (dynContent.contains(s)) print('Found hardcoded string $s in dynamic_layout_page.dart');
  }
  
  print('\n=== TASK 10: Area H ===');
  var areaH = [
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
  ];
  for (var f in areaH) {
    var diff = await Process.run('git', ['diff', 'origin/main...sdui', '--', f]);
    var lines = diff.stdout.toString().split('\n').where((l) => l.startsWith('+') && !l.startsWith('+++')).toList();
    var hardcoded = lines.where((l) => l.contains('Text(') && (l.contains("'") || l.contains('"'))).toList();
    print('$f: added diff lines=${lines.length}, potential hardcoded lines=${hardcoded.length}');
  }
  
  print('\n=== Task 6: Area C ===');
  var onbContent = File("supabase/functions/complete-beauty-onboarding/index.ts").existsSync() ? File("supabase/functions/complete-beauty-onboarding/index.ts").readAsStringSync() : "";
  print("logRLSCheck: ${'logRLSCheck('.allMatches(onbContent).length}");
  print("logQueryResult: ${'logQueryResult('.allMatches(onbContent).length}");
  print("stack: ${'stack: e.stack'.allMatches(onbContent).length}");
  
  var cronContent = File("supabase/functions/compute-monthly-beauty-revenue/index.ts").existsSync() ? File("supabase/functions/compute-monthly-beauty-revenue/index.ts").readAsStringSync() : "";
  print("cron exists: ${File("supabase/functions/compute-monthly-beauty-revenue/index.ts").existsSync()}");
  print("cron logging calls: ${RegExp(r'createLogger\(|logRLSCheck\(|logQueryResult\(|ENTRY|EXIT').allMatches(cronContent).length}");
  
  print('\n=== Task 7: Area E ===');
  var bpContent = File("lib/providers/beauty_plan_provider.dart").existsSync() ? File("lib/providers/beauty_plan_provider.dart").readAsStringSync() : "";
  print("beauty_plan_provider.dart logger: ${'appLogger.provider('.allMatches(bpContent).length}");
  print("beauty_plan_provider.dart dispose: ${'onDispose'.allMatches(bpContent).length}");
  print("beauty_plan_provider.dart BEFORE: ${'BEFORE '.allMatches(bpContent).length}");
  print("beauty_plan_provider.dart AFTER: ${'AFTER '.allMatches(bpContent).length}");
  
  var upContent = File("lib/providers/user_profile_provider.dart").existsSync() ? File("lib/providers/user_profile_provider.dart").readAsStringSync() : "";
  print("AFTER | success: ${'AFTER | success'.allMatches(upContent).length}");
  print("BEFORE rpc: ${'BEFORE rpc | fn: complete_beauty_onboarding'.allMatches(upContent).length}");
  print("RLS block note: ${'possible RLS block on post-onboarding re-fetch'.allMatches(upContent).length}");
  
  var modeProvContent = File("lib/providers/mode_provider.dart").existsSync() ? File("lib/providers/mode_provider.dart").readAsStringSync() : "";
  for (var s in ["'Nutrition'", "'Beauté'", "'Santé'", "'Sport'", "'Famille'"]) {
    if (modeProvContent.contains(s)) print('Found hardcoded string $s in mode_provider.dart');
  }
}
