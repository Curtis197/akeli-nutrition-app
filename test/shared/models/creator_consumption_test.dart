import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/creator.dart';

void main() {
  group('CreatorConsumption', () {
    test('fromAggregated maps all fields', () {
      final c = CreatorConsumption.fromAggregated(
        creatorId: 'c-1',
        creatorName: 'Amara Diallo',
        avatarUrl: 'https://example.com/avatar.jpg',
        count: 12,
        totalMeals: 20,
      );

      expect(c.creatorId, 'c-1');
      expect(c.creatorName, 'Amara Diallo');
      expect(c.avatarUrl, 'https://example.com/avatar.jpg');
      expect(c.count, 12);
      expect(c.pct, closeTo(0.6, 0.001));
    });

    test('avatarUrl is nullable', () {
      final c = CreatorConsumption.fromAggregated(
        creatorId: 'c-2',
        creatorName: 'Kofi',
        avatarUrl: null,
        count: 5,
        totalMeals: 10,
      );
      expect(c.avatarUrl, isNull);
    });

    test('pct is 0.0 when totalMeals is 0', () {
      final c = CreatorConsumption.fromAggregated(
        creatorId: 'c-3',
        creatorName: 'Fatou',
        avatarUrl: null,
        count: 0,
        totalMeals: 0,
      );
      expect(c.pct, 0.0);
    });
  });
}
