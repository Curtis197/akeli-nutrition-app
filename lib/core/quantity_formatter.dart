// lib/core/quantity_formatter.dart
import 'package:collection/collection.dart';

// Units rendered as fractions (1/2, 1/4 etc.) rather than plain decimals.
const _countableUnits = {
  'unit', 'piece', 'clove', 'bunch', 'can', 'pot', 'tsp', 'tbsp', 'pinch',
};

// Units whose label is suppressed in output (e.g. "1/2" not "1/2 unit").
const _silentUnits = {'unit', 'piece'};

// Decimal value → fraction string. Tolerance for floating-point comparison: ±0.01.
final _fractionMap = <double, String>{
  0.25: '1/4',
  0.333: '1/3',
  0.5:   '1/2',
  0.667: '2/3',
  0.75:  '3/4',
};

/// Format a scaled ingredient quantity for display.
///
/// Non-countable units (g, ml, kg, l): plain decimal, integer if whole.
/// Countable units (unit, tsp, etc.): decimal part rendered as fraction.
/// Silent units (unit, piece): suffix omitted.
String formatQuantity(double qty, String unit) {
  if (!_countableUnits.contains(unit)) {
    if (qty % 1 == 0) return '${qty.toInt()}$unit';
    return '${qty.toStringAsFixed(1)}$unit';
  }

  final suffix = _silentUnits.contains(unit) ? '' : ' $unit';
  final whole = qty.floor();
  final decimal = qty - whole;

  if (decimal < 0.01) return '$whole$suffix'.trim();

  final entry = _fractionMap.entries.firstWhereOrNull(
    (e) => (e.key - decimal).abs() < 0.01,
  );
  final fractionStr = entry?.value ?? qty.toStringAsFixed(2);

  if (whole == 0) return '$fractionStr$suffix'.trim();
  return '$whole $fractionStr$suffix'.trim();
}
