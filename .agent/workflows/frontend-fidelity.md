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

## 🏗️ Phase 2: Component Scaffolding & Visuals
**Primary Skills: `frontend-mobile-development-component-scaffold`, `data-scientist`**
- Create "Premium" versions of core widgets:
  - `AkeliPremiumCard`: High-fidelity shadows and border treatments.
  - `AkeliModernMetric`: Custom-painted metrics with conic gradients (Data Viz specialization).
  - `AkeliEditorialHeader`: Centered typography with premium iconography.
- Ensure components are decoupled and use the centralized theme.

## ⚡ Phase 3: Performance & Data Layer
**Primary Skills: `flutter-expert`, `api-design-principles`**
- Implement **Custom Painters** for advanced graphics (avoiding heavy images).
- Optimize for the **Impeller** engine.
- Refine data flow (caching, optimistic UI) to match the "instant" feel of modern web apps.
- Add micro-animations (hero transitions, haptic feedback) to increase "felt" quality.

## 📱 Phase 4: Platform Polish & Quality
- Modularize UI code for easier maintenance and future design updates.
