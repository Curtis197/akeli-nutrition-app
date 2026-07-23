import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/features/recipes/saved_recipes_page.dart';
import 'package:akeli/providers/auth_provider.dart';
import 'package:akeli/providers/profile_tabs_provider.dart';
import 'package:akeli/providers/mode_provider.dart';
import 'package:akeli/shared/models/recipe.dart';
import 'package:akeli/l10n/app_localizations.dart';

class FakeBeautyModeNotifier extends ModeNotifier {
  @override
  AppMode build() => AppMode.beauty;
}

const _testUser = User(
  id: 'user-1',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-06-02T00:00:00Z',
);

Recipe _recipe(String id, String title, String mode) => Recipe(
      id: id,
      creatorId: 'creator-1',
      title: title,
      imageUrls: const [],
      prepTimeMin: 10,
      cookTimeMin: 10,
      servings: 2,
      difficulty: 'easy',
      mode: mode,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  testWidgets(
      'SavedRecipesPage shows only Beauty-mode recipes when appMode is Beauty',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentModeProvider.overrideWith(FakeBeautyModeNotifier.new),
          currentUserProvider.overrideWithValue(_testUser),
          userSavedRecipesProvider('user-1').overrideWith((ref) async => [
                _recipe('r-nutrition', 'Nutrition Recipe', 'nutrition'),
                _recipe('r-beauty', 'Beauty Remedy', 'beauty'),
              ]),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: SavedRecipesPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Beauty Remedy'), findsOneWidget);
    expect(find.text('Nutrition Recipe'), findsNothing);
  });
}
