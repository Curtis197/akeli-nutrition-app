import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/providers/fan_mode_provider.dart';
import 'package:akeli/shared/models/creator.dart';

void main() {
  group('aggregateConsumption', () {
    final creators = {
      'c-1': Creator(
        id: 'c-1', userId: 'u-1', displayName: 'Amara', avatarUrl: 'https://x.com/a.jpg',
        specialties: [], recipeCount: 40, fanCount: 10,
        isFanEligible: true, isMyFanCreator: false, averageRating: 4.5,
      ),
      'c-2': Creator(
        id: 'c-2', userId: 'u-2', displayName: 'Kofi', avatarUrl: null,
        specialties: [], recipeCount: 35, fanCount: 5,
        isFanEligible: true, isMyFanCreator: false, averageRating: 4.0,
      ),
    };

    test('aggregates rows by creator_id and sorts by count desc', () {
      final rows = [
        {'creator_id': 'c-1'},
        {'creator_id': 'c-2'},
        {'creator_id': 'c-1'},
        {'creator_id': 'c-1'},
      ];

      final result = aggregateConsumption(rows, creators);

      expect(result.length, 2);
      expect(result[0].creatorId, 'c-1');
      expect(result[0].count, 3);
      expect(result[0].pct, closeTo(0.75, 0.001));
      expect(result[1].creatorId, 'c-2');
      expect(result[1].count, 1);
      expect(result[1].pct, closeTo(0.25, 0.001));
    });

    test('returns empty list when rows is empty', () {
      final result = aggregateConsumption([], creators);
      expect(result, isEmpty);
    });

    test('skips rows whose creator_id is not in creatorMap', () {
      final rows = [
        {'creator_id': 'c-1'},
        {'creator_id': 'c-unknown'},
      ];
      final result = aggregateConsumption(rows, creators);
      expect(result.length, 1);
      expect(result[0].creatorId, 'c-1');
    });
  });
}
