// lib/core/quantity_formatter.dart
import 'package:collection/collection.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/unit_converter.dart';

final _logger = appLogger;

// Units rendered as fractions (1/2, 1/4 etc.) rather than plain decimals.
const _countableUnits = {
  'unit', 'piece', 'clove', 'bunch', 'can', 'pot', 'tsp', 'tbsp', 'pinch', 'cup',
};

// Translations for units
const _unitTranslations = {
  'clove': 'gousse',
  'bunch': 'botte',
  'can': 'boîte',
  'pot': 'pot',
  'tsp': 'c.à.c',
  'tbsp': 'c.à.s',
  'pinch': 'pincée',
  'unit': '',
  'piece': '',
};

// Decimal value → fraction string. Tolerance for floating-point comparison: ±0.01.
final _fractionMap = <double, String>{
  0.25: '1/4',
  0.333: '1/3',
  0.5:   '1/2',
  0.667: '2/3',
  0.75:  '3/4',
};

/// Rounds ingredient quantities in-app based on category, name, or unit.
double roundIngredientQuantity({
  required double quantity,
  required String unit,
  String? ingredientId,
  String? ingredientName,
}) {
  if (quantity == 0) return 0;

  double? step;
  final u = unit.toLowerCase().trim();

  if (u == 'g') {
    if (ingredientName != null) {
      final nameLower = ingredientName.toLowerCase();
      if (nameLower.contains('riz') || nameLower.contains('rice') ||
          nameLower.contains('couscous') || nameLower.contains('farine') ||
          nameLower.contains('flour') || nameLower.contains('semoule') ||
          nameLower.contains('semolina') || nameLower.contains('atiéké') ||
          nameLower.contains('attieke')) {
        step = 25.0;
      } else if (nameLower.contains('agneau') || nameLower.contains('lamb') ||
                 nameLower.contains('bœuf') || nameLower.contains('beef') ||
                 nameLower.contains('poulet') || nameLower.contains('chicken') ||
                 nameLower.contains('viande') || nameLower.contains('meat') ||
                 nameLower.contains('porc') || nameLower.contains('pork') ||
                 nameLower.contains('merguez') || nameLower.contains('poisson frais') ||
                 nameLower.contains('fresh fish')) {
        step = 50.0;
      } else if (nameLower.contains('crevette') || nameLower.contains('shrimp') ||
                 nameLower.contains('poisson fumé') || nameLower.contains('smoked fish')) {
        step = 25.0;
      } else if (nameLower.contains('bicarbonate') || nameLower.contains('soda') ||
                 nameLower.contains('sel') || nameLower.contains('salt') ||
                 nameLower.contains('muscade') || nameLower.contains('nutmeg') ||
                 nameLower.contains('apki')) {
        step = 1.0;
      } else {
        step = 5.0;
      }
    } else {
      step = 5.0;
    }
  } else if (u == 'ml') {
    step = 5.0;
  } else if (u == 'kg') {
    step = 0.1;
  } else if (u == 'l') {
    step = 0.1;
  } else if (u == 'clove' || u == 'bunch' || u == 'can' || u == 'pot') {
    step = 1.0;
  } else if (u == 'unit' || u == 'piece') {
    bool isWholeOnly = false;
    const wholeOnlyIds = {
      '3a4aa70b-a57b-47ff-bfd0-dcfa39f19938', // Egg
      '47e224bf-e343-4913-b554-dd055ec46b69', // Cube d'assaisonnement
      'd968708f-8577-47e0-ba57-e8df7c86650e', // Bouillon de bœuf
      '56256ed5-4fb7-4c43-b3d4-d63e047a2696', // Bouillon de poulet
      '903f01c4-4773-4b57-85be-34589e9acdb7', // Bay leaves
      '42065998-c8b0-4eff-b804-b18e5039666e', // Cannelle stick
      '20fbc5e5-665c-4037-85cb-4c55951d198c', // Cardamom pod
      'a1b2c3d4-1111-4aaa-8888-000000000003', // Clou de girofle
      '4fad7094-e1dc-4557-a3a1-eb249779bda0', // Thym sprig
      '60c9b4c8-bba7-4986-b297-38a6cfde6613', // Piment oiseau
      '126ab536-b38a-4553-885e-d789b79bc23d', // Piment frais
      '6b64c0ab-f3a3-4a93-9ea6-4dac5367002c', // Piment antillais frais
      '20f9c17c-6f0c-4ea6-9597-421d0b2209be', // Gros piment
      '760e194b-7928-442a-893f-a5171ad33e4a', // Piment sec
      '577f503c-0134-4236-b831-ed70bcd30347', // Yet
      'e44776ac-66a8-46ec-a27d-4f2e51e63fc8', // Poisson fermenté Adjovan
      '3428f263-2d25-4f29-b1ba-c1cd5ee8e357', // Poisson séché Guedj
      'da6a2d9a-de80-4800-b7ef-eeb29a6061f1', // Poisson Thiof
      'ad32a0e5-4882-47cc-8d57-f0d9e7c26704', // Poisson frais
      'ec120eb3-b357-4a3f-8668-4ec08ecca3bd', // Crabe
      '79fbd745-185b-429f-a637-e2e4e00a9fdf', // Thon boite
      '68090810-2346-4808-b319-3fcc5f7e854a', // Saucisse fumée
      'f7690223-9651-42b3-a81b-f284c6fd32ef', // Feuilles de bananier
      '49ab348f-df65-4c4e-bc5a-05239fddd53b', // Navet
    };

    if (ingredientId != null && wholeOnlyIds.contains(ingredientId)) {
      isWholeOnly = true;
    } else if (ingredientName != null) {
      final nameLower = ingredientName.toLowerCase();
      if (nameLower.contains('œuf') || nameLower.contains('egg') ||
          nameLower.contains('cube') || nameLower.contains('bouillon') ||
          nameLower.contains('piment') || nameLower.contains('chili') ||
          nameLower.contains('poisson') || nameLower.contains('fish') ||
          nameLower.contains('thiof') || nameLower.contains('guedj') ||
          nameLower.contains('yet') || nameLower.contains('crabe') ||
          nameLower.contains('crab') || nameLower.contains('saucisse') ||
          nameLower.contains('sausage') || nameLower.contains('navet') ||
          nameLower.contains('turnip') || nameLower.contains('feuille') ||
          nameLower.contains('leaf') || nameLower.contains('leaves') ||
          nameLower.contains('cannelle') || nameLower.contains('cinnamon') ||
          nameLower.contains('gousse') || nameLower.contains('pod') ||
          nameLower.contains('cardamome') || nameLower.contains('cardamom') ||
          nameLower.contains('girofle') || nameLower.contains('clove') ||
          nameLower.contains('thym') || nameLower.contains('thyme') ||
          nameLower.contains('branche') || nameLower.contains('sprig') ||
          nameLower.contains('bâton') || nameLower.contains('stick')) {
        isWholeOnly = true;
      }
    }
    if (isWholeOnly) {
      step = 1.0;
    }
  } else if (u == 'oz' || u == 'lb') {
    step = 0.25;
  } else if (u == 'fl_oz') {
    step = 0.5;
  } else if (u == 'cup') {
    step = 0.25;
  }

  if (step == null) return quantity;

  final rounded = (quantity / step).round() * step;
  return rounded < step ? step : rounded;
}

/// Format a scaled ingredient quantity for display.
///
/// Non-countable units (g, ml, kg, l): plain decimal, integer if whole.
/// Countable units (unit, tsp, etc.): decimal part rendered as fraction.
/// Silent units (unit, piece): suffix omitted.
String formatQuantity(
  double qty,
  String unit, {
  String locale = 'fr',
  String? ingredientId,
  String? ingredientName,
}) {
  var displayQty = qty;
  var displayUnit = unit;

  if (locale == 'en-US') {
    final converted = UnitConverter.toImperial(qty, unit);
    displayQty = converted.quantity;
    displayUnit = converted.unit;
  }

  displayQty = roundIngredientQuantity(
    quantity: displayQty,
    unit: displayUnit,
    ingredientId: ingredientId,
    ingredientName: ingredientName,
  );

  final isFr = locale == 'fr';
  final isPlural = displayQty > 1;

  String translatedUnit;
  if (isFr) {
    translatedUnit = _unitTranslations[displayUnit] ?? displayUnit;
    if (isPlural && const ['gousse', 'botte', 'boîte', 'pot', 'pincée'].contains(translatedUnit)) {
      translatedUnit += 's';
    }
  } else {
    if (displayUnit == 'fl_oz') {
      translatedUnit = 'fl oz';
    } else {
      translatedUnit = displayUnit;
    }
  }

  final isSilent = displayUnit == 'unit' || displayUnit == 'piece';
  final suffix = (isSilent || translatedUnit.isEmpty) ? '' : ' $translatedUnit';

  if (displayUnit == 'lb') {
    if (displayQty % 1 == 0) return '${displayQty.toInt()}$suffix'.trim();
    String s = displayQty.toStringAsFixed(2);
    if (s.endsWith('.00')) {
      s = s.substring(0, s.length - 3);
    } else if (s.endsWith('0')) {
      s = s.substring(0, s.length - 1);
    }
    return '$s$suffix'.trim();
  }

  final countableUnitsExtended = {
    ..._countableUnits,
    'oz',
    'fl_oz',
  };

  if (!countableUnitsExtended.contains(displayUnit)) {
    if (isFr && !_unitTranslations.containsKey(displayUnit)) {
      _logger.provider('formatQuantity | unknown unit: $displayUnit — rendering as-is');
    }
    if (displayQty % 1 == 0) return '${displayQty.toInt()}$suffix'.trim();
    return '${displayQty.toStringAsFixed(1)}$suffix'.trim();
  }

  final whole = displayQty.floor();
  final decimal = displayQty - whole;

  if (decimal < 0.01) return '$whole$suffix'.trim();

  final entry = _fractionMap.entries.firstWhereOrNull(
    (e) => (e.key - decimal).abs() < 0.01,
  );

  if (entry == null) {
    String s = displayQty.toStringAsFixed(1);
    if (s.endsWith('.0')) {
      s = s.substring(0, s.length - 2);
    }
    return '$s$suffix'.trim();
  }

  final fractionStr = entry.value;

  if (whole == 0) return '$fractionStr$suffix'.trim();
  return '$whole $fractionStr$suffix'.trim();
}
