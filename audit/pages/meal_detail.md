# Audit: Meal Detail Page
**Status**: Step 8 — Ready for transcription (approved 2026-03-29)
**Stitch source**: `stitch/meal_detail/`
**Flutter file**: `lib/features/meal_planner/meal_detail_page.dart`
**FF source**: `flutterflow_application/akeli/lib/meal_planner/meal_detail/meal_detail_widget.dart`
**Stitch source**: `stitch/audit_exemple/`

---

## Step 1: [BASE] Widget Tree

> Extracted from FF source. The page has two display modes: **non-personal** (linked to a recipe in the DB) and **personal** (user-created custom meal with optional image). Conditional blocks are annotated.

- **Scaffold** (`secondaryBackground`)
  - **NestedScrollView** (`floatHeaderSlivers: true`)
    - **SliverAppBar** (floating, not pinned, elevation: 0, `secondaryBackground`)
      - **leading**: IconButton (arrow_back_rounded, `primary`, 30px)
      - No title
    - **Body** → SafeArea (top: false) → Padding (15, 20, 15, 50)
      - **SingleChildScrollView**
        - **Column** (crossAxisAlignment: start)
          - **Text** — Meal Name (center-aligned, `titleLarge`, Outfit, `primary`)
          - **[IF non-personal]** FutureBuilder → **CarouselSlider** (h: 200, viewportFraction: 0.85, enlargeCenterPage, radius: 8) → tappable images (Hero expand)
          - **[IF personal + imageUrl exists]** ClipRRect (radius: 8) → Image.network (300x200, BoxFit.cover)
          - **Text** — Meal Type label (center-aligned, `headlineSmall`, Outfit) → "Petit-Déjeuner" / "Déjeuner" / "Dîner" / "Collation"
          - **Text** — Meal Date (center-aligned, Poppins, `bodyMedium`, format: "MMMMEEEEd")
          - **[IF mealDate <= now]** Container (`secondaryBackground`) → FutureBuilder (Meal consumed status)
            - **Row**
              - **Text** "Vous avez consommé ce repas" (`titleLarge`, Outfit)
              - **Expanded** → Row (end-aligned)
                - **[IF consumed == true]** InkWell → Icon (check_box, `primary`, 24px) — taps to set consumed: false
                - **[IF consumed == false]** InkWell → Icon (check_box_outline_blank, `primary`, 24px) — taps to set consumed: true
          - **[IF non-personal]** Column (divide: 10px)
            - FutureBuilder (Receipe row — cooking time + difficulty)
              - **Row** (center, divide: 10px)
                - Container → Row (divide: 2px): Icon(access_time_outlined, 22px) + Text(hours) + Text("h") + Text(mins) + Text("min") — Poppins `bodyMedium` `secondaryText`
                - Container → Row (divide: 5px): Text("Difficulté") + Text(difficulty) — Poppins `bodyMedium` `secondaryText`
            - **Wrap** (spacing: 10, center-aligned) — Macro badges
              - Badge (bg: `secondary`, radius: 8, pad: 8/5): Text "X kcal" — Poppins w500 `secondaryBackground`
              - Badge (bg: `tertiary`, radius: 8, pad: 8/5): Text "X g protéine" — Poppins w500 `secondaryBackground`
              - Badge (bg: `tertiary`, radius: 8, pad: 8/5): Text "X g de glucide" — Poppins w500 `secondaryBackground`
              - Badge (bg: `tertiary`, radius: 8, pad: 8/5): Text "X g de lipide" — Poppins w500 `secondaryBackground`
            - FutureBuilder (ReceipeTags)
              - **Wrap** (spacing: 10, center-aligned) — Dietary tag chips
                - Container (bg: #73E5E5E5, radius: 12, pad: 8/5): Text (tag name, `labelSmall`, Poppins)
          - **[IF non-personal]** Text "Description" (center-aligned, `titleLarge`, Outfit, `primary`) → Padding 16/0
          - **[IF non-personal]** Text (description body, `labelMedium`, Poppins) → Padding 16/0
          - **[IF personal]** Text (description body, `bodyMedium`, Poppins, center-aligned)
          - **[IF non-personal]** Text "Ingredients" (center-aligned, `titleLarge`, Outfit, `secondary`)
          - **[IF non-personal]** StreamBuilder (meal_ingredients, ordered by index)
            - **ListView.separated** (shrinkWrap, primary: false, separator: 15px)
              - Each item: Material (elevation: 3, radius: 12) → Container (`secondaryBackground`, radius: 12, pad: 12)
                - **Column** (crossAxisAlignment: start)
                  - **[IF !title]** Row: Text(quantity, `titleMedium`, Poppins, `secondary`) + Expanded Text(name, `labelMedium`, Poppins)
                  - **[IF title]** Row: Expanded Text(name, `titleMedium`, Poppins, `secondary`) — acts as section sub-header
          - **[IF non-personal]** Text "Etapes" (center-aligned, `titleLarge`, Outfit, `tertiary`)
          - **[IF non-personal]** StreamBuilder (step table, ordered by index)
            - **ListView.separated** (shrinkWrap, separator: 15px)
              - Each step: Material (elevation: 3, radius: 12) → Container (`secondaryBackground`, radius: 12, pad: 12)
                - **Row** (crossAxisAlignment: start, divide: 10px)
                  - **[IF !title]** Text(step number, `titleMedium`, Poppins, `tertiary`)
                  - **[IF title]** Container (w: 280): Text(text, `titleSmall`, Poppins, `tertiary`) — section sub-header
                  - **[IF !title]** Expanded → Container: Text(step text, `bodyMedium`, Poppins)
          - **Column** (divide: 10px) — CTA: Change recipe
            - Text "Voulez-vous choisir une autre recette ?" (`titleLarge`, Outfit)
            - FFButton "Choisir" (bg: `primary`, text: white, radius: 8, h: 40) → navigates to RecipeResearchingList
          - **Column** (divide: 10px) — CTA: Personalise meal
            - Text "Voulez choisir un repas personnalisé ?" (`titleLarge`, Outfit)
            - FFButton "Personaliser" (bg: `primary`, text: white, radius: 8, h: 40) → opens AddMealWidget bottom sheet (h: 500)

---

## Step 2: [DESIGN] Baseline Attributes

| Widget | Attribute | Value |
|---|---|---|
| Scaffold | bg | `secondaryBackground` (white) |
| SliverAppBar | bg | `secondaryBackground`, elevation: 0, floating |
| Back button | icon | arrow_back_rounded, color: `primary` (#006A63), size: 30 |
| Meal Name | font | Outfit, `titleLarge`, color: `primary` (#006A63), center |
| Image Carousel | size | 200px height, viewportFraction: 0.85, radius: 8px |
| Single personal image | size | 300x200, radius: 8px, BoxFit.cover |
| Meal Type | font | Outfit, `headlineSmall`, center |
| Meal Date | font | Poppins, `bodyMedium`, center, format: MMMMEEEEd |
| Consumed row | text | Outfit `titleLarge` |
| Consumed icon (checked) | icon | check_box, `primary`, 24px |
| Consumed icon (unchecked) | icon | check_box_outline_blank, `primary`, 24px |
| Cooking time | font | Poppins `bodyMedium`, `secondaryText` |
| Difficulty | font | Poppins `bodyMedium`, `secondaryText` |
| Calorie badge | bg/text | `secondary` / `secondaryBackground` white, radius: 8, Poppins w500 |
| Protein/Carb/Fat badge | bg/text | `tertiary` / `secondaryBackground` white, radius: 8, Poppins w500 |
| Dietary tag chip | bg | #73E5E5E5 (grey 45%), radius: 12, Poppins `labelSmall` |
| "Description" header | font | Outfit `titleLarge`, `primary`, center, pad: 16 |
| Description body (non-personal) | font | Poppins `labelMedium`, center, pad: 16 |
| Description body (personal) | font | Poppins `bodyMedium`, center |
| "Ingredients" header | font | Outfit `titleLarge`, `secondary` (#4DB6AC), center |
| Ingredient card | bg/shape | `secondaryBackground`, radius: 12, elevation: 3, pad: 12 |
| Ingredient quantity | font | Poppins `titleMedium`, `secondary` |
| Ingredient name | font | Poppins `labelMedium` |
| Ingredient section title | font | Poppins `titleMedium`, `secondary` (full-width) |
| "Etapes" header | font | Outfit `titleLarge`, `tertiary` (#FF9F43), center |
| Step card | bg/shape | `secondaryBackground`, radius: 12, elevation: 3, pad: 12 |
| Step number | font | Poppins `titleMedium`, `tertiary` |
| Step text | font | Poppins `bodyMedium` |
| Step section title | font | Poppins `titleSmall`, `tertiary`, w: 280 |
| CTA button | bg/shape | `primary`, white text, radius: 8, h: 40 |

---

## Step 3: [STITCH] Prompt

> Copy-paste this prompt into Stitch to generate the high-fidelity target mockup.
> This prompt is based on the **complete** widget tree from Steps 1 and 2.

---

**Objective**: Transform the following Meal Detail page into a high-fidelity, modern "Digital Editorial" mobile screen. Preserve every functional section listed below — nothing should be removed. Elevate the visual quality without changing the information hierarchy.

**Design System to apply**:
- **Surface palette**: Background `#FCFAEF` (warm cream). Cards on top use `#FFFFFF` (pure white) to create tonal depth without borders.
- **No-Line Rule**: Zero 1px dividers. Use background color shifts and spacing to create sections.
- **Corner Radius**: `24px` for all primary cards and containers. `16px` for secondary elements (macro boxes, chips). `12px` for small pills.
- **Typography**: `Plus Jakarta Sans` for all headers and labels. `Inter` for body text and descriptions. Remove Outfit and Poppins.
- **Colors**: Primary `#006A63` (deep teal). Secondary container `#C3EAE5` (light teal). Tertiary `#FF9F43` (orange). Surface `#FCFAEF`. On-surface `#1B1C16`. On-surface-variant `#3D4947`.
- **Glassmorphism**: AppBar uses `backdrop-blur-xl` + `bg-surface/70`. Bottom navigation uses `backdrop-blur-xl` + `bg-surface-container-low/80`.
- **Shadows**: No generic grey shadows. Where elevation is needed, use `rgba(0, 106, 99, 0.12)` (brand-tinted).
- **Badges/chips**: Use colored backgrounds at low opacity. Active chips use `#C3EAE5` bg + `#006A63` text.

---

**Functional sections to include in the mockup** (all are mandatory):

1. **AppBar** — Glassmorphism fixed header with: back arrow (circle tap area, left), centered page title "Détail du repas", heart/favorite icon (right).

2. **Hero Image Area** — Full-width image area (height ~220px). For non-personal meals: image carousel with rounded corners. For personal meals: single image. Design the image area with a subtle gradient overlay at the bottom (transparent → surface color) to blend into the content below. The content card below should overlap this image area by ~32px using a negative top margin.

3. **Meal Header Card** — White card (`#FFFFFF`, radius 24px, padding 24px) overlapping the hero image. Contains:
   - Meal name (large Bold title, `Plus Jakarta Sans`)
   - Meal type badge ("Déjeuner" etc. — teal bg `#C3EAE5`, teal text `#006A63`)
   - Calorie badge ("450 kcal" — orange bg at 10% opacity, orange text `#FF9F43`)
   - Cooking duration badge ("25 min" — cream bg `#EAE8DE`, muted text)
   - Meal date (small muted text, below badges, format: "Lundi 21 janvier")

4. **Consumed Toggle Row** — Shown when the meal date is today or past. A soft teal container (`#C3EAE5`, radius 12px, padding 12px) with label "Vous avez consommé ce repas" on the left and a checkbox icon on the right. Checked state uses a filled teal checkbox, unchecked uses an outline checkbox.

5. **Recipe Metadata Row** — One horizontal row with two info chips side by side (centered):
   - Cooking time: clock icon + "Xh Xmin"
   - Difficulty: text label "Difficulté: Facile"
   Both chips use cream bg (`#F6F4E9`, radius 12px).

6. **Macronutrients Section** — Section header "Macronutriments" (Bold, `Plus Jakarta Sans`). Below: a horizontal row of 3 equal boxes (`#F6F4E9`, radius 16px, padding 12px, centered content):
   - Box 1: label "PROTÉINES" (10px, uppercase, muted) / value "18g" (20px, Bold, on-surface)
   - Box 2: label "GLUCIDES" / value "52g"
   - Box 3: label "LIPIDES" / value "14g"

7. **Dietary Tags** — A wrap of soft chips (bg `#C3EAE5`, radius 12px, text `#006A63`): e.g. "Végétarien", "Sans gluten", "Riche en protéines".

8. **Description Section** — Section header "Description". Body text in Inter, 14px, color `#3D4947`, left-aligned, line-height 1.6.

9. **Ingredients Section** — Section header "Ingrédients" with trailing action link "Ajouter à la liste" (teal, small). List of ingredient cards (bg `#F6F4E9`, radius 24px, padding 16px). Each card contains:
   - Left: small square image (48x48, radius 16px)
   - Center: ingredient name (Bold, 14px) + detail line (e.g. "Bio, non-cuit", 12px, muted)
   - Right: quantity amount (Bold, `#006A63`)
   Include both regular ingredient rows and section title rows (e.g. "Pour la sauce" as a bold sub-header row without an image).

10. **Steps Section** — Section header "Étapes". List of step items. Each step:
    - Left: circle badge (24x24, bg: `#006A63` at 20% opacity, text: `#006A63`, Bold) — step number
    - Right: step text (Inter, 14px, `#3D4947`, line-height 1.6)
    Include section title rows (e.g. "Préparation" as a full-width Bold teal sub-header).

11. **Bottom CTAs** — Two soft action rows at the bottom of the scroll:
    - "Choisir une autre recette" — ghost button or outline style, full width, radius 12px
    - "Personnaliser ce repas" — primary filled button, full width, `#006A63`, white text, radius 12px

12. **Bottom Navigation Bar** — Glassmorphism fixed bar at the bottom with 5 icons (home, calendar/meal-planner, recipes, community, profile). Active icon in `#006A63`.

---

## Step 4: [STITCH] High-Fidelity Widget Tree

> Extracted from `stitch/meal_detail/code.html`. All tokens reference the Tailwind color map in the file.

- **Scaffold** (bg: `surface` #FCFAEF, font: Inter)
  - **AppBar** (fixed, top-0, z-50, h: 64px, px: 16, flex justify-between items-center)
    - bg: `#FCFAEF/70`, backdrop-blur-xl, border-b `#BDC9C6/10`
    - IconButton (p-2, rounded-full, hover: `#F6F4E9`): Icon `arrow_back` (color: `#006A63`, Bold)
    - Text "Recipe Detail" (`Plus Jakarta Sans`, Bold, 18px, `on-surface` #1B1C16)
    - IconButton (p-2, rounded-full, hover: `#F6F4E9`): Icon `favorite` (color: `#006A63`)
  - **Body** (pb: 128px)
    - **HeroSection** (relative, h: 220px, overflow-hidden)
      - Image (w-full, h-full, `object-cover`) — real photo from network
      - GradientOverlay: `bg-gradient-to-t from-surface via-transparent to-transparent` (bottom fade into page bg)
    - **MealHeaderCard** (px: 16, -mt-8 [overlap], relative, z-10)
      - Container (bg: `surface-container-lowest` #FFFFFF, `rounded-2xl`, p: 24px, shadow-sm)
        - **BadgesRow** (flex, flex-wrap, gap: 8px, mb: 12px)
          - Badge "Déjeuner" (px-3 py-1, bg: `secondary-container` #C3EAE5, text: `on-secondary-container`, text-xs, semibold, rounded-full)
          - Badge "450 kcal" (px-3 py-1, bg: `tertiary-container/20`, text: `tertiary` #94492D, text-xs, semibold, rounded-full)
          - Badge "25 min" (px-3 py-1, bg: `surface-container-low` #F6F4E9, text: `on-surface-variant`, text-xs, semibold, rounded-full)
        - Text — Meal Name "oeuf mollets" (text-2xl, `Plus Jakarta Sans`, extrabold, `on-surface`, mb: 4px)
        - Text — Date "jeudi 12 mars" (text-sm, `Plus Jakarta Sans`/label, `outline` #6D7A77, uppercase, tracking-wider)
    - **ConsumedToggle** (px: 16, mt: 16px)
      - Container (bg: `secondary-container` #C3EAE5, `rounded-xl`, p: 16px, flex, items-center, justify-between)
        - Row (flex, items-center, gap: 12px)
          - CheckBadge (w-6, h-6, rounded, bg: `primary` #006A63, flex items-center justify-center): Icon `check` (white, sm, FILL:1 — filled)
          - Text "Vous avez consommé ce repas" (font-medium, `on-secondary-container`)
    - **MetadataChips** (px: 16, mt: 24px, flex, gap: 12px)
      - Chip (flex-1, bg: `surface-container-low` #F6F4E9, rounded-xl, p: 12px, flex, items-center, gap: 12px)
        - Icon `schedule` (`primary`)
        - Column: Label "TEMPS" (10px, `outline`, uppercase, Bold) + Value "25 min" (text-sm, semibold)
      - Chip (flex-1, same): Icon `restaurant` (`primary`) + Label "DIFFICULTÉ" + Value "Facile"
    - **MacronutrientsSection** (px: 16, mt: 32px)
      - Header "Macronutriments" (`Plus Jakarta Sans`, Bold, 18px, mb: 16px)
      - Grid (grid-cols-3, gap: 12px)
        - MacroBox (bg: `surface-container-low` #F6F4E9, `rounded-2xl`, p: 16px, text-center)
          - Label "PROTÉINES" (10px, `outline`, Bold, mb: 4px)
          - Value "18g" (text-xl, `Plus Jakarta Sans`, font-black, `primary` #006A63)
        - MacroBox — "GLUCIDES / 52g" (same)
        - MacroBox — "LIPIDES / 14g" (same)
    - **DietaryTags** (px: 16, mt: 24px, flex, flex-wrap, gap: 8px)
      - Tag (px-4, py-2, bg: `secondary-container` #C3EAE5, text: `on-secondary-container`, text-sm, medium, rounded-full)
      - Examples: "Sans gluten", "Pauvre en graisses", "Faible calories"
    - **DescriptionSection** (px: 16, mt: 32px)
      - Header "Description" (`Plus Jakarta Sans`, Bold, 18px, mb: 8px, `on-surface`)
      - Text (text-sm, `on-surface-variant` #3D4947, leading-relaxed, Inter)
    - **IngredientsSection** (px: 16, mt: 32px)
      - Header "Ingrédients" (`Plus Jakarta Sans`, Bold, 18px, mb: 16px)
        - ~~ActionButton "Ajouter à la liste"~~ — **removed**: ingredients are automatically added to the shopping list
      - Column (flex-col, gap: 12px)
        - IngredientCard (bg: `surface-container-low` #F6F4E9, `rounded-2xl`, p: 12px, flex, items-center, justify-between)
          - Left Row (flex, items-center, gap: 12px): Image (w-12, h-12, `rounded-2xl`, object-cover) + Text name (font-medium)
          - Text quantity (`primary`, Bold)
    - **StepsSection** (px: 16, mt: 32px)
      - Header "Étapes" (`Plus Jakarta Sans`, Bold, 18px, mb: 16px)
      - Column (flex-col, gap: 24px)
        - StepItem (flex, gap: 16px)
          - StepBadge (flex-shrink-0, w-8, h-8 [32px], rounded-full, bg: `primary/20`, flex items-center justify-center, Bold, `primary`): step number
          - Text (text-sm, `on-surface-variant`, leading-snug, pt: 4px)
    - **BottomCTAs** (px: 16, mt: 48px, flex-col, gap: 12px)
      - GhostButton "Choisir une autre recette" (w-full, py-4, border-2 `primary`, text: `primary`, Bold, rounded-full, hover: `primary/5`)
      - PrimaryButton "Personnaliser ce repas" (w-full, py-4, bg-gradient-to-r from-`primary` to-`primary-container`, text: white, Bold, rounded-full, shadow: `0px 8px 24px rgba(0,106,99,0.15)`)
  - **BottomNavBar** (fixed, bottom-0, flex, justify-around, px: 24, pb: 24, pt: 12, bg: `#F6F4E9/70`, backdrop-blur-xl, border-t `#BDC9C6/10`, shadow: `0px -8px 24px rgba(0,106,99,0.05)`, z-50)
    - NavItem inactive (p-2, color: `#3D4947`, hover: `#006A63`): Icon only
    - NavItem active: Container (bg: `#4DB6AC`, rounded-2xl, p-2, scale-110) + Icon (white)
    - Icons (L→R): `home`, `calendar_today`, `restaurant_menu` (active), `groups`, `person`

---

## Step 5: [COMPARISON] Delta Analysis

> FF Baseline (Steps 1–2) vs. Stitch Target (Step 4). Every row is an actionable implementation decision.

| Delta Type | FF Baseline | Stitch Target | Action Required |
|---|---|---|---|
| **[LAYOUT]** | `SliverAppBar` floating, back arrow only, no title | Fixed glassmorphism AppBar: back + centered title + heart icon | Replace `SliverAppBar` with fixed `Stack`/`ClipRect`+`BackdropFilter` AppBar |
| **[LAYOUT]** | `CarouselSlider` (non-personal) or `Image.network` (personal) — above the title | Single full-width `Image` with bottom gradient fade, hero section | Wrap in hero container; gradient overlay with `LinearGradient`; keep carousel logic under the hood |
| **[LAYOUT]** | Meal name is **above** the image area, center-aligned | Meal name is **inside** the overlap card, left-aligned, below badges | Move meal name into header card; change alignment to start |
| **[LAYOUT]** | Meal type: plain `Text`, center, below carousel | Meal type: rounded-full badge inside `BadgesRow` | Convert to badge widget |
| **[LAYOUT]** | Date: plain `Text`, center, Poppins, bodyMedium | Date: small uppercase tracking-wider text inside header card, below meal name | Move inside card; restyle (uppercase, tracking, outline color) |
| **[LAYOUT]** | Consumed row: full-width `Row` with text + `check_box`/`check_box_outline_blank` icon | Teal `secondary-container` container, filled square check badge (not Material checkbox icon) | Redesign as teal card; replace icon with filled square badge (`bg-primary` + white check icon) |
| **[LAYOUT]** | Recipe info: inline text row (clock icon + "Xh Xmin" + "Difficulté: X") | Two equal `flex-1` metric cards (icon + uppercase label + value) | Replace inline row with two side-by-side `Expanded` containers |
| **[LAYOUT]** | Macros: `Wrap` of 4 colored pill badges (kcal, protein, carbs, fat) | 3-col grid of cream boxes (protein, carbs, fat only — **kcal moved to BadgesRow**) | Remove kcal from macros section; build 3-col grid with `Row` + 3 `Expanded` |
| **[LAYOUT]** | Ingredient cards: `Material(elevation:3)` + white bg + `Column(quantity, name)` | `surface-container-low` card + `Row(image, name \| quantity)` — image added | Add ingredient image (48×48, radius 16); flip layout from column to justify-between row; remove elevation |
| **[LAYOUT]** | Ingredient action label: "Ajouter..." (text only) | "Ajouter à la liste" + `add_shopping_cart` icon | **Remove entirely** — ingredients auto-added to shopping list, no manual action needed |
| **[LAYOUT]** | Step items: `Material(elevation:3)` cards — step number in `titleMedium` Text | Pure `Row` — step badge is **32px** circle (`primary/20` bg), no card container | Remove Material card; build bare `Row`; use 32px circle badge (not 24px) |
| **[LAYOUT]** | Bottom CTAs: 2 × `Column(Text label + FFButton)` | 2 × full-width `rounded-full` buttons (ghost + gradient), no text above them | Remove title text; replace `FFButton` with styled `ElevatedButton`/`OutlinedButton`; use gradient decoration |
| **[DESIGN]** | Fonts: Outfit (headers) + Poppins (body) | `Plus Jakarta Sans` (headers, labels, values) + `Inter` (body text) | Full font swap across the page |
| **[DESIGN]** | Kcal badge: bg `secondary` (solid teal), white text | bg `tertiary-container/20` (#EA8E6D at 20%), text `tertiary` (#94492D warm brown) | Change kcal badge colors — NOT orange #FF9F43 as assumed; use warm brown/terracotta |
| **[DESIGN]** | Macro box values: white text on colored bg | `primary` (#006A63) text on cream `#F6F4E9` bg — inverted | Invert macro color scheme |
| **[DESIGN]** | Section headers: colored (`secondary` teal for Ingredients, `tertiary` orange for Steps, `primary` for Description) | All headers: `on-surface` (#1B1C16) neutral | Neutralize all section header colors |
| **[DESIGN]** | Dietary tags: bg `#73E5E5E5` (grey 45%), `labelSmall`, radius 12 | bg `secondary-container` #C3EAE5, `on-secondary-container` text, rounded-full | Change tag style from grey pill to teal rounded-full |
| **[DESIGN]** | Ingredient/step card radii: 12px with Material elevation | `rounded-2xl` (Stitch = 1.5rem = 24px in standard; actual px = ~24px here), tonal bg, no elevation | Update radii; remove elevation; use `surface-container-low` bg |
| **[DESIGN]** | AppBar: standard Material, no blur | bg `#FCFAEF/70`, `BackdropFilter(blur: 20)`, border-b `#BDC9C6` @ 10% | Glassmorphism AppBar |
| **[DESIGN]** | BottomNav: not in current FF page scope | bg `#F6F4E9/70`, `BackdropFilter`, active item = teal card (`#4DB6AC`, rounded-2xl), shadow brand-tinted | Match bottom nav spec |
| **[DESIGN]** | Primary CTA button: bg `primary` solid, radius 8 | bg gradient `primary` → `primary-container`, rounded-full, brand-tinted shadow | Gradient button with shadow |

---

## Step 6: [APPROVAL]
- [x] User approved — 2026-03-29

---

## Step 7: [VISUAL] Screenshot Analysis & Blueprint

> From `stitch/meal_detail/screen.png`

### Visual Nuances (from screenshot)
- **Overlap is shallow**: The card overlaps the hero by only ~32px (`-mt-8`), not the 128px from the old audit-exemple. Subtle — the image is still clearly visible.
- **Kcal badge is warm terracotta**, not orange. `tertiary` token = `#94492D`. Background is `tertiary-container` (#EA8E6D) at 20% opacity — creates a faded salmon/terracotta. This is a key deviation from what was documented before.
- **Meal name is left-aligned** inside the card — reads as editorial headline.
- **Date is understated** — uppercase tracking-wider in muted `outline` color (#6D7A77). Acts as a metadata line, not a title.
- **Consumed badge**: filled square (NOT Material `check_box` icon). White checkmark on `primary` bg square — feels like a custom toggle, not a standard checkbox.
- **Macro values are primary colored** (#006A63 teal) on cream boxes — inverted from the FF colored badge approach.
- **Step badge is 32px** (w-8/h-8), giving it more presence than a small 24px circle.
- **Bottom buttons**: Ghost button uses border-2 — creates clear visual weight without a background. Primary button uses gradient + brand shadow.
- **Bottom nav active item**: `#4DB6AC` card with `scale-110` — the active tab visually "pops" above the others.
- **No section dividers anywhere** — spacing alone separates sections.

### Implementation Blueprint

1. **`AkeliGlazeAppBar`** (reusable widget):
   - `Stack`: bottom layer = `ClipRect` + `BackdropFilter(blur: 20)` + `Container(color: Color(0xB3FCFAEF))` (70% opacity)
   - Top layer = `SafeArea` Row: back `IconButton` (circle) + centered `Text` + heart `IconButton`
   - Height: 64px. Use as `SliverPersistentHeader(pinned: true)` inside `CustomScrollView`.

2. **Hero Section**:
   - `SizedBox(height: 220)` + `Stack`:
     - `Image.network(fit: BoxFit.cover)` (or `CarouselSlider` when multiple images)
     - `Positioned.fill`: `DecoratedBox(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [transparent, surface]))`

3. **MealHeaderCard** (overlap):
   - `Transform.translate(offset: Offset(0, -32))` wrapping a `Container(color: white, borderRadius: 24, padding: 24)` — do NOT use negative margin.
   - Inside: `BadgesRow` (Wrap, spacing: 8) + meal name `Text` (2xl extrabold) + date `Text` (small uppercase).

4. **Consumed Toggle**:
   - `Container(color: Color(0xFFC3EAE5), borderRadius: 16, padding: 16)` + `Row`
   - Left: `Container(24×24, borderRadius: 4, color: primary)` + `Icon(Icons.check, color: white, size: 16)`
   - Right: `Text(font-medium, color: on-secondary-container)`
   - Toggle state: swap filled check container with outlined square container.

5. **MetadataChips**:
   - `Row(children: [Expanded(chip1), SizedBox(12), Expanded(chip2)])`
   - Each chip: `Container(color: #F6F4E9, borderRadius: 12, padding: 12)` + `Row`: `Icon` + `Column(Label [10px uppercase], Value [14px semibold])`

6. **MacroGrid**:
   - `Row` with 3 `Expanded` children (gap via `SizedBox(12)`)
   - Each: `Container(color: #F6F4E9, borderRadius: 24, padding: 16)` + `Column(center)`: label (10px ALL_CAPS outline) + value (20px, font-black, `primary`)

7. **IngredientCard**:
   - `Container(color: #F6F4E9, borderRadius: 24, padding: 12)` + `Row(mainAxisAlignment: spaceBetween)`
   - Left: `Row`: `ClipRRect(radius: 16, Image.network(48×48))` + `Text(name, fontMedium)`
   - Right: `Text(quantity, bold, primary)`

8. **StepItem**:
   - `Row(crossAxisAlignment: start, gap: 16)`:
     - `Container(32×32, shape: circle, color: primary.withOpacity(0.2))` + centered Bold `Text(number, primary)`
     - `Expanded(Text(step, Inter 14px, on-surface-variant, leading: 1.4))`

9. **BottomCTAs**:
   - `OutlinedButton` styled: `side: BorderSide(color: primary, width: 2)`, `shape: StadiumBorder`, full-width, py: 16
   - `DecoratedBox(gradient: LinearGradient(primary→primary-container)) + ElevatedButton` or use `Ink` + `Container`, full-width, rounded-full, brand shadow

10. **BottomNavBar**: `ClipRect` + `BackdropFilter(blur: 20)` + `Container(color: Color(0xB3F6F4E9))`. Active item: `Container(color: #4DB6AC, borderRadius: 16, padding: 8)` with `Transform.scale(1.1)`.

---

## Step 8: [TRANSCRIPTION] Notes

**Target file**: `lib/features/meal_planner/meal_detail_page.dart`
**Mock data**: `lib/shared/mocks/mock_meal_plan.dart` (extend with meal detail fields)
**Design tokens**: `lib/core/theme.dart`
**Rules**: No Supabase, no Firebase. All data from mock constants. Riverpod for consumed toggle state only.

### Widgets to create (new)
| Widget | File | Notes |
|---|---|---|
| `AkeliGlazeAppBar` | `lib/shared/widgets/akeli_glaze_app_bar.dart` | Reusable glassmorphism AppBar — back arrow + centered title + optional trailing icon |
| `AkeliMetadataChip` | `lib/shared/widgets/akeli_metadata_chip.dart` | Icon + uppercase label + value — used for time and difficulty |
| `AkeliMacroBox` | `lib/shared/widgets/akeli_macro_box.dart` | Cream box with ALL_CAPS label and primary-colored value |
| `AkeliStepItem` | `lib/shared/widgets/akeli_step_item.dart` | 32px circle badge + expanded step text |
| `AkeliIngredientCard` | `lib/shared/widgets/akeli_ingredient_card.dart` | Image + name + quantity row |

### Implementation order
1. **Mock data** — add a `MealDetailMock` constant with all fields: name, date, type, kcal, duration, macros, tags, description, ingredients (with image URLs), steps
2. **`AkeliGlazeAppBar`** — build and verify blur + back navigation
3. **Hero section** — `CustomScrollView` + `SliverPersistentHeader` for AppBar + hero image with gradient
4. **MealHeaderCard** — overlap card with badges row, meal name, date
5. **ConsumedToggle** — `ConsumerWidget` with a local `StateProvider<bool>` for toggle state
6. **MetadataChips** — two `AkeliMetadataChip` in a `Row`
7. **MacroGrid** — three `AkeliMacroBox` in a `Row` with `Expanded`
8. **DietaryTags** — `Wrap` of rounded-full teal chips
9. **Description** — plain section with header + Inter body text
10. **Ingredients** — `Column` of `AkeliIngredientCard` (section title rows as `Text` sub-headers)
11. **Steps** — `Column` of `AkeliStepItem` (section title rows as `Text` sub-headers)
12. **BottomCTAs** — ghost `OutlinedButton` + gradient `ElevatedButton`
13. **Visual parity check** against `stitch/meal_detail/screen.png`

### Key constraints
- `personal` meal mode (no recipe images, no ingredients/steps sections) must still be handled — hide those sections when `personal == true` using mock bool
- Step section title rows (e.g. "Préparation") still needed — not shown in Stitch mockup but exist in FF source
- Ingredient section title rows (bold sub-header without image) — same
- `AkeliGlazeAppBar` must be pinned and blur correctly on scroll
- No `MediaQuery` hardcoding — use `SafeArea` and theme spacing
