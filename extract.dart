import 'dart:io';

void main() async {
  const planPath = 'docs/superpowers/plans/2026-07-23-beauty-fix-e-models-providers.md';
  final content = await File(planPath).readAsString();

  // Task 5 test
  final test5Regex = RegExp(r'Extend `test/providers/beauty_plan_provider_test.dart`.*?\n\s*```dart\n(.*?)```', dotAll: true);
  final test5Match = test5Regex.firstMatch(content);
  if (test5Match != null) {
    await File('test/providers/beauty_plan_provider_test.dart').writeAsString(test5Match.group(1)!);
    print('Wrote Task 5 test');
  }

  // Task 5 lib
  final lib5Regex = RegExp(r'Replace the full content of `lib/providers/beauty_plan_provider.dart` with:.*?\n\s*```dart\n(.*?)```', dotAll: true);
  final lib5Match = lib5Regex.firstMatch(content);
  if (lib5Match != null) {
    await File('lib/providers/beauty_plan_provider.dart').writeAsString(lib5Match.group(1)!);
    print('Wrote Task 5 lib');
  }

  // Task 6 test
  final test6Regex = RegExp(r'Write the regression test.*Create `test/providers/user_profile_provider_test.dart`:.*?\n\s*```dart\n(.*?)```', dotAll: true);
  final test6Match = test6Regex.firstMatch(content);
  if (test6Match != null) {
    await File('test/providers/user_profile_provider_test.dart').writeAsString(test6Match.group(1)!);
    print('Wrote Task 6 test');
  }

  // Task 6 lib
  final lib6Regex = RegExp(r'Replace the body of `completeBeautyOnboarding`.*?\n\s*```dart\n(.*?)```', dotAll: true);
  final lib6Match = lib6Regex.firstMatch(content);
  if (lib6Match != null) {
    final lib6Content = await File('lib/providers/user_profile_provider.dart').readAsString();
    final newLib6Content = lib6Content.replaceFirst(
      RegExp(r'  Future<void> completeBeautyOnboarding\({.*?^  }', multiLine: true, dotAll: true),
      lib6Match.group(1)!
    );
    await File('lib/providers/user_profile_provider.dart').writeAsString(newLib6Content);
    print('Wrote Task 6 lib');
  }
}
