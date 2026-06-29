// test/core/unit_converter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/core/unit_converter.dart';

void main() {
  group('UnitConverter.toImperial', () {
    test('grams < 500 convert to oz', () {
      final res = UnitConverter.toImperial(100, 'g');
      expect(res.unit, 'oz');
      expect(res.quantity, 3.5); // 100 / 28.3495 = 3.527 -> rounded to 0.25 step = 3.5
    });

    test('grams >= 500 convert to lb', () {
      final res = UnitConverter.toImperial(500, 'g');
      expect(res.unit, 'lb');
      expect(res.quantity, 1.0); // 500 / 453.592 = 1.1 -> rounded to 0.25 step = 1.0
    });

    test('kg converts to lb', () {
      final res = UnitConverter.toImperial(1.5, 'kg');
      expect(res.unit, 'lb');
      expect(res.quantity, 3.25); // 1.5 * 2.20462 = 3.306 -> rounded to 0.25 step = 3.25
    });

    test('ml < 15 convert to tsp', () {
      final res = UnitConverter.toImperial(10, 'ml');
      expect(res.unit, 'tsp');
      expect(res.quantity, 2.0); // 10 / 5 = 2.0
    });

    test('ml 15 to 59 convert to tbsp', () {
      final res1 = UnitConverter.toImperial(15, 'ml');
      expect(res1.unit, 'tbsp');
      expect(res1.quantity, 1.0);

      final res2 = UnitConverter.toImperial(30, 'ml');
      expect(res2.unit, 'tbsp');
      expect(res2.quantity, 2.0);
    });

    test('ml >= 60 convert to fl_oz', () {
      final res = UnitConverter.toImperial(100, 'ml');
      expect(res.unit, 'fl_oz');
      expect(res.quantity, 3.5); // 100 / 29.5735 = 3.38 -> rounded to 0.5 step = 3.5
    });

    test('l > 0.5 convert to cup', () {
      final res = UnitConverter.toImperial(1.0, 'l');
      expect(res.unit, 'cup');
      expect(res.quantity, 4.25); // 1.0 * 4.227 = 4.227 -> rounded to 0.25 step = 4.25
    });

    test('l <= 0.5 convert to fl_oz', () {
      final res = UnitConverter.toImperial(0.25, 'l');
      expect(res.unit, 'fl_oz');
      expect(res.quantity, 8.5); // 0.25 * 33.814 = 8.45 -> rounded to 0.5 step = 8.5
    });

    test('other units pass through', () {
      final res = UnitConverter.toImperial(3, 'piece');
      expect(res.unit, 'piece');
      expect(res.quantity, 3.0);
    });
  });

  group('UnitConverter.toMetric', () {
    test('oz converts to g', () {
      final res = UnitConverter.toMetric(10, 'oz');
      expect(res.unit, 'g');
      expect(res.quantity, closeTo(283.495, 0.001));
    });

    test('lb converts to g', () {
      final res = UnitConverter.toMetric(2, 'lb');
      expect(res.unit, 'g');
      expect(res.quantity, closeTo(907.184, 0.001));
    });

    test('fl_oz converts to ml', () {
      final res = UnitConverter.toMetric(8, 'fl_oz');
      expect(res.unit, 'ml');
      expect(res.quantity, closeTo(236.588, 0.001));
    });

    test('other units pass through', () {
      final res = UnitConverter.toMetric(4, 'clove');
      expect(res.unit, 'clove');
      expect(res.quantity, 4.0);
    });
  });

  group('UnitConverter - Body weight conversion', () {
    test('kgToLb and lbToKg preserve precision for 0.1 lb stepping', () {
      const initialKg = 70.0;
      final lb1 = UnitConverter.kgToLb(initialKg);
      expect(lb1, 154.3);

      final lb2 = lb1 + 0.1;
      expect(lb2, 154.4);

      final kg2 = UnitConverter.lbToKg(lb2);
      expect(kg2, 70.035);

      final lb3 = UnitConverter.kgToLb(kg2);
      expect(lb3, 154.4); // Stays at 154.4 instead of rounding down to 154.3!
    });
  });
}
