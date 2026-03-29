# Akeli UI Audit — Master Ledger

This file is the **status tracker only**. Each page and component has its own dedicated audit file in `audit/` which is the source of truth for that item.

See `.agent/workflows/audit-workflow.md` for the full 8-step process.

---

## Pages

| Page | Audit File | Status | Step | Approved |
|---|---|---|---|---|
| Meal Detail | `audit/pages/meal_detail.md` | ✅ Steps 1-8 ready | Approved — ready to code | ⬜ Pending |
| Meal Planner | `audit/pages/meal_planner.md` | ⬜ Not started | — | — |
| Home Dashboard | `audit/pages/home_dashboard.md` | 🟡 Steps 1-2 done | Step 3 next | — |
| Recipes Feed | `audit/pages/recipes_feed.md` | ⬜ Not started | — | — |
| Recipe Detail | `audit/pages/recipe_detail.md` | ⬜ Not started | — | — |
| AI Assistant | `audit/pages/ai_assistant.md` | ⬜ Not started | — | — |
| Community | `audit/pages/community.md` | ⬜ Not started | — | — |
| Profile | `audit/pages/profile.md` | ⬜ Not started | — | — |
| Auth | `audit/pages/auth.md` | ⬜ Not started | — | — |
| Onboarding | `audit/pages/onboarding.md` | ⬜ Not started | — | — |
| Nutrition | `audit/pages/nutrition.md` | ⬜ Not started | — | — |

---

## Shared Components

| Component | Audit File | Status |
|---|---|---|
| MealCard | `audit/components/meal_card.md` | ⬜ Not started |
| MacroBadge | `audit/components/macro_badge.md` | ⬜ Not started |
| SectionHeader | `audit/components/section_header.md` | ⬜ Not started |
| ShoppingRow | `audit/components/shopping_row.md` | ⬜ Not started |
| AkeliBadge | `audit/components/akeli_badge.md` | ⬜ Not started |
| ProgressCircle | `audit/components/progress_circle.md` | ⬜ Not started |

---

## Notes

- **`audit-exemple.md`** (root) is kept as the process walkthrough reference only — do not use it as a data source. The complete, accurate Meal Detail audit is in `audit/pages/meal_detail.md`.
- Components are audited when first encountered during a page transcription.
