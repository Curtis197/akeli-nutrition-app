# Organic Editorial Redesign — Wave 3 Plan (Recipe Detail)

**Target:** `lib/features/recipes/recipe_detail_page.dart`
**Stitch Reference:** `stitch2/.../akeli_premium_recipe_detail_editorial`

## Plan
1. Completely rewrite the build method of `_RecipeContent` to match the exact HTML specification in `stitch2/.../akeli_premium_recipe_detail_editorial/code.html`.
2. Ensure we use a floating hero layout with `Stack` or `SingleChildScrollView`.
3. Apply `GoogleFonts.plusJakartaSans` and `GoogleFonts.inter` to all text nodes.
4. Apply the required color swaps (`Colors.white` -> `AkeliColors.surfaceContainerLowest` or `AkeliColors.onPrimary`, `AkeliColors.textSecondary` -> `AkeliColors.onSurfaceVariant`).
5. Ensure all bounding boxes have appropriate `AkeliRadius` and `AkeliShadows`.
6. Maintain strict compliance with `CLAUDE.md` logging standards.
