```markdown
# Design System Specification: Organic Editorial

## 1. Overview & Creative North Star: "The Curated Sanctuary"
The Creative North Star for this design system is **The Curated Sanctuary**. We are moving away from the rigid, modular "bootstrap" look toward a high-end digital editorial experience. This is achieved through intentional white space, sophisticated tonal layering, and an "Organic Editorial" aesthetic. 

We reject the "boxed-in" web. By utilizing a **No-Line Rule**, we define structure through depth and color shifts rather than strokes. The layout should feel like a premium physical magazine: breathing room is a functional element, not a void, and asymmetry is used to guide the eye toward focal points of high-value content.

---

## 2. Color & Tonal Architecture
The palette is rooted in a "Deep Teal" foundation, balanced by "Warm Bone" neutrals and a "Vivid Amber" accent to create a sense of grounded luxury.

### Core Palette
- **Primary (#006A63):** Use for high-impact brand moments and key interactive states.
- **Secondary Container (#C3EAE5):** A soft mint-teal used for large-scale structural blocks to provide a "breathable" background that feels cooler than the surface.
- **Tertiary/Accent (#FF9F1C):** Our "Vivid Amber." Use sparingly for high-conversion CTAs, notification pips, or to highlight a single, critical piece of data.
- **Surface (#FCFAEF):** The "Warm Bone" foundation. This is your canvas.

### The "No-Line" Rule
**Explicit Instruction:** Do not use 1px solid borders for sectioning or card definition. 
- **Method:** Define boundaries through background color shifts. For example, a `surface-container-low` section sitting on a `surface` background. 
- **The Signature Texture:** For primary CTAs or hero backgrounds, utilize a subtle linear gradient transitioning from `primary` (#00504A) to `primary-container` (#006A63) at a 135-degree angle. This adds "soul" and prevents the interface from feeling flat.

### Glass & Gradient Rule
To achieve a "frosted sanctuary" effect, floating elements (like navigation bars or modals) should utilize Glassmorphism:
- **Background:** `surface` at 80% opacity.
- **Effect:** `backdrop-filter: blur(20px)`.
- **Edge:** A "Ghost Border" using `outline-variant` at 15% opacity to catch the light without creating a hard line.

---

## 3. Typography: Editorial Authority
We pair the geometric confidence of **Plus Jakarta Sans** with the utilitarian clarity of **Inter**.

| Level | Font Family | Size | Intent |
| :--- | :--- | :--- | :--- |
| **Display LG** | Plus Jakarta Sans | 3.5rem | Hero headlines; use with wide letter-spacing (-0.02em). |
| **Headline MD**| Plus Jakarta Sans | 1.75rem | Section headers; maintain a "High-Contrast" scale. |
| **Title LG**   | Inter | 1.375rem | Card titles and sub-headers. |
| **Body LG**    | Inter | 1.0rem | Primary reading experience; 1.6 line-height for airiness. |
| **Label MD**   | Inter | 0.75rem | All-caps, tracked out (+0.05em) for metadata/chips. |

---

## 4. Elevation & Depth: The Layering Principle
Hierarchy is achieved through **Tonal Layering**, not shadows. Think of the UI as stacked sheets of fine, heavy-weight paper.

- **Nesting:** Place a `surface-container-lowest` (#FFFFFF) card on a `surface-container-low` (#F6F4E9) background to create a soft, natural lift.
- **Ambient Shadows:** Only use shadows for elements that "float" above the page (e.g., Modals). 
    - **Specs:** `0px 24px 48px rgba(27, 28, 22, 0.06)`. The shadow color must be a tint of the `on-surface` color (#1B1C16), never pure black.
- **Ghost Border Fallback:** If accessibility requires a container edge, use `outline-variant` (#BEC9C6) at **10% opacity**. It should be felt, not seen.

---

## 5. Components

### The 24px Radius Standard
All containers, cards, and large buttons must utilize the **MD Radius (1.5rem / 24px)** to maintain the "Organic" feel. Small components (chips/inputs) use **SM Radius (0.5rem)**.

- **Buttons:**
    - **Primary:** Gradient fill (Primary to Primary-Container), white text, 24px radius. 
    - **Secondary:** `secondary-container` fill with `on-secondary-container` text. No border.
- **Cards & Lists:** 
    - **Forbid Divider Lines.** Separate list items using `spacing-4` (1.4rem) of vertical white space or a subtle background shift to `surface-container-highest` on hover.
- **Input Fields:**
    - Use `surface-container-highest` for the field background. Labels should be `label-md` positioned 0.5rem above the field. 
    - Focus state: A 2px "Ghost Border" using the `primary` color at 40% opacity.
- **Editorial Chips:**
    - Pill-shaped (9999px), using `tertiary-fixed` with `on-tertiary-fixed` text for high-priority filters.

---

## 6. Do’s and Don'ts

### Do:
- **Embrace Asymmetry:** Offset images or text blocks using the `spacing-10` to `spacing-16` values to create an editorial rhythm.
- **Layer Tones:** Use the full spectrum of `surface-container` tiers to guide the user's eye from the background to the interaction point.
- **Max Breathing Room:** When in doubt, increase the margin. Use `spacing-20` (7rem) between major sections.

### Don’t:
- **Don't use 1px borders.** This is the most common way to break the "Organic Editorial" look.
- **Don't use pure black (#000000).** Use `on-surface` (#1B1C16) for all "black" text to keep the palette warm and premium.
- **Don't crowd the content.** If a card feels tight, increase the internal padding to `spacing-6` (2rem) and remove unnecessary icons.
- **Don't use default shadows.** Avoid harsh, small, or dark grey shadows that make the UI look like a generic template.