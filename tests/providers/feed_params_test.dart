import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/providers/recipe_provider.dart';

void main() {
  group('FeedParams.hasFilters', () {
    test('returns false when no filters set', () {
      const p = FeedParams(limit: 20);
      expect(p.hasFilters, isFalse);
    });

    test('returns true when regionId set', () {
      const p = FeedParams(limit: 20, regionId: 'west_africa');
      expect(p.hasFilters, isTrue);
    });

    test('returns true when difficulty set', () {
      const p = FeedParams(limit: 20, difficulty: 'easy');
      expect(p.hasFilters, isTrue);
    });

    test('returns true when maxTimeMin set', () {
      const p = FeedParams(limit: 20, maxTimeMin: 30);
      expect(p.hasFilters, isTrue);
    });

    test('returns true when orderBy set', () {
      const p = FeedParams(limit: 20, orderBy: 'rating');
      expect(p.hasFilters, isTrue);
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
