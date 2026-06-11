// test/features/recipes/creators_filter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/creator.dart';
import 'package:akeli/features/recipes/feed_page.dart';

Creator _c({
  required String id,
  required String name,
  String? regionId,
  List<String> specialties = const [],
  int fanCount = 0,
  int recipeCount = 0,
  double averageRating = 0.0,
}) =>
    Creator(
      id: id,
      userId: 'u$id',
      displayName: name,
      specialties: specialties,
      recipeCount: recipeCount,
      fanCount: fanCount,
      isFanEligible: false,
      isMyFanCreator: false,
      averageRating: averageRating,
      regionId: regionId,
    );

void main() {
  final creators = [
    _c(id: '1', name: 'Aminata Mbaye', regionId: 'sn', specialties: ['Cuisine traditionnelle'], fanCount: 200, recipeCount: 24, averageRating: 4.8),
    _c(id: '2', name: 'Fatou Konaté',  regionId: 'ml', specialties: ['Cuisine familiale'],      fanCount: 80,  recipeCount: 17, averageRating: 4.2),
    _c(id: '3', name: 'Grace Nkosi',   regionId: 'cm', specialties: ['Cuisine fusion'],          fanCount: 350, recipeCount: 31, averageRating: 4.6),
  ];

  group('filterAndSortCreators', () {
    test('no filters returns all creators in original order', () {
      final result = filterAndSortCreators(creators);
      expect(result.map((c) => c.id).toList(), ['1', '2', '3']);
    });

    test('query filters by displayName case-insensitively', () {
      final result = filterAndSortCreators(creators, query: 'aminata');
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('query with no match returns empty list', () {
      final result = filterAndSortCreators(creators, query: 'zzz');
      expect(result, isEmpty);
    });

    test('regionId filters by regionId', () {
      final result = filterAndSortCreators(creators, regionId: 'ml');
      expect(result.length, 1);
      expect(result.first.id, '2');
    });

    test('specialty filters by specialties list containment', () {
      final result = filterAndSortCreators(creators, specialty: 'Cuisine fusion');
      expect(result.length, 1);
      expect(result.first.id, '3');
    });

    test('orderBy rating sorts descending by averageRating', () {
      final result = filterAndSortCreators(creators, orderBy: 'rating');
      expect(result.map((c) => c.id).toList(), ['1', '3', '2']);
    });

    test('orderBy fans sorts descending by fanCount', () {
      final result = filterAndSortCreators(creators, orderBy: 'fans');
      expect(result.map((c) => c.id).toList(), ['3', '1', '2']);
    });

    test('orderBy recipes sorts descending by recipeCount', () {
      final result = filterAndSortCreators(creators, orderBy: 'recipes');
      expect(result.map((c) => c.id).toList(), ['3', '1', '2']);
    });

    test('combined query + regionId', () {
      final result = filterAndSortCreators(creators, query: 'at', regionId: 'sn');
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('combined query + regionId with no match returns empty', () {
      final result = filterAndSortCreators(creators, query: 'Grace', regionId: 'sn');
      expect(result, isEmpty);
    });
  });
}
