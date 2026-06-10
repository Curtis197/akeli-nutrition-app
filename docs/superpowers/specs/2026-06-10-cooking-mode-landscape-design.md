# Cooking Mode — Landscape Layout

**Date:** 2026-06-10  
**File:** `lib/features/cooking/cooking_mode_page.dart`  
**Status:** Approved, ready for implementation

---

## Problem

`CookingModePage` uses a pure vertical `Column`. In landscape orientation, available height drops to ~320–400 dp, causing the instruction text, optional media, timer, ingredient strip, and nav buttons to either overflow or become unusably cramped.

Portrait layout is fine and must not change.

---

## Solution

Wrap the page body in `OrientationBuilder`. Portrait renders the existing layout unchanged. Landscape renders a new layout built around three zones: side nav icons flanking a central content area.

---

## Landscape Layout

### Top bar
`_TopBar` spans full width, unchanged. Step counter + progress bar + close button.

### Main row

Three horizontal zones inside an `Expanded` area below the top bar:

| Zone | Widget | Notes |
|---|---|---|
| Left | `‹` `IconButton` circle | Calls `_goToStep(index - 1)`. Dimmed (opacity 0.3) when `isFirst`. |
| Center | `_LandscapeCenter` (new) | Switches on media presence — see below. |
| Right | `›` + `ℹ` stacked icons | Next/finish + info toggle. |

### Right icon column
- **`›` / `✓`** — filled primary circle. Calls `_goToStep(index + 1)`. On last step shows `Icons.check_rounded` instead of `Icons.chevron_right_rounded`.
- **`ℹ`** — `Icons.info_outline_rounded`. Toggles `_infoOpen`. Highlighted (primary color) when panel is open.

### Center area — `_LandscapeCenter`

**Step has `imageUrl` or `videoUrl`:**
- Media fills 100% of the center panel (`ClipRRect`, `BoxFit.cover`).
- `RecipeVideoCard` or `CachedNetworkImage`, same as portrait.
- A bottom gradient scrim (transparent → `Colors.black87`, ~45% of height) overlays:
  - Instruction text: small (11 sp), white, left-aligned, max 2 lines, overflow ellipsis.
  - Timer pill (right side of scrim): `⏱ MM:SS ▶/⏸`, tappable → `_toggleTimer`. Only shown when `step.durationMin != null`.

**Step has no media:**
- Dark background panel (`AkeliColors.surfaceContainerLow`), `ClipRRect`.
- Instruction text centered, `GoogleFonts.plusJakartaSans`, 15 sp, max 4 lines.
- Timer pill centered below text (same pill widget as media state). Only shown when `step.durationMin != null`.

### Info side panel

Controlled by `bool _infoOpen` (new state field, reset to `false` on `_goToStep`).

Implemented as a `Stack` inside `_LandscapeCenter`:
- Main content (media or text) always rendered behind.
- When `_infoOpen == true`, an `AnimatedContainer` slides in from the right edge, covering ~45% of the center width.
- Panel background: `AkeliColors.surfaceContainer`, `BorderRadius` on left side only.
- Panel content (scrollable `Column`):
  1. **Full instruction text** — `GoogleFonts.plusJakartaSans`, 12 sp, no line limit. Useful in the media case where the scrim truncates at 2 lines.
  2. **Divider** (`AkeliColors.outline`, opacity 0.3).
  3. **Ingredients list** reusing `_checkedIngredients` set.
     - Each row: colored dot + ingredient name + quantity.
     - Checked items: dot grey + strikethrough text.
     - Long-press to check/uncheck (same as existing portrait behaviour — calls same `setState` block).
     - Tap an ingredient → `IngredientDetailSheet.show(context, ing)`.
- Animation: `AnimatedContainer` width goes from `0` to `panelWidth` with `Curves.easeOut`, 220 ms.

---

## What Does Not Change

- **Portrait layout** — zero modifications to existing `Column` structure.
- **State** — `_currentStepIndex`, `_timerSeconds`, `_timerRunning`, `_checkedIngredients` unchanged.
- **Timer logic** — `_toggleTimer`, `_resetTimer`, haptics, snack bar.
- **`_TopBar`** widget — reused as-is.
- **`_TimerWidget`** — not used in landscape; timer is a bespoke inline pill to fit the compact space.
- **`_IngredientStrip`** — not used in landscape; replaced by the info side panel.
- **`_NavButtons`** — not used in landscape; replaced by the icon buttons.
- **Swipe gesture** — `onHorizontalDragEnd` preserved, same thresholds.

---

## New Private Widgets

| Widget | Purpose |
|---|---|
| `_LandscapeBody` | Top-level landscape scaffold: `_TopBar` + main row. |
| `_LandscapeCenter` | Switches between media-focus and text-focus variants, owns the info panel `Stack`. |
| `_LandscapeMediaCenter` | Media fill + gradient scrim with text + timer pill. |
| `_LandscapeTextCenter` | Text + timer pill, no media. |
| `_LandscapeInfoPanel` | Animated ingredient list panel. |
| `_TimerPill` | Compact inline timer (pill shape, `⏱ MM:SS ▶/⏸`). Tappable. |

All widgets are file-private (leading `_`). No new files needed.

---

## Edge Cases

- **No steps** — existing empty-state scaffold runs before `OrientationBuilder`; no change needed.
- **No ingredients** — info `ℹ` icon is hidden when `_stepIngredients.isEmpty`.
- **No timer** — timer pill not rendered.
- **Last step** — `›` shows `Icons.check_rounded`, calls `context.pop()` with the same completion log.
- **`_infoOpen` reset** — `_goToStep` calls `setState(() { ...; _infoOpen = false; })` to close the panel on navigation.
