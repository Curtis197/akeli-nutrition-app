# Audit: Meal Planner Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/meal_planner/meal_planner_page.dart`
**FF source**: `flutterflow_application/akeli/lib/meal_planner/meal_planner/meal_planner_widget.dart`
**Stitch source**: `stitch/meal_planner/`

---

## Step 1: [BASE] Widget Tree

- **Scaffold** (bg: secondaryBackground)
  - **FutureBuilder** (UsersRow — loading state: SpinKitDoubleBounce)
  - **GestureDetector** (dismiss keyboard)
    - **Scaffold**
      - **floatingActionButton**: FloatingActionButton (visible if paidPlan)
        - **Icon** (auto_awesome, bg: primary, icon color: info)
        - Toggles AI chat overlay
      - **NestedScrollView**
        - **headerSliverBuilder**
          - **SliverAppBar** (transparent, no leading, centerTitle, elevation: 0)
            - **Text** ("Vos repas de la semaine", headlineLarge, primary color, Outfit)
        - **body** (SafeArea)
          - **FutureBuilder** (MealPlanRow — active week query)
            - **Stack**
              - **Conditional**: if mealPlan exists && paidPlan → **SingleChildScrollView**
                - **Column**
                  - **Link**: "Voir mon plan diététique" (labelLarge, Poppins, underlined) → navigates to DietPlan
                  - **FutureBuilder** (ShoppingListRow)
                    - **Link**: "Voir ma liste de course" (labelLarge, Poppins, underlined) → navigates to ShoppingList
                  - **WeeklyProgressionWidget** (mealPlan ID)
                    - Container (maxWidth: 500, radius: 12px, padding: 12/16)
                    - Text ("Calorie Hebdomadaire", headlineSmall, Outfit)
                    - Date range text (labelLarge, Poppins)
                    - LinearPercentIndicator (progressColor: primary, barRadius: 16)
                    - Row: consumed vs target calories
                  - **Add Meal Section** (padding: 10px horizontal)
                    - **Text** ("Ajouter une collation", titleLarge, Outfit)
                    - **CheckboxListTile** ("Personnel", titleSmall, Poppins, secondaryText)
                    - **FFButtonWidget** ("Ajouter", primary bg, white text, Poppins, radius: 8px, h: 40)
                      - If personal checked → bottom sheet: AddSnackWidget
                      - Else → navigate to RecipeResearchingList
                  - **Day Sections** (Monday through Sunday — each day block)
                    - **FutureBuilder** (MealRow for that day)
                      - **Column**
                        - **Text** (Date header, e.g. "Monday, May 21", titleLarge, Outfit, secondary color)
                        - **Conditional**: DailyUserTrack consumed status
                          - Text ("Vous avez mangé tous les repas...") + checkbox icon
                        - **SingleChildScrollView** (horizontal)
                          - **Row** of meal cards per day
                            - **Container** (w: 275, h: 275, radius: 8px, shadow)
                              - **Stack**
                                - **Meal image** (ClipRRect, radius: 8px, h: 170, BoxFit.cover)
                                - **Bottom info panel** (secondaryBackground, radius: 12px)
                                  - **Text** (meal name, titleMedium, Poppins, color varies by mealType)
                                  - **Text** ("XXX kcal", labelMedium, Poppins, color varies by mealType)
                                  - **Row** (Icon + mealType label, color varies by mealType)
                                    - breakfast: wb_sunny_rounded + "Petit-Déjenuer" (secondary/orange)
                                    - lunch: lunch_dining_rounded + "Déjeuner" (tertiary/dark)
                                    - snack: cookie_rounded + "Collation" (accent1/blue)
                                    - dinner: dinner_dining_rounded + "Dîner" (primary/green)
                                - **Top overlay**: consumed checkbox row
              - **Conditional**: if no mealPlan → **EmptyStateWidget**
                - Column (centered)
                  - Icon (restaurant_menu, 64px, primary)
                  - Text ("Pas de plan pour cette semaine", titleLarge)
                  - Text ("Générez votre plan avec l'IA", bodyMedium)
                  - FFButtonWidget ("Générer", primary bg) → calls generate-meal-plan

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens (Light Mode)
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | Progress bars, buttons, dinner labels, FAB |
| secondary | `#FF9F1C` | Breakfast labels, date headers |
| tertiary | `#3F3F44` | Lunch labels |
| alternate | `#E5E5E5` | Borders, dividers, drag handle |
| primaryText | `#2F2F2F` | Body text |
| secondaryText | `#5A5A5A` | Labels, subtitles |
| primaryBackground | `#F9F9E8` | Progress bar bg, input fields |
| secondaryBackground | `#FFFFFF` | Card backgrounds, scaffold bg |
| accent1 | `#4D96FF` | Snack labels |
| accent2 | `#FF6B6B` | Error messages |
| info | `#FFFFFF` | Button text, titleMedium default |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| headlineLarge | Outfit | 32px | 600 | primaryText |
| headlineSmall | Outfit | 24px | 500 | primaryText |
| titleLarge | Outfit | 22px | 500 | primaryText |
| titleMedium | Poppins | 18px | 400 | info (overridden per context) |
| titleSmall | Poppins | 16px | 500 | info (overridden per context) |
| labelLarge | Poppins | 16px | 400 | secondaryText |
| labelMedium | Poppins | 14px | 400 | secondaryText (overridden) |
| bodyMedium | Poppins | 14px | 400 | primaryText |

### Spacing & Radius
| Token | Value |
|-------|-------|
| sm | 4px |
| md | 8px |
| lg | 16px |
| xl | 24px |

### Widget-Specific Attributes
- **SliverAppBar**: bg: transparent, elevation: 0, centerTitle: true, no back button
- **WeeklyProgression card**: radius: 12px, padding: 12/16, maxWidth: 500, bg: #FFFFFF
- **LinearPercentIndicator**: lineHeight: 16px, barRadius: 16px, progressColor: #3BB78F, bg: #F9F9E8
- **Add section container**: bg: #FFFFFF, padding: 10px horizontal
- **"Ajouter" button**: h: 40px, bg: #3BB78F, text: white, radius: 8px, padding: 16/0
- **Meal card**: w: 275px, h: 275px, radius: 8px, shadow: blur 2px, offset (0,1), color: #520E151B
- **Meal card image**: ClipRRect radius: 8px, h: 170px, BoxFit.cover
- **Meal card bottom panel**: bg: #FFFFFF, radius: 12px, padding: 10px
- **CheckboxListTile**: radius: 8px, padding: 12/0, activeColor: #3BB78F
- **Link texts**: Poppins 16px, underlined, secondaryBackground bg (clickable containers)
- **Empty state**: Icon 64px, centered column with button
- **FAB**: bg: #3BB78F, icon: auto_awesome (24px, white), elevation: 8
- **Drag handle** (bottom sheets): w: 100/50px, h: 6/5px, bg: #E5E5E5, radius: 50/8px

### Animations
- All cards: FadeIn + MoveUp (50px → 0px), duration: 600ms, easeInOut
- WeeklyProgression: FadeIn + MoveUp (90px → 0px), duration: 600ms

### Meal Type Color Coding
| Type | Icon | Color | Label |
|------|------|-------|-------|
| breakfast | wb_sunny_rounded | #FF9F1C (secondary) | Petit-Déjenuer |
| lunch | lunch_dining_rounded | #3F3F44 (tertiary) | Déjeuner |
| snack | cookie_rounded | #4D96FF (accent1) | Collation |
| dinner | dinner_dining_rounded | #3BB78F (primary) | Dîner |

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Meal Planner page into a high-fidelity, modern "Digital Editorial" experience while preserving the existing functional hierarchy and African cuisine identity.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for all primary containers and cards. Replace the current 8px/12px radii.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text. Maintain high contrast between section headers and body content.
> - **Visual Air**: Increase white space between sections. Use generous padding (24px minimum on cards). Create breathing room between day headers and their horizontal scroll lists.
> - **Interactive Cues**: Apply subtle shadows (`shadow-sm`) and micro-interactions on meal cards (hover lift effect). Use the brand Teal (#3BB78F) as the primary accent consistently.
> - **Layered Design**: Consider a subtle cream/off-white background (#F9F9E8) for the page, with pure white (#FFFFFF) cards creating editorial layers.
>
> **Functional Structure to Preserve**:
> - **Header**: "Vos repas de la semaine" — centered, prominent
> - **Quick links**: "Voir mon plan diététique" + "Voir ma liste de course" — subtle, text-link style
> - **Weekly calorie progress card**: Linear progress bar with consumed/target display and date range
> - **Add snack/meal section**: Checkbox toggle ("Personnel") + action button
> - **Day-by-day horizontal scroll**: Each day has a date header, consumption status, and horizontally scrollable meal cards
> - **Meal cards**: Image on top, name, calories, meal type icon + label below
> - **FAB**: AI assistant toggle (auto_awesome icon)
> - **Empty state**: When no meal plan exists — icon, text, "Generate" CTA
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **SliverAppBar** (fixed, transparent, centerTitle)
>     - **Text** ("Vos repas de la semaine", 28px, Bold, Plus Jakarta Sans, primary Teal)
>   - **SingleChildScrollView** (vertical)
>     - **Column** (spacing: 24px)
>       - **QuickLinksRow** (flex, justify-between, gap: 12px)
>         - **TextLink** ("Voir mon plan diététique", 14px, Inter, primary, underline)
>         - **TextLink** ("Voir ma liste de course", 14px, Inter, primary, underline)
>       - **WeeklyProgressCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm)
>         - **HeaderRow** (flex, justify-between)
>           - **Text** ("Calorie Hebdomadaire", 18px, Bold, Plus Jakarta Sans)
>           - **DateRange** (12px, Inter, muted)
>         - **LinearProgressIndicator** (h: 12px, radius: 8px, progress: Teal, bg: cream)
>         - **StatsRow** (flex, justify-between)
>           - **Text** ("1,240 kcal", 16px, Bold, Inter)
>           - **Text** ("de 2,100 kcal", 14px, Inter, muted)
>       - **AddMealSection** (bg: #FFFFFF, rounded-3xl [24px], p: 24)
>         - **HeaderRow** (flex, justify-between, items-center)
>           - **Text** ("Ajouter un repas", 18px, Bold, Plus Jakarta Sans)
>           - **Toggle** ("Personnel", switch-style)
>         - **SizedBox** (h: 16px)
>         - **Button** ("Ajouter", full-width, bg: Teal, white text, rounded-2xl [16px], h: 48px)
>       - **DaySection** (repeat for each day Mon-Sun)
>         - **DayHeader** (flex, justify-between, items-center)
>           - **Text** ("Lundi 21 Mai", 20px, Bold, Plus Jakarta Sans, secondary accent)
>           - **ConsumedBadge** (checkmark icon + "Complété", 12px, success green bg)
>         - **SizedBox** (h: 12px)
>         - **SingleChildScrollView** (horizontal)
>           - **Row** (gap: 16px)
>             - **MealCard** (w: 280px, bg: #FFFFFF, rounded-3xl [24px], overflow-hidden, shadow-sm)
>               - **ImageContainer** (h: 160px, relative, overflow-hidden)
>                 - **Image** (w: 100%, h: 100%, object-cover)
>                 - **MealTypeBadge** (absolute, top-right, pill shape, icon + label, colored by type)
>               - **CardContent** (p: 16)
>                 - **Text** (Meal name, 16px, Bold, Plus Jakarta Sans, 1 line overflow)
>                 - **SizedBox** (h: 4px)
>                 - **Row** (justify-between)
>                   - **Text** ("450 kcal", 14px, Inter, primary)
>                   - **Icon** (meal type icon, 20px, colored by type)
>   - **FloatingActionButton** (bottom-right, bg: Teal, icon: auto_awesome, rounded-full, shadow-lg)
>
> **Meal Type Color System**:
> | Type | Badge Color | Text Color | Icon |
> |------|------------|------------|------|
> | Petit-Déjeuner | #FFF3E0 | #FF9F1C | wb_sunny_rounded |
> | Déjeuner | #E8F5E9 | #3BB78F | lunch_dining_rounded |
> | Collation | #E3F2FD | #4D96FF | cookie_rounded |
> | Dîner | #E0F2F1 | #006A63 | dinner_dining_rounded |
