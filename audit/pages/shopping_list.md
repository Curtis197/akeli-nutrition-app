# Audit: Shopping List Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/shopping_list/shopping_list_page.dart`
**FF source**: `flutterflow_application/akeli/lib/shopping_list/shopping_list_widget.dart`
**Stitch source**: `stitch/shopping_list/`

---

## Step 1: [BASE] Widget Tree

- **FutureBuilder** (UsersRow — loading: SpinKitDoubleBounce centered)
  - **GestureDetector** (dismiss keyboard)
    - **Scaffold** (bg: secondaryBackground)
      - **AppBar** (bg: primary, elevation: 2, centerTitle: true, no leading)
        - **leading**: FlutterFlowIconButton (arrow_back_ios_rounded, 30px, secondaryBackground, borderRadius: 30, buttonSize: 60) → pop
        - **title**: Text ("Liste de Course", headlineMedium Outfit 22px, white)
      - **SafeArea**
        - **FutureBuilder** (MealPlanRow — active week query)
          - **SingleChildScrollView**
            - **Column**
              - **Radio Filter** (center)
                - **FlutterFlowRadioButton** (options: "Tous", "Déjà acheté", "Reste à acheter", horizontal, primary radio, labelMedium Poppins)
              - **Conditional**: if "Tous" selected
                - **Row** (center)
                  - Text ("Nombre d'ingredient total", headlineSmall Outfit, secondary)
                  - Text ("{count}", headlineSmall Outfit, secondary)
                - **ListView.separated** (separator: 5px gap, px: 5)
                  - Per ingredient:
                    - Container (bg: secondaryBackground, radius: 12, border: 1px alternate, padding: 0/5)
                    - **Row**
                      - Text (formatted quantity, labelMedium Poppins)
                      - Expanded Text (ingredient name, labelMedium Poppins)
                      - **Conditional**: if bought == true
                        - InkWell → Icon (check_box, 24px, primary) → toggle to false
                      - **Conditional**: if bought == false
                        - InkWell → Icon (check_box_outline_blank, 24px, primary) → toggle to true
              - **Conditional**: if "Déjà acheté" selected
                - **Row** (center)
                  - Text ("Nombre d'ingredient acheté", headlineSmall Outfit, secondary)
                  - Text ("{count}", headlineSmall Outfit, secondary)
                - **ListView.separated** (same structure, filtered: bought == true)
              - **Conditional**: if "Reste à acheter" selected
                - **Row** (center)
                  - Text ("Nombre d'ingredient restant", headlineSmall Outfit, secondary)
                  - Text ("{count}", headlineSmall Outfit, secondary)
                - **ListView.separated** (same structure, filtered: bought == false)

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens (Light Mode)
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | AppBar bg, checkbox icons, radio buttons |
| secondary | `#FF9F1C` | Ingredient count numbers |
| tertiary | `#3F3F44` | Loading spinner |
| alternate | `#E5E5E5` | Ingredient card borders |
| primaryText | `#2F2F2F` | Ingredient names, body text |
| secondaryText | `#5A5A5A` | Radio inactive, quantity text |
| primaryBackground | `#F9F9E8` | — |
| secondaryBackground | `#FFFFFF` | Scaffold bg, ingredient card bg, AppBar icon |
| info | `#FFFFFF` | AppBar title text |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| headlineMedium | Outfit | 22px | 400 | white (AppBar title) |
| headlineSmall | Outfit | 24px | 500 | secondary (count numbers) |
| labelMedium | Poppins | 14px | 400 | primaryText/secondaryText |
| labelLarge | Poppins | 16px | 400 | — |
| bodyLarge | Poppins | 16px | 400 | radio selected text |
| labelSmall | Poppins | 12px | 400 | — |

### Spacing & Radius
| Token | Value |
|-------|-------|
| sm | 4px |
| md | 8px |
| lg | 12px |
| xl | 24px |

### Widget-Specific Attributes
- **AppBar**: bg: #3BB78F (primary), elevation: 2, centerTitle: true
- **Back button**: arrow_back_ios_rounded, 30px, #FFFFFF, borderRadius: 30, buttonSize: 60
- **Title**: "Liste de Course", headlineMedium Outfit 22px, white
- **Radio filter**: horizontal, options: "Tous" / "Déjà acheté" / "Reste à acheter", primary radio, optionHeight: 32
  - Selected: bodyLarge Poppins
  - Inactive: labelMedium Poppins, secondaryText
- **Count display**: center row, "Nombre d'ingredient {type}", headlineSmall Outfit, secondary (#FF9F1C)
  - Count number: headlineSmall Outfit, secondary
  - Gap: 5px
- **Ingredient card**: bg: #FFFFFF, radius: 12px, border: 1px #E5E5E5, padding: 0/5
  - Quantity: labelMedium Poppins (formatted via formatIngredientQuantity)
  - Name: labelMedium Poppins, primaryText
  - Checkbox: check_box / check_box_outline_blank, 24px, primary (#3BB78F)
  - Gap between quantity and name: 5px
  - Side padding: 5px left/right
- **Separator**: 5px gap between items

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Shopping List page into a high-fidelity, modern "Digital Editorial" grocery list experience that feels like a premium shopping companion.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for all primary containers and cards. Replace the current 12px/8px radii.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for list items. Create clear visual distinction between checked and unchecked items.
> - **Visual Air**: Increase padding inside ingredient cards (16px horizontal, 12px vertical). Use generous spacing between items (8px). Separate the count display from the list with clear breathing room.
> - **Interactive Cues**: Apply subtle shadows on ingredient cards. Use the brand Teal (#3BB78F) for checkboxes. Add strikethrough effect on checked items.
> - **Filter Design**: Transform the radio buttons into modern segmented chips or filter tabs.
>
> **Functional Structure to Preserve**:
> - **Header**: "Liste de Course" title on colored AppBar, back button
> - **Filter**: Three options — "Tous", "Déjà acheté", "Reste à acheter"
> - **Count display**: Shows total/bought/remaining count based on filter
> - **Ingredient list**: Each item has quantity (formatted), name, and checkbox toggle
> - **Checkbox toggle**: Toggles bought status, refreshes list
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **AppBar** (bg: transparent/white, elevation: 0, border-bottom: 1px cream)
>     - **BackButton** (circle, bg: cream, icon: arrow_back)
>     - **Text** ("Liste de Courses", 22px, Bold, Plus Jakarta Sans, primaryText, center)
>   - **SingleChildScrollView** (px: 16)
>     - **Column** (spacing: 20)
>       - **FilterChips** (flex, gap: 8)
>         - **Chip** ("Tous", flex: 1, center, 14px Inter, active: Teal bg + white text, inactive: cream bg + primaryText, rounded-xl [12px], py: 10)
>         - **Chip** ("Achetés", flex: 1, center, same style)
>         - **Chip** ("Restants", flex: 1, center, same style)
>       - **CountBanner** (bg: #FFFFFF, rounded-3xl [24px], p: 20, shadow-sm, center)
>         - **Text** ("{count}", 36px, Bold, Plus Jakarta Sans, secondary)
>         - **Text** ("ingrédients {filterLabel}", 14px, Inter, muted)
>       - **IngredientList** (spacing: 8)
>         - **IngredientItem** (bg: #FFFFFF, rounded-2xl [16px], p: 16, shadow-xs)
>           - **Row** (items-center, gap: 12)
>             - **Checkbox** (24px, Teal when checked, outline when unchecked, circle style)
>             - **Column** (flex: 1)
>               - **Text** (ingredient name, 15px, Inter, primaryText, strikethrough if checked)
>               - **Text** (quantity, 13px, Inter, muted)
>
> **Meal Type Color System**:
> | Type | Badge Color | Text Color | Icon |
> |------|------------|------------|------|
> | Petit-Déjeuner | #FFF3E0 | #FF9F1C | wb_sunny_rounded |
> | Déjeuner | #E8F5E9 | #3BB78F | lunch_dining_rounded |
> | Collation | #E3F2FD | #4D96FF | cookie_rounded |
> | Dîner | #E0F2F1 | #006A63 | dinner_dining_rounded |
