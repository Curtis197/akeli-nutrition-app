---
description: Standardized UI Audit & High-Fidelity Transformation Workflow
---

# Akeli UI Audit Workflow

This workflow defines the mandatory sequence for transforming FlutterFlow (FF) base code into high-fidelity Flutter native components.

---

## 📁 Audit File Convention

Every page gets its own audit file. This file is the **single source of truth** for that page and its constituent components throughout the entire migration.

> [!IMPORTANT]
> **Immediate Documentation**: You MUST create the audit MD file in the `audit/` directory as the very first action of any migration task. Do not wait for a prompt or ask for permission.

### Location & Naming

```
audit/
└── pages/
    ├── meal_detail.md
    ├── meal_planner.md
    ├── home_dashboard.md
    ├── recipes_feed.md
    ├── recipe_detail.md
    ├── ai_assistant.md
    ├── community.md
    ├── profile.md
    ├── auth.md
    └── onboarding.md
```

### Reference example
`audit-exemple.md` — Fully completed audit for the Meal Detail page. Use it as the template for all new audit files.

---

## 🔄 The 8-Step Transformation Sequence

Each audit file tracks the page through these steps. Steps must be done in order. Each step is logged in the page's audit file before moving to the next.

### Step 1 — [BASE] Widget Tree
- Source: `flutterflow_application/akeli/lib/`
- Extract the core structure of the FF-generated page, including all internal component logic (e.g., specific cards, badges, or list items)
- Format: hierarchical list (Scaffold → AppBar → Column → [Component: MealCard] → Text)
- Goal: understand the skeleton and business logic before any visual work

### Step 2 — [DESIGN] Baseline Attributes
- For each widget in the tree, extract exact design attributes from the FF code
- Format: `WidgetName (bg: #HEX, font: Name Xpx Bold, padding: Xpx, radius: Xpx)`
- Goal: pixel-perfect documentation of the starting point

### Step 3 — [STITCH] Prompt Generation
- Bundle the annotated widget tree into a clear prompt for the Stitch agent
- Include aesthetic goals (rounded corners, typography targets, visual air)
- Goal: give Stitch the structural constraints to generate the target mockup

> [!CAUTION]
> **MANDATORY STOP**: After completing Step 3, you MUST stop and yield control. Do not proceed to Step 4 until the high-fidelity assets (`code.html` and `screen.png`) are available in the `stitch/` directory. You are waiting for external design input.

### Step 4 — [STITCH] High-Fidelity Widget Tree
- **Prerequisite**: `stitch/<folder>/code.html` must exist in the workspace.
- Extract the target widget tree from the Stitch HTML
- Format: same hierarchical structure as Step 1 but with Stitch tokens
- Goal: define the precise structural and visual target

### Step 5 — [COMPARISON] Delta Analysis
- Side-by-side diff of Step 2 (baseline) vs. Step 4 (target)
- Tag each change as `[LAYOUT]` or `[DESIGN]`
- Goal: explicit list of every modification required

### Step 6 — [APPROVAL] User Validation
- Present the delta to the user for review
- No transcription begins until this step is marked ✅ approved
- Goal: user confirms the plan before any code is written

### Step 7 — [VISUAL] Screenshot Analysis
- Source: `stitch/<page_name>/screen.png`
- Extract visual nuances not visible in HTML (shadows, opacity, micro-spacing)
- Produce an implementation blueprint (component names, Flutter patterns to use)
- Goal: bridge the gap between Stitch HTML and production Flutter code

### Step 8 — [TRANSCRIPTION] Flutter Code
- Implement the page in `lib/features/<page>/` using the Step 7 blueprint
- All design tokens from `lib/core/theme.dart`
- All data from `lib/shared/mocks/` — no backend calls
- Verify visual parity against `stitch/<page_name>/screen.png`

---

## 📋 Audit File Template

Each audit file must follow this structure:

```markdown
# Audit: [Page or Component Name]
**Status**: Step X — [Step Name]
**Flutter file**: `lib/features/.../page.dart`
**FF source**: `flutterflow_application/akeli/lib/.../widget.dart`
**Stitch source**: `stitch/<folder>/`

---

## Step 1: [BASE] Widget Tree
...

## Step 2: [DESIGN] Baseline Attributes
...

## Step 3: [STITCH] Prompt
...

## Step 4: [STITCH] High-Fidelity Widget Tree
...

## Step 5: [COMPARISON] Delta
| Delta Type | Change Required |
|---|---|
| [LAYOUT] | ... |
| [DESIGN] | ... |

## Step 6: [APPROVAL]
- [ ] User approved

## Step 7: [VISUAL] Screenshot Analysis & Blueprint
...

## Step 8: [TRANSCRIPTION] Notes
...
```

---

## 🛠️ Rules

- **Never start Step 8 without Step 6 approval.**
- **MANDATORY STOP after Step 3**: Always wait for Stitch assets before Step 4.
- **One audit file per page.** Components are audited as part of their parent page.
- **Create the audit file IMMEDIATELY** — Do not ask before creating it.
- **Keep the audit file updated** — it is the living record of decisions made.
- **`audit-exemple.md`** is the reference template. Do not modify it.
- The `UI_AUDIT.md` ledger in the root tracks the status of all pages at a glance (links to individual audit files).
