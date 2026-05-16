# Audit: Recipe Search/List Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/recipes/recipe_search_page.dart`
**FF source**: `flutterflow_application/akeli/lib/recipe_researching_list/recipe_researching_list_widget.dart`
**Stitch source**: `stitch/recipe_search/`

---

## Step 1: [BASE] Widget Tree

- **GestureDetector** (dismiss keyboard)
  - **Scaffold** (bg: secondaryBackground)
    - **AppBar** (bg: secondaryBackground, elevation: 0, centerTitle: true)
      - **title**: Text ("Recette", headlineLarge, Outfit, primary)
    - **SafeArea**
      - **SingleChildScrollView**
        - **Column**
          - **Search Bar Section** (padding: 10/10/10/0, gap: 5)
            - **Row** (gap: 10)
              - **Expanded** → **TextFormField** (w: 200, filled, bg: primaryBackground, radius: 50, suffixIcon: search_rounded 24px secondaryText)
                - hintText: "Rechercher votre recette" (labelMedium Poppins)
                - onChanged: EasyDebounce (2000ms) → calls API with current filters
              - **FlutterFlowIconButton** (filter_alt, 24px secondaryText, bg: primaryBackground, borderRadius: 8, buttonSize: 40)
                - onTap → showModalBottomSheet (h: 600, RecipeFiltersCopyWidget)
              - **FlutterFlowIconButton** (filter_list, conditional)
                - If ordering: bg: primary, icon: primaryBackground
                - If not ordering: bg: primaryBackground, icon: primary
                - borderRadius: 8, buttonSize: 40
                - onTap → toggles FFAppState().orderMenu
            - **Row** (justify: end)
              - If orderMenu: **OrederingSelectorWidget** (embedded)
          - **Active Filters Section** (conditional: if FFAppState().filtering)
            - **Divider** (thickness: 2, color: alternate)
            - **Padding** (10/0/10/0)
              - **Wrap** (spacing: 10, runSpacing: 10) — Filter Chips
                - Per filter: Container (bg: alternate, radius: 15, border: alternate, padding: 10/5)
                  - Row (gap: 5)
                    - Text (filter value, labelSmall Poppins)
                    - InkWell → Icon (close, 18px, secondaryText) → removes filter + re-fetches
          - **Divider** (thickness: 2, color: alternate)
          - **Tag Quick-Select Section**
            - If tags not empty: **InkWell** → **TagAndOrWidget** (AND/OR toggle)
            - **FutureBuilder** (TagsRow, language: fr, receipeCreated > 0)
              - **SingleChildScrollView** (horizontal)
                - **Row** (gap: 10)
                  - Per tag: Container (bg: alternate, radius: 15, border: alternate, padding: 10/5)
                    - Row (gap: 5)
                      - Text (tag name, labelSmall Poppins)
                      - Text (recipe count, labelSmall Poppins)
                    - onTap → adds tag to FFAppState().tags + re-fetches
          - **Meal Context Banner** (conditional: if FFAppState().mealID != null && != 0)
            - Container (bg: primaryBackground, radius: 8, padding: 10)
              - Row (justify: end)
                - Icon (close_rounded, 24px, secondaryText) → clears mealID
              - Row (gap: 10)
                - ClipRRect image (radius: 8, w: 75, h: 75, BoxFit.cover)
                - Column (crossAxisAlignment: start)
                  - Text (meal name, titleLarge Outfit)
                  - Text (mealType label: Petit-Déjeuner/Déjeuner/Dîner/Collation, titleMedium Poppins, secondaryText)
                  - Text (formatted date "MMMMEEEEd", labelMedium Poppins)
          - **Divider** (thickness: 2, color: alternate)
          - **Recipe List** (padding: 10)
            - **ListView.separated** (separator: 10px gap, shrinkWrap)
              - Per recipe: **RecipeCardJSONCopyWidget** (wrapped with model)
                - **Stack**
                  - **InkWell** (onTap → navigates to ReceipeDetailWidget with receipeID)
                    - **Container** (maxWidth: 800, bg: secondaryBackground, radius: 12, border: 1px alternate, padding: 8)
                      - **Column** (gap: 8)
                        - **FutureBuilder** (ReceipeImageRow — main image)
                          - ClipRRect (radius: 4) → Image.network (w: 100%, h: 200, BoxFit.cover)
                        - **Row** (justify: spaceBetween, crossAxisAlignment: end, gap: 8)
                          - **Expanded** → **Column** (gap: 4)
                            - Text (recipe name, titleLarge Outfit)
                            - **Column**
                              - **RichText** (calories + "kcal" + " || " + hours + "h" + minutes + "min", labelSmall Poppins)
                              - **Row** (gap: 10)
                                - RatingBarIndicator (5 stars, star_rounded, secondary, 24px, unratedColor: #3DFF9F1C)
                                - RichText (empty text span)
                            - **Row** (gap: 5)
                              - Icon (favorite_sharp, 24px, primary) + Text (likeCount, bodyMedium)
                              - Icon (comment, 24px, primary) + Text (commentCount, bodyMedium)
                              - Icon (local_dining, 24px, primary) + Text (mealConsumed, bodyMedium)
                              - Expanded → Row (justify: end)
                                - Text (Food Region, bodyMedium, primary)
                  - **FutureBuilder** (ReceipeTagsRow, limit: 3)
                    - **Row** (absolute, top-left, padding: 5)
                      - Per tag (up to 3): Container (bg: #76FFFFFF, radius: 24, padding: 8/5)
                        - Text (tag name, labelSmall Poppins)

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens (Light Mode)
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | AppBar title, ordering icon (inactive), like/comment/dining icons, food region text, active ordering bg |
| secondary | `#FF9F1C` | Star rating color |
| tertiary | `#3F3F44` | Loading spinner |
| alternate | `#E5E5E5` | Filter chips bg/border, tag chips bg/border, recipe card border, dividers |
| primaryText | `#2F2F2F` | Body text, cursor |
| secondaryText | `#5A5A5A` | Search icon, filter icon, close icons, meal type text, ordering close icon |
| primaryBackground | `#F9F9E8` | Search field bg, ordering menu bg, meal context banner bg |
| secondaryBackground | `#FFFFFF` | Scaffold bg, AppBar bg, recipe card bg, filter bottom sheet bg |
| accent1 | `#4D96FF` | — |
| info | `#FFFFFF` | Button text, ordering active text |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| headlineLarge | Outfit | 32px | 600 | primary |
| titleLarge | Outfit | 22px | 500 | primaryText |
| titleMedium | Poppins | 18px | 400 | secondaryText |
| bodyMedium | Poppins | 14px | 400 | primaryText |
| labelMedium | Poppins | 14px | 400 | secondaryText |
| labelSmall | Poppins | 12px | 400 | filter/tag text, recipe meta |

### Spacing & Radius
| Token | Value |
|-------|-------|
| sm | 4px |
| md | 8px |
| lg | 16px |
| xl | 24px |

### Widget-Specific Attributes
- **AppBar**: bg: #FFFFFF, elevation: 0, centerTitle: true
- **Title**: "Recette", headlineLarge Outfit 32px 600w, primary (#3BB78F)
- **Search field**: filled, bg: #F9F9E8, radius: 50 (pill), suffixIcon: search_rounded 24px secondaryText
  - hintText: "Rechercher votre recette", labelMedium Poppins
  - onChanged: EasyDebounce 2000ms
- **Filter button**: filter_alt, 24px secondaryText, bg: #F9F9E8, borderRadius: 8, buttonSize: 40
- **Order button**: filter_list, 24px, conditional bg/icon colors, borderRadius: 8, buttonSize: 40
- **Filter chips**: bg: #E5E5E5, radius: 15px, border: 1px #E5E5E5, padding: 10/5
  - Text: labelSmall Poppins
  - Close icon: 18px, secondaryText
- **Tag chips**: bg: #E5E5E5, radius: 15px, border: 1px #E5E5E5, padding: 10/5
  - Text: labelSmall Poppins + count
- **AND/OR toggle**: Two connected pill halves (50x30 each), radius: 15 on outer corners only
  - Active: bg: #E5E5E5, text: secondaryText
  - Inactive: bg: #FFFFFF, text: secondaryText, border: #E5E5E5
- **Meal context banner**: bg: #F9F9E8, radius: 8px, padding: 10
  - Image: ClipRRect radius: 8px, w: 75, h: 75
  - Meal name: titleLarge Outfit
  - Meal type: titleMedium Poppins, secondaryText
  - Date: labelMedium Poppins
  - Close: close_rounded 24px, secondaryText
- **Divider**: thickness: 2px, color: #E5E5E5
- **Recipe card**: maxWidth: 800, bg: #FFFFFF, radius: 12px, border: 1px #E5E5E5, padding: 8
  - Image: ClipRRect radius: 4px, w: 100%, h: 200, BoxFit.cover
  - Recipe name: titleLarge Outfit
  - Meta text: labelSmall Poppins (calories || time)
  - RatingBarIndicator: 5 stars, star_rounded, 24px, secondary (#FF9F1C), unratedColor: #3DFF9F1C
  - Stats row: favorite_sharp/comment/local_dining icons (24px, primary) + count text (bodyMedium)
  - Food region: bodyMedium Poppins, primary, aligned right
  - Tag overlay: bg: #76FFFFFF (semi-transparent white), radius: 24px (pill), padding: 8/5, positioned top-left

### Ordering Selector
- Container (bg: #F9F9E8, radius: 12px, padding: 10)
- Close icon (top-right, 20px, secondaryText)
- Options: "Les plus aimées", "Les plus commentées", "Les plus consomées"
  - Active: bg: primary (#3BB78F), text: white Poppins 500w
  - Inactive: bg: #F9F9E8, text: primary Poppins 500w
  - Each: radius: 8px, padding: 10/5

### Bottom Sheets
- Filter bottom sheet: h: 600px, bg: secondaryBackground, isScrollControlled: true, no drag

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Recipe Search/List page into a high-fidelity, modern "Digital Editorial" discovery experience that feels like a premium recipe discovery platform.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for all primary containers and cards. Replace the current 4px/8px/12px radii.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text. Create strong hierarchy between recipe names and metadata.
> - **Visual Air**: Increase white space between recipe cards. Use generous padding (20px minimum on cards). Separate the search bar from the tag section with clear visual breathing room.
> - **Interactive Cues**: Apply subtle shadows (`shadow-sm`) on recipe cards. Use the brand Teal (#3BB78F) as the primary accent consistently.
> - **Search Experience**: Make the search bar the hero element — large, pill-shaped, with a frosted glass effect.
> - **Filter Chips**: Transform flat gray chips into colorful, pill-shaped indicators with subtle backgrounds.
>
> **Functional Structure to Preserve**:
> - **Header**: "Recette" title, centered
> - **Search bar**: Text input with search icon, auto-debounce search
> - **Filter button**: Opens bottom sheet with advanced filters
> - **Sort button**: Toggle ordering menu (most liked, most commented, most consumed)
> - **Active filters**: Removable filter chips showing current search criteria
> - **Tag quick-select**: Horizontal scroll of popular tags with recipe counts
> - **AND/OR toggle**: Switch between AND and OR logic for tag filtering
> - **Meal context banner**: Shows the meal slot this recipe is being added to (with close button)
> - **Recipe list**: Vertical list of recipe cards with image, name, calories, cooking time, rating, engagement stats, and tag overlay
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **AppBar** (bg: transparent/white, elevation: 0)
>     - **Text** ("Recette", 28px, Bold, Plus Jakarta Sans, primary Teal, center)
>   - **SingleChildScrollView**
>     - **Column** (spacing: 16px, px: 16)
>       - **SearchBar** (bg: #FFFFFF, rounded-2xl [16px], p: 4, shadow-sm)
>         - **Row** (items-center, gap: 8)
>           - **Icon** (search, 20px, muted, pl: 16)
>           - **TextField** (flex: 1, bg: transparent, 16px Inter, "Rechercher votre recette")
>           - **IconButton** (filter_alt, 20px, muted, circle, bg: cream)
>           - **IconButton** (sort, 20px, primary, circle, bg: cream)
>       - **OrderingDropdown** (conditional, bg: #FFFFFF, rounded-2xl [16px], p: 12, shadow-sm)
>         - **Column** (spacing: 4)
>           - **Option** ("Les plus aimées", 14px Inter, active: primary bg + white text, inactive: cream bg + primary text, rounded-xl [12px], px: 12, py: 8)
>           - **Option** ("Les plus commentées", 14px Inter)
>           - **Option** ("Les plus consommées", 14px Inter)
>       - **FilterChipsRow** (conditional, flex-wrap, gap: 8)
>         - **FilterChip** (bg: cream, border: 1px primary/20, rounded-full, px: 12, py: 6)
>           - **Text** (filter value, 13px Inter, primaryText)
>           - **Icon** (close, 14px, muted)
>       - **TagLogicToggle** (conditional, center)
>         - **SegmentedButton** (ET / OU, rounded-full, active: primary bg, inactive: cream bg, 13px Inter)
>       - **TagsScrollView** (horizontal, gap: 8)
>         - **TagChip** (bg: #FFFFFF, rounded-full, px: 14, py: 8, shadow-xs)
>           - **Text** (tag name, 13px Inter, primaryText)
>           - **Text** ("{count}", 12px Inter, muted)
>       - **MealContextBanner** (conditional, bg: primary/5, rounded-2xl [16px], p: 16)
>         - **Row** (items-center, gap: 12)
>           - **Image** (w: 56, h: 56, rounded-xl [12px], object-cover)
>           - **Column** (flex: 1)
>             - **Text** (meal name, 16px Bold, Plus Jakarta Sans)
>             - **Text** (mealType + date, 13px Inter, muted)
>           - **IconButton** (close, 18px, muted)
>       - **RecipeList** (spacing: 16)
>         - **RecipeCard** (bg: #FFFFFF, rounded-3xl [24px], overflow-hidden, shadow-sm)
>           - **ImageContainer** (h: 200px, relative, overflow-hidden)
>             - **Image** (w: 100%, h: 100%, object-cover)
>             - **TagsOverlay** (absolute, top: 12, left: 12, gap: 6)
>               - **TagPill** (bg: white/85, backdrop-blur, rounded-full, px: 10, py: 4)
>                 - **Text** (tag name, 11px Inter, primaryText)
>           - **CardContent** (p: 16)
>             - **Text** (Recipe name, 18px Bold, Plus Jakarta Sans, primaryText, 2 lines max)
>             - **SizedBox** (h: 8)
>             - **MetaRow** (flex, justify-between, items-center)
>               - **Text** ("450 kcal · 2h 30min", 13px Inter, muted)
>               - **StarRating** (5 stars, 16px, secondary)
>             - **SizedBox** (h: 12)
>             - **StatsRow** (flex, justify-between, items-center)
>               - **Row** (gap: 12)
>                 - **StatChip** (flex, items-center, gap: 4)
>                   - **Icon** (favorite, 16px, primary)
>                   - **Text** ("23", 13px Inter)
>                 - **StatChip** (flex, items-center, gap: 4)
>                   - **Icon** (comment, 16px, primary)
>                   - **Text** ("8", 13px Inter)
>                 - **StatChip** (flex, items-center, gap: 4)
>                   - **Icon** (local_dining, 16px, primary)
>                   - **Text** ("156", 13px Inter)
>               - **Text** ("West Africa", 12px Inter, primary, uppercase, letter-spacing)
>
> **Meal Type Color System**:
> | Type | Badge Color | Text Color | Icon |
> |------|------------|------------|------|
> | Petit-Déjeuner | #FFF3E0 | #FF9F1C | wb_sunny_rounded |
> | Déjeuner | #E8F5E9 | #3BB78F | lunch_dining_rounded |
> | Collation | #E3F2FD | #4D96FF | cookie_rounded |
> | Dîner | #E0F2F1 | #006A63 | dinner_dining_rounded |
