// lib/core/unit_converter.dart

class UnitConverter {
  static double _roundTo(double val, double step) {
    if (step == 0) return val;
    return (val / step).round() * step;
  }

  /// Convert a metric quantity and unit to US/Imperial.
  static ({double quantity, String unit}) toImperial(double qty, String unit) {
    final u = unit.toLowerCase().trim();
    switch (u) {
      case 'g':
        if (qty < 500) {
          return (
            quantity: _roundTo(qty / 28.3495, 0.25),
            unit: 'oz',
          );
        } else {
          return (
            quantity: _roundTo(qty / 453.592, 0.25),
            unit: 'lb',
          );
        }
      case 'kg':
        return (
          quantity: _roundTo(qty * 2.20462, 0.25),
          unit: 'lb',
        );
      case 'ml':
        if (qty < 15) {
          return (
            quantity: _roundTo(qty / 5.0, 0.25),
            unit: 'tsp',
          );
        } else if (qty < 60) {
          return (
            quantity: _roundTo(qty / 15.0, 0.5),
            unit: 'tbsp',
          );
        } else {
          return (
            quantity: _roundTo(qty / 29.5735, 0.5),
            unit: 'fl_oz',
          );
        }
      case 'l':
        if (qty > 0.5) {
          return (
            quantity: _roundTo(qty * 4.227, 0.25),
            unit: 'cup',
          );
        } else {
          return (
            quantity: _roundTo(qty * 33.814, 0.5),
            unit: 'fl_oz',
          );
        }
      default:
        // Pass-through: tsp, tbsp, cup, piece, clove, bunch, can, pot, pinch, unit, oz, lb, fl_oz
        return (quantity: qty, unit: unit);
    }
  }

  /// Body weight display helpers — 1 decimal precision, no step rounding.
  static double kgToLb(double kg) => double.parse((kg * 2.20462).toStringAsFixed(1));
  static double lbToKg(double lb) => double.parse((lb / 2.20462).toStringAsFixed(1));

  /// Convert a US/Imperial quantity and unit back to metric (for saving).
  static ({double quantity, String unit}) toMetric(double qty, String unit) {
    final u = unit.toLowerCase().trim();
    switch (u) {
      case 'oz':
        return (quantity: qty * 28.3495, unit: 'g');
      case 'lb':
        return (quantity: qty * 453.592, unit: 'g');
      case 'fl_oz':
        return (quantity: qty * 29.5735, unit: 'ml');
      default:
        return (quantity: qty, unit: unit);
    }
  }
}
