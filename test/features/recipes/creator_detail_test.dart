// test/features/recipes/creator_detail_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/creator.dart';
import 'package:akeli/shared/models/creator_detail.dart';

void main() {
  group('CreatorDetail', () {
    final creator = Creator(
      id: 'c1',
      userId: 'u1',
      displayName: 'Chef Amina',
      specialties: [],
      recipeCount: 5,
      fanCount: 10,
      isFanEligible: false,
      isMyFanCreator: false,
      averageRating: 4.2,
    );

    test('totalLikes and userConsumptionCount are stored correctly', () {
      final detail = CreatorDetail(
        creator: creator,
        totalLikes: 42,
        userConsumptionCount: 3,
        isFan: false,
      );
      expect(detail.totalLikes, 42);
      expect(detail.userConsumptionCount, 3);
      expect(detail.isFan, false);
      expect(detail.creator.displayName, 'Chef Amina');
    });

    test('copyWith isFan updates fan status', () {
      final detail = CreatorDetail(
        creator: creator,
        totalLikes: 42,
        userConsumptionCount: 3,
        isFan: false,
      );
      final updated = detail.copyWith(isFan: true);
      expect(updated.isFan, true);
      expect(updated.totalLikes, 42); // unchanged
    });
  });
}
