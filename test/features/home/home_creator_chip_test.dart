import 'package:akeli/core/theme.dart';
import 'package:akeli/features/home/home_creator_chip.dart';
import 'package:akeli/shared/models/creator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: buildLightTheme(), home: Scaffold(body: child));

const _creator = Creator(
  id: 'c1',
  userId: 'u1',
  displayName: 'Chef Amina',
  specialties: [],
  recipeCount: 12,
  fanCount: 40,
  isFanEligible: true,
  isMyFanCreator: false,
  averageRating: 4.5,
);

void main() {
  group('HomeCreatorChip', () {
    testWidgets('renders display name', (tester) async {
      await tester.pumpWidget(_wrap(HomeCreatorChip(creator: _creator)));
      expect(find.text('Chef Amina'), findsOneWidget);
    });

    testWidgets('shows initials avatar when no avatarUrl', (tester) async {
      await tester.pumpWidget(_wrap(HomeCreatorChip(creator: _creator)));
      // CircleAvatar with initial letter 'C'
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        HomeCreatorChip(creator: _creator, onTap: () => tapped = true),
      ));
      await tester.tap(find.byType(HomeCreatorChip));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('does not throw when onTap is null', (tester) async {
      await tester.pumpWidget(_wrap(HomeCreatorChip(creator: _creator)));
      await tester.tap(find.byType(HomeCreatorChip));
      await tester.pump();
      // no exception
    });
  });
}
