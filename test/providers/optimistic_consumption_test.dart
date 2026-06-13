import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/providers/meal_plan_provider.dart';

void main() {
  group('optimisticConsumptionProvider', () {
    test('starts empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(optimisticConsumptionProvider), isEmpty);
    });

    test('sets override for an entry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(optimisticConsumptionProvider.notifier)
          .update((map) => {...map, 'entry-1': true});
      expect(container.read(optimisticConsumptionProvider)['entry-1'], isTrue);
    });

    test('reverts override on simulated error', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(optimisticConsumptionProvider.notifier)
          .update((map) => {...map, 'entry-1': true});
      // Simulate revert
      container.read(optimisticConsumptionProvider.notifier)
          .update((map) => {...map, 'entry-1': false});
      expect(container.read(optimisticConsumptionProvider)['entry-1'], isFalse);
    });

    test('clears override after success', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(optimisticConsumptionProvider.notifier)
          .update((map) => {...map, 'entry-1': true});
      container.read(optimisticConsumptionProvider.notifier)
          .update((map) => {...map}..remove('entry-1'));
      expect(container.read(optimisticConsumptionProvider).containsKey('entry-1'), isFalse);
    });
  });

  group('effective isConsumed merge', () {
    test('overlay takes precedence over db value', () {
      const dbIsConsumed = false;
      final overrides = {'entry-1': true};
      final effective = overrides['entry-1'] ?? dbIsConsumed;
      expect(effective, isTrue);
    });

    test('falls back to db value when no override exists', () {
      const dbIsConsumed = true;
      final overrides = <String, bool>{};
      final effective = overrides['entry-1'] ?? dbIsConsumed;
      expect(effective, isTrue);
    });

    test('overlay false overrides db true', () {
      const dbIsConsumed = true;
      final overrides = {'entry-1': false};
      final effective = overrides['entry-1'] ?? dbIsConsumed;
      expect(effective, isFalse);
    });
  });
}
