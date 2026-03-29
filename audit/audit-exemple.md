# UI Audit Example: Meal Detail Page

This document serves as a reference for the 6-step high-fidelity transformation workflow.

---

## 🥗 Step 1: [BASE] Meal Detail Page Widget Tree
- **Scaffold**
  - **AppBar**
    - **leading**: BackButton
    - **title**: Text (Détail du repas)
  - **Body** (Scrollable)
    - **SingleChildScrollView**
      - **Column**
        - **Container** (Image Area)
          - **Center**
            - **child**: Text (Emoji 🍽️)
        - **Padding** (Main Content)
          - **Column**
            - **Text** (Meal Title)
            - **SizedBox** (Spacing)
            - **Row** (Category Badges)
              - **AkeliBadge** (Meal Type)
              - **SizedBox**
              - **AkeliBadge** (Calories)
            - **SizedBox**
            - **AkeliSectionHeader** (Macronutriments)
            - **SizedBox**
            - **Wrap** (Macro Grid)
              - **AkeliMacroBadge** (Glucides)
              - **AkeliMacroBadge** (Protéines)
              - **AkeliMacroBadge** (Graisses)
              - **AkeliMacroBadge** (Calories)
            - **SizedBox**
            - **AkeliSectionHeader** (Ingrédients + Action Button)
            - **SizedBox**
            - **AkeliShoppingRow** (List of Ingredients...)
            - **SizedBox**
            - **AkeliSectionHeader** (Instructions)
            - **SizedBox**
            - **Text** (Step-by-step description)
            - **SizedBox** (Bottom safe-area spacing)

---

## 🎨 Step 2: [DESIGN] Meal Detail Page Attributes
- **Scaffold** (bg: #FFFFFF)
  - **AppBar** (bg: transparent, elevation: 0)
    - **BackButton** (icon: arrow_back, color: #1B1C16)
    - **Text** ("Détail du repas", 20px, Bold, Outfit, #1B1C16)
  - **Body** (SingleChildScrollView)
    - **Column** (crossAlign: start)
      - **Container** (h: 220px, bg: #4DB6AC @ 8% opacity)
        - **Center** -> **Text** ("🍽️", 64px)
      - **Padding** (all: 16px)
        - **Column** (crossAlign: start)
          - **Text** (Meal Title, 20px, Bold, Outfit, #1B1C16)
          - **SizedBox** (h: 8px)
          - **Row**
            - **AkeliBadge** (Type, bg: #4DB6AC, label: White)
            - **SizedBox** (w: 8px)
            - **AkeliBadge** (Calories, bg: #FF9F43, label: White)
          - **SizedBox** (h: 24px)
          - **AkeliSectionHeader** (Title: "Macronutriments", text: 16px, Bold)
          - **SizedBox** (h: 12px)
          - **Wrap** (spacing: 8px)
            - **AkeliMacroBadge** (Glucides, bg: #F8F9FA, border: 1px)
            - **AkeliMacroBadge** (Protéines, bg: #F8F9FA, border: 1px)
            - **AkeliMacroBadge** (Graisses, bg: #F8F9FA, border: 1px)
            - **AkeliMacroBadge** (Calories, bg: #F8F9FA, border: 1px)
          - **SizedBox** (h: 24px)
          - **AkeliSectionHeader** (Title: "Ingrédients", action: "Ajouter...")
          - **SizedBox** (h: 12px)
          - **AkeliShoppingRow** (h: 48px, padding: 12px, border-bottom: 1px #E5E5E5)
          - **SizedBox** (h: 24px)
          - **AkeliSectionHeader** (Title: "Instructions")
          - **SizedBox** (h: 12px)
          - **Text** (Poppins, 14px, #3D4947, line-height: 1.5)
          - **SizedBox** (h: 80px)

---

## 🤖 Step 3: [STITCH] Prompt Generation

### The High-Fidelity Prompt Example
Copy and paste this prompt when using the Stitch agent or generating new look-and-feel mockups:

> **Objective**: Transform the following Meal Detail Page into a high-fidelity, modern "Digital Editorial" experience while respecting the existing functional hierarchy.
> 
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (Radius 24px) for all primary containers and cards.
> - **Modern Typography**: Implement `Inter` or `Plus Jakarta Sans` with high contrast between headers and body text.
> - **Visual Air**: Increase white space and use centered alignments for headers to create a "clean" look.
> - **Interactive Cues**: Apply subtle shadows (`shadow-sm` or custom `blur-xl`) and `linear-gradients` for image placeholders.
> 
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: #FFFFFF)
>   - **AppBar** (bg: transparent, elevation: 0)
>     - **BackButton** (icon: arrow_back, color: #1B1C16)
>     - **Text** ("Détail du repas", 20px, Bold, Outfit, #1B1C16)
>   - **Body** (SingleChildScrollView)
>     - **Column** (crossAlign: start)
>       - **Container** (h: 220px, bg: #4DB6AC @ 8% opacity)
>         - **Center** -> **Text** ("🍽️", 64px)
>       - **Padding** (all: 16px)
>         - **Column** (crossAlign: start)
>           - **Text** (Meal Title, 20px, Bold, Outfit, #1B1C16)
>           - **SizedBox** (h: 8px)
>           - **Row**
>             - **AkeliBadge** (Type, bg: #4DB6AC, label: White)
>             - **SizedBox** (w: 8px)
>             - **AkeliBadge** (Calories, bg: #FF9F43, label: White)
>           - **SizedBox** (h: 24px)
>           - **AkeliSectionHeader** (Title: "Macronutriments", text: 16px, Bold)
>           - **SizedBox** (h: 12px)
>           - **Wrap** (spacing: 8px)
>             - **AkeliMacroBadge** (Glucides, Protéines, Graisses, Calories)
>           - **SizedBox** (h: 24px)
>           - **AkeliSectionHeader** (Title: "Ingrédients", action: "Ajouter...")
>           - **SizedBox** (h: 12px)
>           - **AkeliShoppingRow** (h: 48px, padding: 12px)
>           - **SizedBox** (h: 24px)
>           - **AkeliSectionHeader** (Title: "Instructions")
>           - **SizedBox** (h: 12px)
>           - **Text** (Poppins, 14px, #3D4947, line-height: 1.5)
>           - **SizedBox** (h: 80px)

---

## 🏗️ Step 4: [STITCH] High-Fidelity Widget Tree (Target)
*This is the precise structure extracted from the Stitch HTML source of truth.*

- **Scaffold** (`bg-surface` #FCFAEF)
  - **CustomAppBar** (`header` - `fixed`, `backdrop-blur-xl`, `bg-surface/70`)
    - **HeaderContainer** (h: 64px, px: 24, flex, justify-between, items-center)
      - **IconButton** (Icon: `arrow_back`, circle, hover:bg-surface-container-high/50)
      - **Text** ("Meal Details", 18px, Bold, `Plus Jakarta Sans`, `on-surface`)
      - **IconButton** (Icon: `favorite`, Color: `primary` #006A63)
  - **SingleChildScrollView**
    - **Column**
      - **HeroSection** (h: 220px, pt: 64, relative, overflow-hidden)
        - **BackgroundLayer** (bg: `#4DB6AC` @ 8% opacity)
        - **GradientLayer** (linear-gradient: transparent -> white/20)
        - **Center** -> **Text** (Emoji: `🍽️`, size: 6xl, drop-shadow-sm)
      - **ContentOverlapArea** (main, relative, `-mt-32`, px: 16, z-index: 20)
        - **MainCard** (bg: `#FFFFFF`, `rounded-3xl` [24px], p: 24, border: 1px `on-surface` @ 3%)
          - **Column** (spacing: 16)
            - **MealTitle** ("Bowl de Quinoa...", 20px, Bold, `Plus Jakarta Sans`, leading: tight)
            - **BadgesRow** (flex-wrap, gap: 8)
              - **Badge** (Text: "Déjeuner", bg: `#C3EAE5`, text: `#006A63`, bold)
              - **Badge** (Text: "450 kcal", bg: `#FF9F43` @ 10%, text: `#FF9F43`, bold)
              - **Badge** (Text: "25 min", bg: `#EAE8DE`, text: `on-surface-variant`, medium)
          - **SizedBox** (h: 32)
          - **MacronutrientsSection**
            - **Header** ("Macronutriments", 16px, Bold, `Plus Jakarta Sans`)
            - **SizedBox** (h: 16)
            - **MacrosGrid** (Row, gap: 12)
              - **Expanded** -> **MacroBox** (Label: "PROTÉINES", Value: "18g", bg: `#F6F4E9`, `rounded-2xl` [16px])
              - **Expanded** -> **MacroBox** (Label: "GLUCIDES", Value: "52g", bg: `#F6F4E9`, `rounded-2xl` [16px])
              - **Expanded** -> **MacroBox** (Label: "LIPIDES", Value: "14g", bg: `#F6F4E9`, `rounded-2xl` [16px])
          - **SizedBox** (h: 32)
          - **IngredientsSection**
            - **HeaderRow** (flex, justify-between)
              - **Title** ("Ingrédients", 16px, Bold, `Plus Jakarta Sans`)
              - **Action** ("Ajouter...", 14px, Bold, `primary`, Icon: `add`)
            - **SizedBox** (h: 16)
            - **IngredientsList** (Column, spacing: 12)
              - **IngredientItem** (bg: `#F6F4E9`, `rounded-3xl` [24px], p: 16, border: 1px opacity)
                - **Row** (gap: 16)
                  - **Image** (w: 48, h: 48, `rounded-2xl` [16px], `object-cover`)
                  - **Column** (Name: "Quinoa blanc", Detail: "Bio, non-cuit", style: 14px/12px)
                  - **Spacer**
                  - **Amount** ("60g", 14px, Bold, `primary`)
              - **IngredientItem** (...)
          - **SizedBox** (h: 32)
          - **InstructionsSection**
            - **Header** ("Instructions", 16px, Bold, `Plus Jakarta Sans`)
            - **SizedBox** (h: 16)
            - **StepsList** (Column, spacing: 16)
              - **StepItem** (Row, gap: 16, items-start)
                - **BadgeIcon** (w: 24, h: 24, circle, bg: `primary` @ 20%, text: `primary`, bold, "1")
                - **StepText** (Expanded, "Préchauffez votre four...", 14px, leading: 1.6)
              - **StepItem** (...)
  - **BottomNavBar** (fixed, bottom: 0, backdrop-blur-xl, bg: `#F6F4E9` @ 80%)

---

## 🔍 Step 5: [COMPARISON] Baseline vs. High-Fidelity

| Delta Type | Modification Required |
| :--- | :--- |
| **[LAYOUT]** | Implement `-32px` translation on the main content card. |
| **[LAYOUT]** | Change Ingredients from a raw list to `rounded-3xl` containers with images. |
| **[DESIGN]** | Update all `radius` values from 12px -> 24px (`AkeliRadius.xl`). |
| **[DESIGN]** | Implement `BackdropFilter` on AppBar and BottomNavBar for glass effect. |
| **[DESIGN]** | Switch typography to `Plus Jakarta Sans` for headers and `Inter` for body. |

---

## 📸 Step 7: [VISUAL] Screenshot Analysis & Implementation Prep
*Synthesizing Visual Clues + Flutter Expert Skill*

### Visual Nuance Extraction (from `screen.png`)
- **Tonal Depth**: The contrast between the pure white card (#FFFFFF) and the cream background (#FCFAEF) is subtle but creates the "Editorial" layers. No dividers are needed.
- **Micro-Coloring**: The "450 kcal" badge uses a warm orange with an extremely low opacity background (approx 10%). The protein/carb values use the brand Teal (#006A63).
- **Typography Feel**: The title has a slightly tighter letter-spacing than the body text.

### Implementation Blueprint (Flutter Expert Prep)
1. **Component Scaffolding**:
   - `AkeliGlazeAppBar`: A custom `SliverAppBar` or fixed `Header` using `ClipRect` + `BackdropFilter` (blur: 20).
   - `AkeliOverlapCard`: A `Transform.translate` or `Stack` based container with `AkeliRadius.xl`.
   - `AkeliMacroGrid`: A horizontal `Row` with 3 `Expanded` blocks to ensure perfect mathematical alignment.
2. **State & Data**:
   - Prepare a `MockMealData` model to decouple the UI from the FF data layer during prototype.
3. **Performance Optimization**:
   - Use `const` constructors for all static style elements (Radius, Spacing).
   - Implement `Image.network` with a `loadingBuilder` that uses a shimmering gradient placeholder.

---

## 🛠️ Step 8: [TRANSCRIPTION] High-Fidelity Flutter Code
- Implement `lib/features/meal_planner/meal_detail_page.dart` using the Step 7 blueprint.
- Verify visual parity against the screenshot and structural parity against the widget tree.
- Use `lib/core/design_system/` tokens for all colors and spacing.
- Final validation of visual parity against `stitch/audit_exemple/screen.png`.
