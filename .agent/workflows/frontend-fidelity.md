---
description: How to achieve high-fidelity Flutter frontend transformation
---

# Frontend Fidelity Workflow

This workflow defines the process for escalating the visual and technical quality of the Akeli mobile application to match high-fidelity Stitch mockups.

## 📝 Phase 1: Design-to-Code Audit
**Primary Skill: `ui-ux-designer`**
- Compare the Stitch `code.html` (Tailwind/CSS) against the current `lib/features/` screens.
- Identify discrepancies in:
  - **Color Tokens**: Exact Hex codes and opacity levels.
  - **Typography**: Inter font weights, tracking, and leading.
  - **Layout Geometry**: 24px corner radii, specific padding (16px vs 24px), and shadow depth.

## 🏗️ Phase 2: Component Scaffolding
**Primary Skill: `frontend-mobile-development-component-scaffold`**
- Create "Premium" versions of core widgets:
  - `AkeliPremiumCard`: High-fidelity shadows and border treatments.
  - `AkeliModernMetric`: Custom-painted circular progress with conic gradients.
  - `AkeliEditorialHeader`: Centered typography with premium iconography.
- Ensure components are decoupled and use the centralized theme.

## ⚡ Phase 3: High-Performance Implementation
**Primary Skill: `flutter-expert`**
- Implement **Custom Painters** for advanced graphics (avoiding heavy images/packages where possible).
- Optimize for the **Impeller** engine.
- Add micro-animations (hero transitions, haptic feedback) to increase "felt" quality.

## 📱 Phase 4: Platform Polish
**Primary Skill: `mobile-developer`**
- Ensure iOS/Android specific behaviors (safe areas, haptic feedback profiles).
- Optimize list scroll performance (virtualization and image caching).
- Handle edge cases like varying screen aspect ratios.

## 🧪 Phase 5: Refinement & Refactoring
**Primary Skill: `code-refactoring-refactor-clean`**
- Clean up ad-hoc styling in favor of the theme-driven approach.
- Modularize UI code for easier maintenance and future design updates.
