// test/core/date_utils_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/core/date_utils.dart';

void main() {
  group('isFutureMeal', () {
    test('returns true for tomorrow', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(isFutureMeal(tomorrow), isTrue);
    });

    test('returns false for today', () {
      final today = DateTime.now();
      expect(isFutureMeal(today), isFalse);
    });

    test('returns false for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(isFutureMeal(yesterday), isFalse);
    });

    test('returns false for today with a late time component', () {
      final now = DateTime.now();
      final todayLate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      expect(isFutureMeal(todayLate), isFalse);
    });

    test('returns true for a date far in the future', () {
      final future = DateTime.now().add(const Duration(days: 30));
      expect(isFutureMeal(future), isTrue);
    });
  });
}
