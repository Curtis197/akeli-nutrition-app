# Home Recommended Creators Row — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Créateurs pour vous" horizontal strip to the home page showing the 5 most aligned, not-yet-followed creators.

**Architecture:** Reuse the existing `creatorsListProvider` (calls `generate_creators_personalized` RPC, returns up to 20 personalized creators). In `HomePage.build()`, filter to `isMyFanCreator == false` and take 5. A new `HomeCreatorChip` widget (in its own file inside the home feature folder) renders each creator as a compact vertical card.

**Tech Stack:** Flutter, Riverpod (`FutureProvider.autoDispose`), `go_router`, `cached_network_image`, `google_fonts`

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/features/home/home_creator_chip.dart` | Create | Compact vertical creator card widget |
| `lib/features/home/home_page.dart` | Modify | Watch `creatorsListProvider`, add section |
| `test/features/home/home_creator_chip_test.dart` | Create | Widget tests for `HomeCreatorChip` |

---

## Task 1: `HomeCreatorChip` widget — TDD

**Files:**
- Create: `lib/features/home/home_creator_chip.dart`
- Test: `test/features/home/home_creator_chip_test.dart`

- [ ] **Step 1: Create the test file with failing tests**

Create `test/features/home/home_creator_chip_test.dart`:

```dart
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
      expect(tapped, isTrue);
    });

    testWidgets('does not throw when onTap is null', (tester) async {
      await tester.pumpWidget(_wrap(HomeCreatorChip(creator: _creator)));
      await tester.tap(find.byType(HomeCreatorChip));
      // no exception
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```
flutter test test/features/home/home_creator_chip_test.dart
```

Expected: compilation error — `home_creator_chip.dart` does not exist yet.

- [ ] **Step 3: Create `lib/features/home/home_creator_chip.dart`**

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../shared/models/creator.dart';

class HomeCreatorChip extends StatelessWidget {
  final Creator creator;
  final VoidCallback? onTap;

  const HomeCreatorChip({
    super.key,
    required this.creator,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AkeliColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AkeliRadius.lg),
          boxShadow: const [AkeliShadows.sm],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _avatar(),
            const SizedBox(height: 6),
            Text(
              creator.displayName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AkeliColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    if (creator.avatarUrl != null && creator.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: CachedNetworkImageProvider(creator.avatarUrl!),
      );
    }
    final initial = creator.displayName.isNotEmpty
        ? creator.displayName[0].toUpperCase()
        : '?';
    return CircleAvatar(
      radius: 28,
      backgroundColor: AkeliColors.primaryContainer,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AkeliColors.onPrimaryContainer,
        ),
      ),
    );
  }
}
```

Note: `appLogger` is not imported here intentionally — the chip is a pure display widget with no state. Tap logging is the caller's responsibility (home page).

- [ ] **Step 4: Run tests — all should pass**

```
flutter test test/features/home/home_creator_chip_test.dart
```

Expected: 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/home_creator_chip.dart test/features/home/home_creator_chip_test.dart
git commit -m "feat: add HomeCreatorChip widget with tests"
```

---

## Task 2: Add "Créateurs pour vous" section to `HomePage`

**Files:**
- Modify: `lib/features/home/home_page.dart`

- [ ] **Step 1: Add `creatorsListProvider` import**

In `lib/features/home/home_page.dart`, add to the existing import block:

```dart
import '../../providers/creator_provider.dart';
import 'home_creator_chip.dart';
```

- [ ] **Step 2: Watch the provider in `build()`**

In `_HomePageState.build()`, alongside the other provider watches (after `final regionNames = ...`), add:

```dart
final creatorsAsync = ref.watch(creatorsListProvider);
```

Also add it to the build-log block:

```dart
_logger.provider('  [creators]     ${_ps(creatorsAsync)}');
```

The full logging block already has the `────` divider line — insert the new line before it:

```dart
_logger.provider('  [creators]     ${_ps(creatorsAsync)}');
_logger.provider('────────────────────────────────────────────────────────');
```

- [ ] **Step 3: Add the section in `build()` — after the recipes section**

Locate the `const SizedBox(height: 80)` at the bottom of the `Column` children. Insert the new section immediately before it:

```dart
const SizedBox(height: 24),

// --- Recommended creators section ---
...creatorsAsync.when(
  data: (creators) {
    final shown = creators
        .where((c) => !c.isMyFanCreator)
        .take(5)
        .toList();
    _logger.provider('[home-creators] data | total rpc: ${creators.length} | after fan filter + take5: ${shown.length}');
    if (shown.isEmpty) return [];
    return [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: AkeliSectionHeader(
          title: 'Créateurs pour vous',
          color: AkeliColors.primary,
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: shown.length,
          itemBuilder: (context, index) {
            final creator = shown[index];
            return Padding(
              key: ValueKey(creator.id),
              padding: const EdgeInsets.only(right: 12),
              child: HomeCreatorChip(
                creator: creator,
                onTap: () {
                  _logger.userAction(
                    'Creator chip tapped',
                    screen: 'HomePage',
                    metadata: {'creatorId': creator.id},
                  );
                  context.go('/creator/${creator.id}');
                },
              ),
            );
          },
        ),
      ),
    ];
  },
  loading: () {
    _logger.provider('[home-creators] loading');
    return [
      const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
    ];
  },
  error: (e, st) {
    _logger.provider('[home-creators] ERROR: $e', error: e, stackTrace: st);
    return const [SizedBox.shrink()];
  },
),

const SizedBox(height: 80),
```

> **Why spread (`...`):** The `Column` children list is a `List<Widget>`. `creatorsAsync.when(data: ...)` returns a `List<Widget>` per branch so we can conditionally include or omit the section header + list together using the spread operator.

- [ ] **Step 4: Run all tests to verify no regressions**

```
flutter test
```

Expected: all existing tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/home_page.dart
git commit -m "feat: add recommended creators row to home page"
```

---

## Self-Review

**Spec coverage:**
- ✅ 5 most aligned creators → `creatorsListProvider` (personalized RPC) + `.take(5)`
- ✅ Exclude fans → `.where((c) => !c.isMyFanCreator)`
- ✅ Avatar + name only → `HomeCreatorChip` shows `CircleAvatar` + `Text`
- ✅ Initials fallback → `_avatar()` method
- ✅ Tap navigates to creator detail → `context.go('/creator/${creator.id}')`
- ✅ Section hidden when empty → `if (shown.isEmpty) return []`
- ✅ Loading state → `CircularProgressIndicator`
- ✅ Error state → `SizedBox.shrink()` (silent fail)
- ✅ CLAUDE.md logging → provider states, user action logged
- ✅ Section placed after "Recettes recommandées" → spread inserted before `SizedBox(height: 80)`

**Placeholder scan:** None found. All steps contain complete code.

**Type consistency:** `HomeCreatorChip` constructor uses `creator` and `onTap` — consistent across test file and home page usage.
