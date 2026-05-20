# Audit: Home Dashboard
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/home/home_page.dart`
**Stitch source**: `stitch/home_dashboard/`

---

## Step 1: [BASE] Widget Tree

- **Scaffold** (bg: AkeliColors.background)
  - **NestedScrollView** (floatHeaderSlivers: true)
    - **headerSliverBuilder**
      - **SliverAppBar** (pinned: false, floating: true, snap: false, bg: AkeliColors.background, elevation: 0, scrolledUnderElevation: 0, automaticallyImplyLeading: false, leadingWidth: 72)
        - **leading**: Padding(left: 16)
          - **Center**
            - **profileAsync.when**
              - data: Container (circle border: 1.5px primary @ 10% opacity) → CircleAvatar (radius: 20, bg: surfaceContainerHigh)
                - NetworkImage if avatarUrl set, else Icon(person_outline, outline, 20px)
              - loading: SizedBox(20×20) + CircularProgressIndicator(strokeWidth: 2)
              - error: CircleAvatar(radius: 20, Icon: person)
        - **actions**:
          - IconButton (notifications_none_rounded, secondary, 26px) → `/notifications`
          - Padding(right: 8) → IconButton (settings_outlined, secondary, 26px) → `/profile`
    - **body**: SingleChildScrollView → Column (crossAxisAlignment: start)

      - **[A] Welcome Header** — Padding(fromLTRB: 16, 8, 16, 0)
        - **profileAsync.when**
          - data: Column(crossAxis: start)
            - Text('Bonjour, {firstName}!', headlineMedium, onSurface, w800, letterSpacing: -0.5)
            - SizedBox(h: 4)
            - Text('Heureux de vous revoir.', bodyMedium, onSurfaceVariant)
          - loading: SizedBox(h: 40)
          - error: Text('Bonjour!')
      - SizedBox(h: 24)

      - **[B] Combined Metrics Card** — Padding(horizontal: 16)
        - Container (bg: white, borderRadius: 24, padding: v32/h24, shadow: black 2% blur 20 offset(0,10))
          - IntrinsicHeight → Row
            - **Expanded** → **Weight AkeliModernMetric** — healthAsync.maybeWhen
              - data: label 'Poids actuel', value: weight.toStringAsFixed(1), unit: 'kg'
              - progress: (targetWeight / weight).clamp(0.0, 1.0)
              - gradientColors: [primary, primaryContainer]
              - orElse: value '--', progress: 0
            - VerticalDivider (color: outline @ 10%, thickness: 1, indent/endIndent: 10)
            - **Expanded** → **Calorie AkeliModernMetric** — nutritionAsync.when
              - data: label 'Calories', value: '$consumed', unit: 'kcal'
              - progress: (consumed / 2000).clamp(0.0, 1.0)
              - gradientColors: [secondary, secondaryContainer]
              - onTap: → `/nutrition`
              - loading: CircularProgressIndicator
              - error: Icon(error_outline)
      - SizedBox(h: 24)

      - **[C] Weight Stepper** — Padding(horizontal: 16)
        - **AkeliWeightStepper** (weight: _currentWeight, onChanged: setState + HapticFeedback.lightImpact)
          - Container (bg: white, borderRadius: AkeliRadius.xl [24px], padding: AkeliSpacing.lg [16px], shadow: black 3% blur 20 offset(0,10))
            - Row (mainAxisAlignment: center)
              - **_StepperButton** (icon: remove, isActive: false)
                - Container (48×48, circle, bg: surfaceContainerHigh)
                  - Icon(remove, onSurfaceVariant, 20px)
              - SizedBox(w: AkeliSpacing.xl [24px])
              - Column (mainSize: min)
                - Text(weight, displayLarge/48px, primaryContainer, w900, letterSpacing: -1.5)
                - Text('KILOGRAMMES', labelSmall, onSurfaceVariant @ 50%, w800, letterSpacing: 2.0)
              - SizedBox(w: AkeliSpacing.xl [24px])
              - **_StepperButton** (icon: add, isActive: true)
                - Container (48×48, circle, bg: primaryContainer)
                  - Icon(add, white, 20px)
      - SizedBox(h: 32)

      - **[D] Today's Meals** — Padding(horizontal: 16)
        - AkeliSectionHeader (title: 'Vos repas du jour', color: AkeliColors.primary)
        - SizedBox(h: 12)
        - SizedBox(h: 310) → **mealPlanAsync.when**
          - data: entriesForDate(today)
            - empty → Center: Text("Aucun repas planifié pour aujourd'hui.", textSecondary)
            - ListView.builder (horizontal, padding: horizontal 16)
              - **AkeliMealCard** (title, mealType, calories, protein, carbs, fat, imageUrl)
              - onTap: → `/meal/${entry.id}`
          - loading: CircularProgressIndicator
          - error: Text('Erreur: $error', textSecondary)
      - SizedBox(h: 24)

      - **[E] Shopping List** — Padding(horizontal: 16)
        - AkeliSectionHeader (title: 'Liste de courses', trailingLabel: 'Voir tout', onTrailingTap: → `/shopping-list`)
        - SizedBox(h: 16)
        - **Filter Chips** — SingleChildScrollView(horizontal, padding: horizontal 16)
          - Row:
            - **_FilterChip** (label: 'Tout', isActive: _activeFilter == 'tout') — HapticFeedback.selectionClick
            - **_FilterChip** (label: 'À acheter', isActive: _activeFilter == 'acheter')
            - **_FilterChip** (label: 'Pris', isActive: _activeFilter == 'pris')
        - SizedBox(h: 16)
        - Padding(horizontal: 16) → **shoppingAsync.when**
          - data: _filterShoppingItems(items) → max 4 items (_activeFilter controls which)
            - empty → Container (h: 100, white, radius: 24, AkeliShadows.sm) → Text('Aucun article trouvé', onSurfaceVariant @ 50%)
            - Container (white, radius: 24, AkeliShadows.sm) → Column
              - **AkeliShoppingRow** per item (quantity, ingredient, checked: _checkedShoppingIds.contains, onToggle: HapticFeedback.mediumImpact + setState)
          - loading: CircularProgressIndicator
          - error: SizedBox.shrink()
      - SizedBox(h: 24)

      - **[F] Recommended Recipes** — Padding(horizontal: 16)
        - AkeliSectionHeader (title: 'Recettes recommandées', color: AkeliColors.secondary)
        - SizedBox(h: 12)
        - SizedBox(h: 220) → **recipesAsync.when** (feedProvider, FeedParams(limit: 10))
          - data:
            - empty → Center: Text('Aucune recette disponible.', textSecondary)
            - ListView.builder (horizontal, padding: horizontal 16)
              - SizedBox(w: 160) → Padding(right: 12) → **AkeliRecipeCard**
                - title, calories, rating, likes, comments, saves: 0, region, imageUrl
                - hasImage: true, isMinimalist: true
                - onTap: → `/recipe/${recipe.id}`
                - **Card internals** (isMinimalist):
                  - Container (bg: surface [white], radius: AkeliRadius.xl [24px], border: outlineVariant @ 30%, shadow: black 2% blur 12 offset(0,4))
                  - **_ImageVariant**:
                    - ClipRRect (top radius: 24px)
                      - Container (h: 140, bg: surfaceContainerHigh)
                        - Image.network or emoji fallback ('🥘', 40px)
                      - Positioned(top: md, right: md): Container (32×32, circle, bg: primaryContainer) → Icon(auto_awesome, white, 16px)
                    - Padding(all: md [8px]) → Column (crossAxis: start)
                      - Text(title, titleSmall, onSurface, w700, 15px, maxLines: 2, ellipsis)
                      - SizedBox(h: 4)
                      - Text('$calories kcal', labelSmall, onSurfaceVariant @ 60%, w600)
          - loading: CircularProgressIndicator
          - error: Text('Erreur: $error', textSecondary)
      - SizedBox(h: 80)

### Private Widget: _FilterChip
- GestureDetector(onTap)
  - Container (margin: right 8, padding: h20/v10, borderRadius: 40 [pill])
    - **active**: bg: primary, border: primary, shadow: primary @ 20% blur 10 offset(0,4)
    - **inactive**: bg: white, border: outline @ 20%
    - Text(label, labelLarge, active: white w700 / inactive: onSurfaceVariant)

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens
| Token | Value | Usage |
|-------|-------|-------|
| AkeliColors.primary | `#3BB78F` | Weight ring gradient start, filter chip active bg, section header [D], stepper add button bg |
| AkeliColors.primaryContainer | `#C3EAE5` | Weight ring gradient end, stepper weight value text, sparkle button bg on recipe cards |
| AkeliColors.secondary | `#FF9F1C` | Calorie ring gradient start, notification/settings icons, section header [F] |
| AkeliColors.secondaryContainer | (light orange) | Calorie ring gradient end |
| AkeliColors.background | (cream) | Scaffold bg, SliverAppBar bg |
| AkeliColors.surface | `#FFFFFF` | Metrics card bg, stepper card bg, shopping list container bg, recipe card bg |
| AkeliColors.surfaceContainerHigh | (light grey) | Profile avatar bg, stepper decrement button bg, recipe image placeholder bg |
| AkeliColors.onSurface | (near black) | Welcome headline text, recipe card title |
| AkeliColors.onSurfaceVariant | (medium grey) | Welcome subtitle, filter chip inactive text, 'KILOGRAMMES' label, calorie label on recipe card |
| AkeliColors.outline | (grey) | Avatar border base, filter chip inactive border |
| AkeliColors.outlineVariant | (light grey) | Recipe card border |
| AkeliColors.textSecondary | (muted) | Empty-state messages, error messages |

### Typography
| Style | Usage | Key attributes |
|-------|-------|----------------|
| headlineMedium | Welcome greeting ('Bonjour, $name!') | w800, letterSpacing: -0.5, onSurface |
| bodyMedium | Welcome subtitle ('Heureux de vous revoir.') | onSurfaceVariant |
| displayLarge/48px | Stepper weight value | w900, primaryContainer, letterSpacing: -1.5 |
| labelSmall | 'KILOGRAMMES' label; kcal sub-label on recipe card | w800, letterSpacing: 2.0, onSurfaceVariant @ 50% |
| titleSmall/15px | Recipe card title | w700, onSurface, maxLines: 2 |
| labelLarge | Filter chip labels | w700 active (white) / onSurfaceVariant inactive |

### Spacing & Radius (AkeliSpacing / AkeliRadius tokens)
| Token | Value | Usage |
|-------|-------|-------|
| AkeliSpacing.xs | 2px | Stats row icon-text gap |
| AkeliSpacing.sm | 4px | Recipe title/kcal gap |
| AkeliSpacing.md | 8px | Recipe card body padding |
| AkeliSpacing.lg | 16px | Stepper container padding, section horizontal padding |
| AkeliSpacing.xl | 24px | Stepper side gaps, metrics card horizontal padding |
| AkeliRadius.xl | 24px | Metrics card, stepper card, shopping container, recipe card, filter chip pill radius |

### Widget-Specific Attributes

**[A] Welcome Header**
- Padding: fromLTRB(16, 8, 16, 0), crossAxisAlignment: start (NOT centered)
- Greeting: headlineMedium, onSurface, w800, letterSpacing: -0.5
- Subtitle: bodyMedium, onSurfaceVariant

**[A] SliverAppBar**
- bg: AkeliColors.background, elevation: 0, scrolledUnderElevation: 0
- floating: true, snap: false, pinned: false, leadingWidth: 72
- Profile avatar: CircleAvatar(radius: 20), border Container: 1.5px primary @ 10%, Padding(left: 16)
- Icons: notifications_none_rounded + settings_outlined, both secondary, 26px (NOT 32px)

**[B] Combined Metrics Card**
- Container: bg: white, borderRadius: 24, padding: v32/h24, shadow: black @ 2% blur 20 offset(0,10)
- IntrinsicHeight ensures both columns equal height
- VerticalDivider: outline @ 10%, thickness: 1, indent/endIndent: 10
- Calorie side is tappable (→ /nutrition); weight side is not

**[C] AkeliWeightStepper**
- Container: bg: white, radius: AkeliRadius.xl (24px), padding: 16px, shadow: black @ 3% blur 20 offset(0,10)
- Decrement button: 48×48 circle, bg: surfaceContainerHigh, icon: onSurfaceVariant
- Increment button: 48×48 circle, bg: primaryContainer, icon: white
- Step size: 0.1 kg (NOT 1 kg from FlutterFlow source)
- Haptic: lightImpact on every change

**[D] Today's Meals**
- SizedBox height: 310px
- ListView.builder horizontal (NOT CarouselSlider)
- Padding: horizontal 16 on list
- Empty state: Text centered, textSecondary color
- AkeliMealCard: title, mealType, calories, protein, carbs, fat, imageUrl

**[E] Shopping List**
- Section header has trailing 'Voir tout' → /shopping-list
- Filter chips: 'Tout' / 'À acheter' / 'Pris' (NOT FlutterFlowRadioButton)
- Local state: _activeFilter (String) + _checkedShoppingIds (Set<String>)
- Items capped at 4 via .take(4)
- Container: white, radius: 24, AkeliShadows.sm
- Empty container: h: 100, centered text, onSurfaceVariant @ 50%

**[E] _FilterChip**
- Container: margin right 8, padding h20/v10, radius: 40 (pill)
- Active: bg: primary, border: primary, shadow: primary @ 20% blur 10 offset(0,4)
- Inactive: bg: white, border: outline @ 20%
- Text: labelLarge, active white w700 / inactive onSurfaceVariant

**[F] Recommended Recipes**
- SizedBox height: 220px
- feedProvider with FeedParams(limit: 10)
- ListView.builder horizontal, padding: horizontal 16
- Each item: SizedBox(w: 160) + Padding(right: 12) + AkeliRecipeCard(isMinimalist: true)
- AkeliRecipeCard (isMinimalist):
  - Container: bg: surface (white), radius: 24, border: outlineVariant @ 30%, shadow: black @ 2% blur 12 offset(0,4)
  - Image area: h: 140, ClipRRect top radius 24
  - Sparkle button overlay: 32×32 circle, primaryContainer bg, auto_awesome white 16px, top-right
  - Body padding: all 8px
  - Title: titleSmall, onSurface, w700, 15px, maxLines: 2
  - Calorie label: labelSmall, onSurfaceVariant @ 60%, w600
- Bottom padding: SizedBox(h: 80) (clears bottom nav bar)

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Home Dashboard into a high-fidelity, modern "Digital Editorial" experience while preserving the existing functional hierarchy and African cuisine identity.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for all primary containers and cards. Replace the current 8px/12px radii.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text. Maintain high contrast between section headers and body content.
> - **Visual Air**: Increase white space between sections. Use generous padding (24px minimum on cards). Create breathing room between the welcome headline and the progress rings.
> - **Interactive Cues**: Apply subtle shadows (`shadow-sm`) and micro-interactions on meal cards. Use the brand Teal (#3BB78F) as the primary accent consistently.
> - **Layered Design**: Use a subtle cream/off-white background (#F9F9E8) for the page, with pure white (#FFFFFF) cards creating editorial layers.
> - **Progress Rings**: Elevate the two circular percent indicators into a premium dual-ring dashboard widget with subtle gradient fills and clean center typography.
>
> **Functional Structure to Preserve**:
> - **Top bar**: Profile avatar (left), notification badge + settings icon (right)
> - **Welcome headline**: "Bienvenue sur Akeli {Name}" — centered, prominent
> - **Dual progress rings**: Weight tracking + Calorie tracking side by side, clickable → full dashboard
> - **Weight update**: Section with +/- counter and submit button (or "Commencer" CTA if no weight set)
> - **Coaching demands**: List of pending requests with accept/reject actions (conditional)
> - **No meal plan CTA**: Prompt to generate meals (conditional)
> - **Today's meals carousel**: Horizontal carousel of meal cards with image, name, calories, meal type icon, and consumed checkbox
> - **Shopping list preview**: Section with radio filter and item list (conditional)
> - **FAB**: AI assistant toggle (auto_awesome icon)
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: AkeliColors.background [cream])
>   - **SliverAppBar** (floating, bg: background, elevation: 0)
>     - **leading**: CircleAvatar (radius: 20, border: 1.5px Teal)
>     - **actions**: IconButton (notifications_none_rounded, secondary, 26px) + IconButton (settings_outlined, secondary, 26px)
>   - **SingleChildScrollView** (vertical, px: 16)
>     - **Column** (crossAxisAlignment: start)
>       - **[A] WelcomeHeader** (px: 16, pt: 8)
>         - **Text** ("Bonjour, {firstName}!", headlineMedium, Bold w800, onSurface, letterSpacing: -0.5)
>         - **Text** ("Heureux de vous revoir.", bodyMedium, onSurfaceVariant)
>       - **SizedBox** (h: 24)
>       - **[B] MetricsCard** (bg: #FFFFFF, rounded-3xl [24px], p: v32/h24, shadow-sm)
>         - **Row** with VerticalDivider
>           - **Expanded** → **WeightMetric** (AkeliModernMetric, gradient: Teal)
>             - label: "Poids actuel", value: "{weight}", unit: "kg"
>           - **Expanded** → **CalorieMetric** (AkeliModernMetric, gradient: Orange, tappable → /nutrition)
>             - label: "Calories", value: "{consumed}", unit: "kcal"
>       - **SizedBox** (h: 24)
>       - **[C] WeightStepper** (bg: #FFFFFF, rounded-3xl [24px], p: 16)
>         - **Row** (centered)
>           - **StepperButton** (remove, circle 48px, bg: surfaceContainerHigh)
>           - **Column**: Text ("{weight}", 48px, Bold, primaryContainer) + Text ("KILOGRAMMES", labelSmall, muted, letterSpacing: 2)
>           - **StepperButton** (add, circle 48px, bg: primaryContainer, icon: white)
>       - **SizedBox** (h: 32)
>       - **[D] TodayMealsSection**
>         - **SectionHeader** ("Vos repas du jour", color: Teal)
>         - **SizedBox** (h: 12)
>         - **SizedBox** (h: 310) → **ListView** (horizontal, padding: h16)
>           - **AkeliMealCard** (title, mealType, calories, protein, carbs, fat, imageUrl) → /meal/{id}
>       - **SizedBox** (h: 24)
>       - **[E] ShoppingListSection**
>         - **SectionHeader** ("Liste de courses", trailing: "Voir tout" → /shopping-list)
>         - **SizedBox** (h: 16)
>         - **FilterChipRow** (horizontal scroll)
>           - **FilterChip** ("Tout", active: primary)
>           - **FilterChip** ("À acheter")
>           - **FilterChip** ("Pris")
>         - **SizedBox** (h: 16)
>         - **ShoppingContainer** (bg: #FFFFFF, rounded-3xl [24px], shadow-sm)
>           - **AkeliShoppingRow** per item (checkbox + ingredient + quantity), max 4 items
>       - **SizedBox** (h: 24)
>       - **[F] RecommendedRecipesSection**
>         - **SectionHeader** ("Recettes recommandées", color: Orange/secondary)
>         - **SizedBox** (h: 12)
>         - **SizedBox** (h: 220) → **ListView** (horizontal, padding: h16)
>           - **AkeliRecipeCard** (w: 160, isMinimalist: true, gap: 12px)
>             - Image (h: 140) + SparkleButton overlay (32px circle, Teal, auto_awesome)
>             - Title (15px, Bold) + Calories (labelSmall, muted)
>       - **SizedBox** (h: 80)
>
> **Meal Type Color System** (handled inside AkeliMealCard):
> | Type | Label |
> |------|-------|
> | breakfast | Petit-Déjeuner |
> | lunch | Déjeuner |
> | snack | Collation |
> | dinner | Dîner |

---

## Step 4: [STITCH] High-Fidelity Widget Tree
*Waiting for Stitch HTML...*

---

## Step 5: [COMPARISON] Delta
| Delta Type | Modification Required |
| :--- | :--- |
| **[LAYOUT]** | *TBD* |
| **[DESIGN]** | *TBD* |

---

## Step 6: [APPROVAL]
- [ ] User approved

---

## Step 7: [VISUAL] Screenshot Analysis & Blueprint
*Waiting for Stitch generation and user approval...*

---

## Step 8: [TRANSCRIPTION] Notes
*Waiting for Stitch generation and user approval...*
