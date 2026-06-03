// test/core/quantity_formatter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/core/quantity_formatter.dart';

void main() {
  group('formatQuantity — weight/volume (non-countable)', () {
    test('whole grams shows as integer', () {
      expect(formatQuantity(235, 'g'), '235g');
    });
    test('whole ml shows as integer', () {
      expect(formatQuantity(250, 'ml'), '250ml');
    });
    test('decimal litre shows 1dp', () {
      expect(formatQuantity(0.2, 'l'), '0.2l');
    });
    test('decimal kg shows 1dp', () {
      expect(formatQuantity(0.1, 'kg'), '0.1kg');
    });
  });

  group('formatQuantity — countable units (fractions)', () {
    test('0.5 unit shows as 1/2', () {
      expect(formatQuantity(0.5, 'unit'), '1/2');
    });
    test('1.5 unit shows as 1 1/2', () {
      expect(formatQuantity(1.5, 'unit'), '1 1/2');
    });
    test('1.0 unit shows as integer', () {
      expect(formatQuantity(1.0, 'unit'), '1');
    });
    test('2.0 unit shows as integer', () {
      expect(formatQuantity(2.0, 'unit'), '2');
    });
    test('0.25 tsp shows as 1/4 tsp', () {
      expect(formatQuantity(0.25, 'tsp'), '1/4 tsp');
    });
    test('0.75 tsp shows as 3/4 tsp', () {
      expect(formatQuantity(0.75, 'tsp'), '3/4 tsp');
    });
    test('0.5 tbsp shows as 1/2 tbsp', () {
      expect(formatQuantity(0.5, 'tbsp'), '1/2 tbsp');
    });
    test('1.25 tsp shows as 1 1/4 tsp', () {
      expect(formatQuantity(1.25, 'tsp'), '1 1/4 tsp');
    });
    test('whole clove shows as integer with suffix', () {
      expect(formatQuantity(2.0, 'clove'), '2 clove');
    });
    test('0.5 pinch shows as 1/2 pinch', () {
      expect(formatQuantity(0.5, 'pinch'), '1/2 pinch');
    });
  });

  group('formatQuantity — unit suffix rules', () {
    test('"unit" suffix hidden', () {
      expect(formatQuantity(1.0, 'unit'), '1');
      expect(formatQuantity(0.5, 'unit'), '1/2');
    });
    test('"piece" suffix hidden', () {
      expect(formatQuantity(1.0, 'piece'), '1');
      expect(formatQuantity(0.5, 'piece'), '1/2');
    });
    test('tsp suffix shown', () {
      expect(formatQuantity(0.5, 'tsp'), '1/2 tsp');
    });
  });
}
