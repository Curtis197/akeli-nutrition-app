# Akeli Nutrition App — Project Roadmap

## 🎯 Migration Goal

Migrate from a **FlutterFlow production app** (working, no bugs, ~6/10 design) to a **Flutter native app** that offers:
- Full development freedom (custom painters, animations, complex state)
- Upgraded design: **6/10 → 8/10** (modern, fluid, "Digital Editorial" aesthetic)

The migration is split into **3 strictly sequential phases**. Phases do not overlap. No backend work is done until Phase 3.

---

## 🔴 Previous Attempt — Why It Failed

A first migration attempt was made but produced poor results:
- Backend connections (Supabase) and UI were migrated simultaneously
- Design quality suffered from lack of structured visual references
- The resulting code mixed concerns and was hard to iterate on

**Lesson**: Design and data must be separated. UI-first, backend-second.

---

## ✅ Source of Truth

| Asset | Role |
|---|---|
| `flutterflow_application/akeli/` | Original FF app — feature reference, data model reference |
| `stitch/` | High-fidelity mockups — visual target for each page |
| `audit/pages/<page>.md` | Per-page audit file — single source of truth for each page |
| `audit/components/<name>.md` | Per-component audit file |
| `audit-exemple.md` | Completed reference example (Meal Detail) — do not modify |
| `UI_AUDIT.md` | Master ledger — status tracker linking to all audit files |
| `.agent/workflows/audit-workflow.md` | Mandatory 8-step workflow for every page transformation |

---

## 🏗️ Phase 1 — Pure UI (Current Phase)

**Rule**: Zero backend calls. Zero Supabase. Zero Firebase. Only mock data and Riverpod state.

**Goal**: Achieve pixel-perfect, high-fidelity UI for every page, validated against Stitch mockups.

### How each page is done (8-step audit workflow)

1. Extract widget tree from FF source (`flutterflow_application/akeli/lib/`)
2. Document baseline design attributes (colors, fonts, spacing)
3. Generate Stitch prompt from baseline
4. Extract Stitch high-fidelity widget tree (from `stitch/*/code.html`)
5. Delta analysis — Baseline vs. Stitch
6. User approval of proposed changes
7. Visual screenshot analysis (`stitch/*/screen.png`) → implementation blueprint
8. Flutter transcription into `lib/features/`

### Page Status

| Page | FF Audit | Stitch | Delta | Approved | Transcribed |
|---|---|---|---|---|---|
| Meal Detail | ✅ Done (audit-exemple.md) | ✅ | ✅ | ⬜ | ⬜ |
| Meal Planner | ⬜ | ✅ stitch_meal_planner | ⬜ | ⬜ | ⬜ |
| Home Dashboard | 🟡 Steps 1-2 done | ✅ stitch_modern_dashboard | ⬜ | ⬜ | ⬜ |
| Recipes Feed | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Recipe Detail | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| AI Assistant | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Community | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Profile | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Auth / Onboarding | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Nutrition | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

### Phase 1 Rules
- All widgets use constants or mock data from `lib/shared/mocks/`
- Riverpod providers are allowed for UI state only (no async data fetching)
- Navigation via GoRouter is kept
- No Supabase imports anywhere in `lib/features/`

---

## 🏗️ Phase 2 — Design System Hardening

**Prerequisite**: All pages transcribed and visually approved in Phase 1.

**Goal**: Extract repeated patterns into a robust, reusable component library.

- [ ] Audit all Phase 1 screens for repeated patterns
- [ ] Extract into `lib/core/design_system/` components
- [ ] Ensure all design tokens (colors, spacing, radius, typography) are centralized in `lib/core/theme.dart`
- [ ] Dark mode verification pass
- [ ] Performance audit (const constructors, no rebuilds on unchanged state)

---

## 🏗️ Phase 3 — Backend Reconnection

**Prerequisite**: Phase 2 complete. Design is frozen.

**Goal**: Replace mock data with real Supabase data without touching the UI layer.

- [ ] Swap `lib/shared/mocks/` with real Supabase providers
- [ ] Re-enable auth flow (Supabase Auth with email confirmation)
- [ ] Re-enable GoRouter guards
- [ ] Implement error states and loading states for every screen
- [ ] Edge Functions: meal plan generation, AI assistant
- [ ] End-to-end testing against production Supabase

---

## 🎨 Design System (Reference)

| Token | Value |
|---|---|
| Primary | #006A63 |
| Secondary | #4DB6AC |
| Surface | #FCFAEF |
| On-Surface | #1B1C16 |
| Corner Radius (xl) | 24px |
| Corner Radius (lg) | 16px |
| Font (Headers) | Plus Jakarta Sans |
| Font (Body) | Inter |
| Design Aesthetic | "Digital Editorial" — tonal depth, glassmorphism, no dividers |
