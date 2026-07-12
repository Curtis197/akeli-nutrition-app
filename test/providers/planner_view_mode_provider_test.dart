import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/providers/meal_plan_provider.dart';

void main() {
  group('plannerViewModeProvider', () {
    test('defaults to PlannerViewMode.week', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(plannerViewModeProvider), PlannerViewMode.week);
    });

    test('can be set to PlannerViewMode.day', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(plannerViewModeProvider.notifier).state = PlannerViewMode.day;
      expect(container.read(plannerViewModeProvider), PlannerViewMode.day);
    });
  });
}
