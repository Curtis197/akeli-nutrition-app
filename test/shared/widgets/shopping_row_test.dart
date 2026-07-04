import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/meal_plan.dart';
import 'package:akeli/shared/widgets/shopping_row.dart';

const _item = ShoppingItem(
  id: 'i1',
  ingredientId: 'ing1',
  name: 'Riz',
  quantity: 500,
  unit: 'g',
  isChecked: false,
);

void main() {
  group('AkeliShoppingRow -- info icon', () {
    testWidgets('is absent when onInfoTap is not provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AkeliShoppingRow(item: _item, isChecked: false, onToggle: () {}),
        ),
      ));

      expect(find.byKey(const Key('shopping-row-info')), findsNothing);
    });

    testWidgets('is present and invokes onInfoTap when provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AkeliShoppingRow(
            item: _item,
            isChecked: false,
            onToggle: () {},
            onInfoTap: () => tapped = true,
          ),
        ),
      ));

      expect(find.byKey(const Key('shopping-row-info')), findsOneWidget);
      await tester.tap(find.byKey(const Key('shopping-row-info')));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('tapping the info icon does not also trigger onToggle', (tester) async {
      var toggled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AkeliShoppingRow(
            item: _item,
            isChecked: false,
            onToggle: () => toggled = true,
            onInfoTap: () {},
          ),
        ),
      ));

      await tester.tap(find.byKey(const Key('shopping-row-info')));
      await tester.pump();
      expect(toggled, isFalse);
    });
  });
}
