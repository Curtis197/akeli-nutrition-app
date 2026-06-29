// test/core/quantity_formatter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/core/quantity_formatter.dart';

void main() {
  group('formatQuantity — weight/volume (non-countable)', () {
    test('whole grams shows as integer with space', () {
      expect(formatQuantity(235, 'g'), '235 g');
    });
    test('whole ml shows as integer with space', () {
      expect(formatQuantity(250, 'ml'), '250 ml');
    });
    test('decimal litre shows 1dp with space', () {
      expect(formatQuantity(0.2, 'l'), '0.2 l');
    });
    test('decimal kg shows 1dp with space', () {
      expect(formatQuantity(0.1, 'kg'), '0.1 kg');
    });
  });

  group('formatQuantity — countable units (fractions)', () {
    test('0.5 unit shows as 1/2 (no suffix)', () {
      expect(formatQuantity(0.5, 'unit'), '1/2');
    });
    test('1.5 unit shows as 1 1/2 (no suffix)', () {
      expect(formatQuantity(1.5, 'unit'), '1 1/2');
    });
    test('1.0 unit shows as integer (no suffix)', () {
      expect(formatQuantity(1.0, 'unit'), '1');
    });
    test('2.0 unit shows as integer (no suffix)', () {
      expect(formatQuantity(2.0, 'unit'), '2');
    });
    test('0.25 tsp shows as 1/4 c.à.c', () {
      expect(formatQuantity(0.25, 'tsp'), '1/4 c.à.c');
    });
    test('0.75 tsp shows as 3/4 c.à.c', () {
      expect(formatQuantity(0.75, 'tsp'), '3/4 c.à.c');
    });
    test('0.667 tsp shows as 2/3 c.à.c', () {
      expect(formatQuantity(0.667, 'tsp'), '2/3 c.à.c');
    });
    test('0.5 tbsp shows as 1/2 c.à.s', () {
      expect(formatQuantity(0.5, 'tbsp'), '1/2 c.à.s');
    });
    test('1.25 tsp shows as 1 1/4 c.à.c', () {
      expect(formatQuantity(1.25, 'tsp'), '1 1/4 c.à.c');
    });
    test('whole clove plural shows as integer with gousses', () {
      expect(formatQuantity(2.0, 'clove'), '2 gousses');
    });
    test('singular clove shows as gousse', () {
      expect(formatQuantity(1.0, 'clove'), '1 gousse');
    });
    test('0.5 pinch shows as 1/2 pincée', () {
      expect(formatQuantity(0.5, 'pinch'), '1/2 pincée');
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
    test('tsp suffix shows French abbreviation', () {
      expect(formatQuantity(0.5, 'tsp'), '1/2 c.à.c');
    });
  });

  group('formatQuantity — US/Imperial (en-US locale)', () {
    test('fl_oz formats as fraction with fl oz suffix', () {
      expect(formatQuantity(0.5, 'fl_oz', locale: 'en-US'), '1/2 fl oz');
      expect(formatQuantity(1.5, 'fl_oz', locale: 'en-US'), '1 1/2 fl oz');
    });
    test('oz formats as fraction with oz suffix', () {
      expect(formatQuantity(0.25, 'oz', locale: 'en-US'), '1/4 oz');
      expect(formatQuantity(1.75, 'oz', locale: 'en-US'), '1 3/4 oz');
    });
    test('lb formats as decimal with lb suffix', () {
      expect(formatQuantity(1.0, 'lb', locale: 'en-US'), '1 lb');
      expect(formatQuantity(1.25, 'lb', locale: 'en-US'), '1.25 lb');
      expect(formatQuantity(1.5, 'lb', locale: 'en-US'), '1.5 lb');
    });
    test('automatically converts metric g to oz/lb when locale is en-US', () {
      // 200g < 500g -> oz. 200 / 28.3495 = 7.054 -> rounds to 7.0 oz
      expect(formatQuantity(200.0, 'g', locale: 'en-US'), '7 oz');
      // 500g >= 500g -> lb. 500 / 453.592 = 1.102 -> rounds to 1.0 lb
      expect(formatQuantity(500.0, 'g', locale: 'en-US'), '1 lb');
    });
    test('automatically converts metric ml to fl_oz/tbsp/tsp when locale is en-US', () {
      // 250ml -> fl_oz. 250 / 29.5735 = 8.453 -> rounds to 8.5 fl_oz -> 8 1/2 fl_oz
      expect(formatQuantity(250.0, 'ml', locale: 'en-US'), '8 1/2 fl oz');
      // 15ml -> tbsp. 15 / 15 = 1.0 tbsp
      expect(formatQuantity(15.0, 'ml', locale: 'en-US'), '1 tbsp');
      // 5ml -> tsp. 5 / 5 = 1.0 tsp
      expect(formatQuantity(5.0, 'ml', locale: 'en-US'), '1 tsp');
    });
    test('automatically converts metric l/kg when locale is en-US', () {
      // 1kg -> 2.20462 lb -> rounds to 2.25 lb
      expect(formatQuantity(1.0, 'kg', locale: 'en-US'), '2.25 lb');
      // 1l -> 4.227 cup -> rounds to 4.25 cup
      expect(formatQuantity(1.0, 'l', locale: 'en-US'), '4 1/4 cup');
    });
  });

  group('formatQuantity — non-matching fraction fallback', () {
    test('non-matching fraction formats as standard decimal', () {
      expect(formatQuantity(4.8, 'unit'), '4.8');
      expect(formatQuantity(1.18, 'tsp'), '1.2 c.à.c');
    });
  });
}
