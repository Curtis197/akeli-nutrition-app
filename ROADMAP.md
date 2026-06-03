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

## ✅ Phase 1 — Pure UI (Completed)

All UI screens transcribed, pixel-perfect, and high-fidelity.

---

## ✅ Phase 2 — Design System Hardening (Completed)

- [x] Audit all Phase 1 screens for repeated patterns
- [x] Extract into `lib/core/design_system/` components
- [x] Ensure all design tokens (colors, spacing, radius, typography) are centralized in `lib/core/theme.dart`
- [x] Dark mode verification pass
- [x] Performance audit (const constructors, no rebuilds on unchanged state)

---

## ✅ Phase 3 — Backend Reconnection (Completed)

- [x] Swap `lib/shared/mocks/` with real Supabase providers
- [x] Re-enable auth flow (Supabase Auth with email confirmation)
- [x] Re-enable GoRouter guards
- [x] Implement error states and loading states for every screen
- [x] Edge Functions: meal plan generation, AI assistant
- [x] End-to-end testing against production Supabase

---

## 🚀 Phase 4 — Live Testing & Debugging (Current Phase)

**Goal**: Monitor real-time logs, fix layout bugs, optimize queries, and resolve edge cases found during live usage.

- [ ] Actively track logs via `appLogger`
- [ ] Address RLS policy blocks
- [ ] Fix runtime exceptions and edge cases
- [ ] Performance and query optimization

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
