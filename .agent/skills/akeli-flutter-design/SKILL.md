---
name: akeli-flutter-design
description: >
  High-fidelity Flutter UI migration skill for the Akeli app.
  Use this skill whenever building or migrating a Flutter screen for Akeli.
  Produces pixel-accurate Dart code from Stitch mockups, HTML references,
  and FlutterFlow exports. Avoids generic Material Design aesthetics.
  Triggers on: "migrate this screen", "build this page in Flutter",
  "convert FlutterFlow to native Flutter", "reproduce this mockup in Dart",
  or any screen implementation task for the Akeli project.
---

# Akeli Flutter Design Migration Skill

This skill produces high-fidelity, production-grade Flutter screens for the Akeli
nutrition app. It follows an 8-step audit workflow to guarantee visual parity between
the design reference (Stitch screenshot + HTML mockup) and the final Dart code.

> [!IMPORTANT]
> **Workflow Initiation**: You MUST create the audit MD file in the `audit/` folder as the very first action when starting any migration. Do not wait for a separate instruction.

Reference example: `stitch/audit_exemple/audit-exemple.md` + `screen.png`

---

## Core Principles

- **Never interpret — transcribe.** Every spacing, color, and radius value must come
  from the audit document or screenshot. Do not invent.
- **No generic Material defaults.** Avoid default AppBar, default ListTile, default
  Card. Every widget must be explicitly styled.
- **Design tokens first.** All colors, radius, and spacing come from
  `lib/core/design_system/` — never hardcode raw values in page files.
- **Decouple UI from data.** Use `MockData` models during UI prototype. Wire providers
  only after visual parity is confirmed.
- **const everything static.** All style elements that do not change must use `const`.

---

## Akeli Design Tokens (Reference)

```dart
// Colors
AkeliColors.primary          // #006A63 — teal dark (CTA, active icons, amounts)
AkeliColors.primaryLight     // #4DB6AC — teal light (badges, image bg)
AkeliColors.surface          // #FCFAEF — cream (page background)
AkeliColors.surfaceContainer // #F6F4E9 — cream dark (macro boxes, ingredient rows)
AkeliColors.white            // #FFFFFF — cards
AkeliColors.orange           // #FF9F43 — calories, secondary CTA
AkeliColors.onSurface        // #1B1C16 — primary text
AkeliColors.onSurfaceVariant // #3D4947 — body text, secondary labels

// Radius
AkeliRadius.sm   // 8px
AkeliRadius.md   // 12px
AkeliRadius.lg   // 16px  — macro boxes, image thumbnails
AkeliRadius.xl   // 24px  — main cards, ingredient rows, buttons
AkeliRadius.pill // 99px  — badges

// Spacing
AkeliSpacing.xs  // 4px
AkeliSpacing.sm  // 8px
AkeliSpacing.md  // 12px
AkeliSpacing.lg  // 16px  — default page padding
AkeliSpacing.xl  // 24px  — section gap
AkeliSpacing.xxl // 32px  — major section gap

// Typography
// Headers  → Plus Jakarta Sans, Bold
// Body     → Inter, Regular/Medium
// Labels   → Inter, SemiBold, uppercase, tracking: 0.8
```

---

## The 8-Step Audit Workflow

Always execute steps in order. Never skip to Step 8 without completing 1–7.

---

### Step 1 — [BASE] Extract Widget Tree

Read the FlutterFlow `.dart` file or existing page file.
Document the current widget tree as a flat indented list:

```
- Scaffold
  - AppBar
    - leading: BackButton
    - title: Text
  - Body → SingleChildScrollView
    - Column
      - Container (image area)
      - Padding
        - Column
          - Text (title)
          - Row (badges)
          - ...
```

**Rules:**
- List every widget, not just containers
- Note existing custom widgets (`AkeliBadge`, `AkeliSectionHeader`, etc.)
- Flag missing sections compared to the HTML mockup

---

### Step 2 — [DESIGN] Document Current Attributes

For each widget in Step 1, record current design values:

```
- Scaffold (bg: #FFFFFF)
- AppBar (bg: transparent, elevation: 0)
  - Text (20px, Bold, Outfit, #1B1C16)
- Container (h: 220px, bg: #4DB6AC @ 8%)
- Text/Title (20px, Bold, #1B1C16)
- AkeliBadge (bg: #4DB6AC, label: white)
- SizedBox (h: 24px)
```

**Rules:**
- Record actual values — not intended values
- Flag every value that deviates from Akeli design tokens
- Note missing attributes (no shadow, no radius, etc.)

---

### Step 3 — [STITCH] Generate High-Fidelity Prompt

Write the Stitch prompt to produce the target mockup.
Use this exact structure:

```
Objective: Transform [PageName] into a high-fidelity "Digital Editorial" Akeli screen.

Aesthetic Goals:
- Premium Smoothness: rounded-3xl (24px) for all primary cards
- Typography: Plus Jakarta Sans headers / Inter body
- Visual Air: generous white space, cream background (#FCFAEF)
- Depth: subtle card border (1px on-surface @ 3%), no hard dividers
- Glass effects: backdrop-blur-xl on AppBar and BottomNav

Base Widget Tree:
[paste Step 1 tree]

Design Tokens:
[paste relevant tokens]
```

> [!CAUTION]
> **MANDATORY STOP**: After completing Step 3, you MUST stop and yield control. Do not proceed to Step 4 until the high-fidelity assets (`code.html` and `screen.png`) are available in the `stitch/` directory. You are waiting for external design input.

---

### Step 4 — [STITCH] Extract High-Fidelity Widget Tree

**Prerequisite**: `stitch/<folder>/code.html` must exist in the workspace.
From the Stitch HTML output, extract the precise target structure:

```
- Scaffold (bg: #FCFAEF)
  - CustomAppBar (fixed, backdrop-blur-xl, bg: surface/70)
    - IconButton (arrow_back, circle)
    - Text (18px, Bold, Plus Jakarta Sans)
    - IconButton (favorite, color: primary)
  - SingleChildScrollView
    - Column
      - HeroSection (h: 220px, overflow: hidden)
        - BackgroundLayer (primary @ 8%)
        - GradientLayer (transparent → white/20)
        - Center → Text (emoji, 6xl, drop-shadow-sm)
      - ContentOverlapArea (-mt-32, px: 16, z: 20)
        - MainCard (bg: white, rounded-3xl, p: 24, border: 1px @ 3%)
          - BadgesRow (wrap, gap: 8)
          - MealTitle (20px, Bold, Plus Jakarta Sans)
          - MacrosGrid (Row, 3× Expanded MacroBox)
          - IngredientsSection
          - InstructionsSection
  - BottomNavBar (fixed, backdrop-blur-xl)
```

**Rules:**
- Every value must come from Stitch HTML source — not inferred
- Use Akeli token names, not raw hex values

---

### Step 5 — [COMPARISON] Delta Table

Produce a diff table between Step 2 (current) and Step 4 (target):

| Delta Type | Widget | Change Required |
|---|---|---|
| [LAYOUT] | Body | Add `-32px` overlap translate on MainCard |
| [LAYOUT] | Ingredients | Replace raw list → `rounded-3xl` containers with image |
| [DESIGN] | All cards | radius 12px → 24px (`AkeliRadius.xl`) |
| [DESIGN] | AppBar | Add `BackdropFilter` blur: 20 |
| [DESIGN] | Typography | Switch headers to `Plus Jakarta Sans` |
| [DESIGN] | BottomNav | Add `BackdropFilter` + cream bg @ 80% |
| [MISSING] | HeroSection | Add gradient overlay layer |

---

### Step 6 — [VALIDATION] Screenshot Checklist

Before writing any Dart code, verify the Stitch screenshot against Step 4 tree.
Check each item:

```
□ Image hero height matches (220px)
□ Card overlap is visible (content slides over image)
□ Badge colors correct (teal/orange/neutral)
□ Macro grid is 3 equal columns
□ Ingredient rows have circular image + amount in primary color
□ Step numbers are circular badges (primary @ 20% bg)
□ CTA buttons: outline (secondary) + filled (primary)
□ Bottom nav icon spacing and active state correct
□ Background is cream (#FCFAEF), not white
□ No hard dividers between sections
```

Flag any discrepancy before proceeding to Step 7.

---

### Step 7 — [VISUAL] Nuance Extraction & Implementation Blueprint

#### Visual Nuance Extraction (from screenshot)

Analyze the screenshot and document subtle details:

- **Tonal depth**: contrast between white card and cream bg — no dividers needed
- **Micro-coloring**: opacity levels on badge backgrounds (approx 10% for kcal)
- **Typography feel**: title letter-spacing, body line-height
- **Shadow quality**: card shadow — diffuse, not hard
- **Image treatment**: circular thumbnails with `object-cover`, no border

#### Implementation Blueprint

Define custom components needed:

```dart
// AkeliGlazeAppBar
// ClipRect + BackdropFilter(blur: 20) + bg: surface @ 70%
// Fixed position, height: 64px, px: 24

// AkeliOverlapCard  
// Stack or Transform.translate(offset: Offset(0, -32))
// bg: white, rounded-3xl, p: 24, border: Border.all(color: onSurface.withOpacity(0.03))

// AkeliMacroGrid
// Row with 3× Expanded → MacroBox
// MacroBox: bg: surfaceContainer, rounded-2xl, p: 12, label uppercase 10px, value 20px Bold

// AkeliIngredientRow
// Container: bg: surfaceContainer, rounded-3xl, p: 16
// Row: Image(48×48, rounded-2xl) + Column(name/detail) + Spacer + Amount(primary, Bold)

// AkeliStepItem
// Row: CircleAvatar(r:12, bg:primary@20%, text:primary, Bold) + Expanded Text(14px, h:1.6)
```

---

### Step 8 — [TRANSCRIPTION] Flutter Implementation

Implement `lib/features/[feature]/[page_name].dart` using the Step 7 blueprint.

#### File Structure

```dart
// IMPORTS
import 'package:flutter/material.dart';
import '../../core/design_system/colors.dart';
import '../../core/design_system/radius.dart';
import '../../core/design_system/spacing.dart';
import '../../core/design_system/typography.dart';

// MOCK DATA (during UI prototype — replace with providers after visual parity confirmed)
class _MockPageData { ... }

// PAGE WIDGET
class PageNamePage extends StatelessWidget {
  const PageNamePage({super.key});
  
  @override
  Widget build(BuildContext context) { ... }
}

// PRIVATE COMPONENTS (only used in this file)
class _CustomComponent extends StatelessWidget { ... }
```

#### Implementation Rules

1. **No hardcoded values** — use `AkeliColors.*`, `AkeliRadius.*`, `AkeliSpacing.*`
2. **No default Material widgets** — custom AppBar, no ListTile, no default Card
3. **const everything** — all static style decorations must be `const`
4. **Overlap with Stack or Transform** — never approximate with padding
5. **BackdropFilter requires ClipRect parent** — always wrap
6. **Image.network with shimmer placeholder** — never empty containers
7. **SafeArea bottom padding** — `SizedBox(height: 80)` minimum before end of scroll

#### Validation Checklist (after implementation)

```
□ Visual parity against screen.png confirmed
□ Widget tree matches Step 4 structure
□ All values come from design tokens (no raw hex)
□ const constructors used for static elements
□ Mock data decoupled from UI
□ No FlutterFlow imports or dependencies
□ File compiles without errors
□ Hot reload shows correct layout on iPhone 14 frame
```

---

## Common Flutter Patterns for Akeli

### Overlap Card (hero image + content slide-over)
```dart
Stack(
  children: [
    // Hero image
    Container(height: 220, ...),
    // Content card
    Positioned(
      top: 188, left: 16, right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: AkeliColors.white,
          borderRadius: BorderRadius.circular(AkeliRadius.xl),
          border: Border.all(color: AkeliColors.onSurface.withOpacity(0.03)),
        ),
        padding: const EdgeInsets.all(AkeliSpacing.xl),
        child: ...,
      ),
    ),
  ],
)
```

### Glass AppBar
```dart
ClipRect(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
    child: Container(
      height: 64,
      color: AkeliColors.surface.withOpacity(0.7),
      padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.xl),
      child: Row(
        children: [backButton, title, actionButton],
      ),
    ),
  ),
)
```

### Macro Grid (3 equal columns)
```dart
Row(
  children: [
    Expanded(child: _MacroBox(label: 'PROTÉINES', value: '18g')),
    const SizedBox(width: 12),
    Expanded(child: _MacroBox(label: 'GLUCIDES', value: '52g')),
    const SizedBox(width: 12),
    Expanded(child: _MacroBox(label: 'LIPIDES', value: '14g')),
  ],
)
```

### Step Number Badge
```dart
Container(
  width: 24, height: 24,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: AkeliColors.primary.withOpacity(0.2),
  ),
  child: Center(
    child: Text('1',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AkeliColors.primary,
      ),
    ),
  ),
)
```

### Pill Badge
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: AkeliColors.primaryLight.withOpacity(0.2),
    borderRadius: BorderRadius.circular(AkeliRadius.pill),
  ),
  child: Text('Déjeuner',
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AkeliColors.primary,
    ),
  ),
)
```

---

## What NOT to Do

- ❌ `AppBar(title: Text(...))` — use custom `ClipRect + BackdropFilter` header
- ❌ `Card(child: ...)` — use `Container` with explicit `BoxDecoration`
- ❌ `ListTile(...)` — use custom `Row` with explicit padding
- ❌ `Colors.teal` — use `AkeliColors.primary`
- ❌ `BorderRadius.circular(8)` — use `AkeliRadius.lg`
- ❌ `SizedBox(height: 20)` — use `AkeliSpacing.xl`
- ❌ Import any `flutterflow_ui` package
- ❌ Add sections not visible in the mockup
- ❌ Guess spacing — measure from screenshot or audit document
