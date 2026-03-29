# Design System Strategy: The Digital Editorial

## 1. Overview & Creative North Star

This design system is built upon the **"Organic Editorial"** North Star. We are moving away from the cold, industrial feel of standard Material or Human Interface guidelines to create an experience that feels like a premium wellness journal—tactile, breathable, and sophisticated. 

Instead of rigid grids and harsh dividers, this system utilizes **Tonal Depth** and **Asymmetric Balance**. We celebrate the negative space provided by the cream-toned background, treating the UI as a series of layered organic surfaces rather than a flat digital screen. This approach fosters trust and calm, essential for a wellness and tracking application.

---

## 2. Colors & Surface Philosophy

The palette is anchored by the warmth of `#FCFAEF` (Surface) and the vitality of `#4DB6AC` (Primary Container/Teal).

### The "No-Line" Rule
Standard 1px borders are strictly prohibited for defining sections. Structure must be achieved through:
*   **Background Shifts:** Use `surface-container-low` for secondary sections and `surface-container-high` for interactive elements.
*   **Negative Space:** Utilize the spacing scale (specifically `8`, `12`, and `16`) to create mental boundaries.

### Surface Hierarchy & Nesting
Treat the UI as physical layers of fine paper.
*   **Base:** `surface` (#fcfaef)
*   **Secondary Content Areas:** `surface-container-low` (#f6f4e9)
*   **Interactive Cards:** `surface-container-lowest` (#ffffff) to create a subtle "pop" against the cream background.
*   **Overlay Elements:** `surface-bright` for floating modals.

### The "Glass & Gradient" Rule
To add a signature premium feel, floating action buttons (FABs) and navigation overlays should use a subtle gradient from `primary` (#006a63) to `primary_container` (#4db6ac). For headers or navigation bars that stick during scroll, apply a **Backdrop Blur (20px)** with a 70% opacity version of the `surface` color to maintain depth.

---

## 3. Typography

The system utilizes **Plus Jakarta Sans** for its modern, geometric yet approachable personality.

*   **Display (Display-LG to SM):** Used for "hero" moments like weight numbers or welcome messages. These are high-impact and should use `on_surface` (#1b1c16) with tight letter spacing (-0.02em).
*   **Headlines & Titles:** Used for section headers. They establish the editorial hierarchy.
*   **Body (Body-LG to SM):** Optimized for readability. Use `on_surface_variant` (#3d4947) for body copy to soften the contrast against the cream background, reducing eye strain.
*   **Labels:** Strict use for metadata (e.g., "104 kg / 75 kg") using `label-md` and `outline` (#6d7a77) colors.

---

## 4. Elevation & Depth

We eschew traditional "drop shadows" in favor of **Tonal Layering**.

*   **The Layering Principle:** A card does not need a shadow if it is `surface-container-lowest` sitting on a `surface-container-low` background. The slight shift in hex value provides enough contrast for the human eye.
*   **Ambient Shadows:** Where floating is required (e.g., the Teal FAB), use a custom shadow: `0px 8px 24px rgba(0, 106, 99, 0.15)`. This tints the shadow with the primary brand color, making it feel integrated rather than "dirty."
*   **Ghost Borders:** For accessibility on input fields, use `outline-variant` (#bdc9c6) at **20% opacity**. It should be felt, not seen.

---

## 5. Components

### Circular Progress Indicators
*   **Track:** Use `surface-container-highest` (#e4e3d8) for the background track.
*   **Indicator:** Use `primary_container` (#4db6ac) with a `round` stroke cap.
*   **Content:** Place `display-sm` text in the center to emphasize the data.

### Buttons & Chips
*   **Primary Button:** Gradient-filled (`primary` to `primary_container`), rounded-full (`9999px`).
*   **Secondary/Ghost Button:** `outline` color for the label, no background, or a `surface-container-high` background for a "pill" look.
*   **Chips:** Use `secondary_container` (#c3eae5) with `on_secondary_container` text for active states.

### Cards
*   **Style:** `xl` (1.5rem) corner radius.
*   **Spacing:** Content within cards must use at least `4` (1rem) of internal padding.
*   **Restriction:** Never use a horizontal divider inside a card. Use a `1.5` spacing unit (0.375rem) gap to separate header from body.

### Custom Bottom Navigation
*   **Background:** `surface-container-low` with a subtle top "Ghost Border" (10% opacity).
*   **Icons:** Use `on_surface_variant` for inactive and `primary` for active states. 
*   **Layout:** High-clearance icons with `label-sm` text only for the active state to reduce visual clutter.

---

## 6. Do’s and Don’ts

### Do
*   **Do** use asymmetrical spacing in hero sections to create an editorial feel.
*   **Do** rely on font weight (Bold vs. Regular) to distinguish hierarchy rather than color alone.
*   **Do** use `primary_fixed_dim` for large decorative icons to keep them from overpowering the text.

### Don’t
*   **Don’t** use pure black (#000000). Use `on_surface` (#1b1c16) to maintain the organic warmth.
*   **Don’t** use the `DEFAULT` (0.5rem) roundedness for main containers; it feels too "standard." Lean into `lg` (1rem) or `xl` (1.5rem).
*   **Don’t** use 1px solid dividers. If you must separate content, use a background color block or 16px of vertical white space.