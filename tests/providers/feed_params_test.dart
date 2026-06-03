import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/providers/recipe_provider.dart';

void main() {
  group('FeedParams', () {
    test('can be constructed with no filters', () {
      const p = FeedParams(limit: 20);
      expect(p.limit, equals(20));
      expect(p.regionId, isNull);
      expect(p.difficulty, isNull);
      expect(p.maxTimeMin, isNull);
      expect(p.orderBy, isNull);
    });

    test('can set regionId filter', () {
      const p = FeedParams(limit: 20, regionId: 'west_africa');
      expect(p.regionId, equals('west_africa'));
    });

    test('can set difficulty filter', () {
      const p = FeedParams(limit: 20, difficulty: 'easy');
      expect(p.difficulty, equals('easy'));
    });

    test('can set maxTimeMin filter', () {
      const p = FeedParams(limit: 20, maxTimeMin: 30);
      expect(p.maxTimeMin, equals(30));
    });

    test('can set orderBy filter', () {
      const p = FeedParams(limit: 20, orderBy: 'rating');
      expect(p.orderBy, equals('rating'));
    });

    test('equality includes orderBy', () {
      const a = FeedParams(limit: 20, orderBy: 'rating');
      const b = FeedParams(limit: 20, orderBy: 'rating');
      const c = FeedParams(limit: 20, orderBy: 'likes');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
