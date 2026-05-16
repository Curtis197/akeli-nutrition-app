# Audit: Diet Plan Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/diet_plan/diet_plan_page.dart`
**FF source**: `flutterflow_application/akeli/lib/diet_plan/diet_plan_widget.dart`
**Stitch source**: `stitch/diet_plan/`

---

## Step 1: [BASE] Widget Tree

- **FutureBuilder** (UsersRow — loading: SpinKitDoubleBounce centered)
  - **GestureDetector** (dismiss keyboard)
    - **Scaffold** (bg: secondaryBackground)
      - **NestedScrollView** (floatHeaderSlivers: true)
        - **headerSliverBuilder**
          - **SliverAppBar** (bg: secondaryBackground, elevation: 0, centerTitle: true, no leading)
            - **leading**: FlutterFlowIconButton (arrow_back_rounded, 30px, primary, borderRadius: 30, buttonSize: 60) → pop
        - **body** (SafeArea, top: false)
          - **Stack**
            - **SingleChildScrollView**
              - **Column**
                - **Summary Header** (padding: 24/0)
                  - **Text** ("Récapitulatif", displaySmall Outfit, normal weight)
                  - **Text** ("Voici un résumé de votre perso...", bodyMedium Poppins, secondaryText, lineHeight: 1.4)
                - **Goal Summary Card** (bg: primaryBackground, radius: 16, padding: 0/24)
                  - **Weight Loss Section** (padding: 12)
                    - **Row**
                      - Container (48x48, circle, bg: primary, Icon: track_changes, primaryBackground)
                      - Column
                        - Text ("Objectif de perte de poids", titleMedium Poppins 600w)
                        - Text ("Perdre {diff} kg en {targetTime} mois", bodyMedium Poppins, accent4)
                  - **Divider** (thickness: 3, color: secondaryBackground)
                  - **Diet Goal Section** (padding: 12)
                    - **Row**
                      - Container (48x48, circle, bg: secondary, Icon: restaurant_menu, primaryBackground)
                      - Column
                        - Text ("Objectif diétetique", titleMedium Poppins 600w)
                        - Text ("{targetCalorie} cal par jour", labelMedium Poppins 500w, primary)
                  - **Divider** (thickness: 3, color: secondaryBackground)
                  - **Restrictions Section** (padding: 12)
                    - **Row**
                      - Container (48x48, circle, bg: tertiary, Icon: warning_rounded, primaryBackground)
                      - Column
                        - **FutureBuilder** (UserPreferencesRow)
                          - Text ("Régime particulier :", titleMedium Poppins 600w)
                          - Text (particularDiet, labelMedium Poppins, secondaryText)
                        - **FutureBuilder** (UserAllergiesRow list)
                          - Text ("Allergies", titleMedium Poppins 600w)
                          - Text (allergy names joined, labelMedium Poppins, secondaryText)
                - **Regenerate Button** (conditional: if mealPlan exists)
                  - Container (bg: secondaryBackground, padding: 20/10)
                    - **Row** (gap: 10)
                      - **FFButtonWidget** ("Générer de nouveau", primary bg, white text, radius: 8, h: 40)
                        - onTap: navigate to EditInfo
                      - **FFButtonWidget** ("Voir la liste de course", primary bg, white text, radius: 8, h: 40)
                        - onTap: navigate to ShoppingList
                - **No Meal Plan CTA** (conditional: if no mealPlan)
                  - Container (bg: secondaryBackground, padding: 20/10)
                    - **Text** ("Pas de plan diététique...", titleLarge Outfit, center)
                    - **Text** ("Générez votre plan avec l'IA", labelLarge Poppins, center)
                    - **FFButtonWidget** ("Générer", primary bg, white text, radius: 8, h: 40)
                      - onTap: call generate-meal-plan API
                - **Daily Recap Section** (conditional: if mealPlan exists)
                  - Container (bg: secondaryBackground, padding: 20/10)
                    - **FutureBuilder** (MealPlanRow — active week)
                      - **Text** ("Récapitulatif quotidien", headlineSmall Outfit)
                      - **DailyRecapvViewWidget** (embedded, mealPlanId param)

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens (Light Mode)
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | Back button, daily calorie target text, buttons |
| secondary | `#FF9F1C` | Diet goal icon bg, weight loss count text |
| tertiary | `#3F3F44` | Restrictions icon bg, loading spinner |
| alternate | `#E5E5E5` | — |
| primaryText | `#2F2F2F` | Section titles, body text |
| secondaryText | `#5A5A5A` | Subtitles, restriction values |
| primaryBackground | `#F9F9E8` | Summary card bg |
| secondaryBackground | `#FFFFFF` | Scaffold bg, section bg, divider color |
| accent4 | `#006A63` | Weight loss count text |
| info | `#FFFFFF` | Button text, icon colors on colored bg |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| displaySmall | Outfit | 48px | 400 (normal) | primaryText |
| headlineSmall | Outfit | 24px | 500 | primaryText |
| titleLarge | Outfit | 22px | 500 | primaryText |
| titleMedium | Poppins | 18px | 600 | primaryText |
| labelMedium | Poppins | 14px | 400/500 | secondaryText/primary |
| labelLarge | Poppins | 16px | 400 | secondaryText |
| bodyMedium | Poppins | 14px | 400 | accent4/secondaryText |

### Spacing & Radius
| Token | Value |
|-------|-------|
| sm | 4px |
| md | 8px |
| lg | 16px |
| xl | 24px |

### Widget-Specific Attributes
- **SliverAppBar**: bg: #FFFFFF, elevation: 0, centerTitle: true
- **Back button**: arrow_back_rounded, 30px, primary (#3BB78F), borderRadius: 30, buttonSize: 60
- **Summary header**: padding: 24/0
  - Title: displaySmall Outfit 48px normal weight
  - Subtitle: bodyMedium Poppins, secondaryText, lineHeight: 1.4
- **Summary card**: bg: #F9F9E8, radius: 16px
  - Section padding: 12px
  - Icon containers: 48x48, circle
    - Weight loss: primary (#3BB78F)
    - Diet goal: secondary (#FF9F1C)
    - Restrictions: tertiary (#3F3F44)
  - Dividers: thickness: 3px, color: #FFFFFF
- **Weight loss text**: "Perdre {diff} kg en {targetTime} mois", bodyMedium Poppins, accent4 (#006A63)
- **Calorie text**: "{targetCalorie} cal par jour", labelMedium Poppins 500w, primary (#3BB78F)
- **Action buttons**: h: 40, bg: primary, white text, radius: 8px, padding: 16/0
- **Daily recap section**: bg: #FFFFFF, padding: 20/10
  - Title: headlineSmall Outfit
  - DailyRecapvViewWidget: embedded component

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Diet Plan page into a high-fidelity, modern "Digital Editorial" nutrition summary that feels like a premium diet tracking dashboard.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for all primary containers and cards. Replace the current 16px/8px radii.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text. Create strong visual hierarchy with large, bold numbers for key metrics.
> - **Visual Air**: Increase padding inside cards (24px minimum). Use generous spacing between sections (20px). Separate the summary card from action buttons with clear breathing room.
> - **Interactive Cues**: Apply subtle shadows on cards. Use the brand Teal (#3BB78F) as the primary accent consistently. Replace flat icon circles with more refined icon badges.
> - **Metrics Display**: Transform the text-based metrics into visual data cards with large numbers and contextual labels.
>
> **Functional Structure to Preserve**:
> - **Header**: Back button, "Récapitulatif" title, subtitle
> - **Summary card**: Weight loss goal (kg + months), daily calorie target, special diet, allergies
> - **Action buttons**: "Générer de nouveau" + "Voir la liste de course" (if plan exists) OR "Générer" CTA (if no plan)
> - **Daily recap**: Embedded DailyRecapvViewWidget showing daily meal breakdown
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **SliverAppBar** (bg: transparent, elevation: 0)
>     - **BackButton** (circle, bg: white/80, icon: arrow_back, 20px)
>   - **SingleChildScrollView** (px: 16)
>     - **Column** (spacing: 20)
>       - **HeaderSection** (pt: 8)
>         - **Text** ("Récapitulatif", 28px, Bold, Plus Jakarta Sans)
>         - **Text** ("Votre plan diététique personnalisé", 15px, Inter, muted)
>       - **SummaryCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm)
>         - **MetricRow** (gap: 12)
>           - **MetricCard** (flex: 1, bg: cream, rounded-2xl [16px], p: 16, center)
>             - **IconBadge** (32x32, circle, bg: primary/15, icon: track_changes, primary)
>             - **SizedBox** (h: 8)
>             - **Text** ("{diff} kg", 24px, Bold, Plus Jakarta Sans, primary)
>             - **Text** ("à perdre", 12px, Inter, muted)
>           - **MetricCard** (flex: 1, bg: cream, rounded-2xl [16px], p: 16, center)
>             - **IconBadge** (32x32, circle, bg: secondary/15, icon: restaurant_menu, secondary)
>             - **SizedBox** (h: 8)
>             - **Text** ("{targetTime} mois", 24px, Bold, Plus Jakarta Sans, secondary)
>             - **Text** ("objectif", 12px, Inter, muted)
>         - **SizedBox** (h: 16)
>         - **CalorieBanner** (bg: primary/5, rounded-2xl [16px], p: 16)
>           - **Row** (items-center, gap: 12)
>             - **IconBadge** (40x40, circle, bg: primary, icon: local_fire_department, white)
>             - **Column**
>               - **Text** ("{targetCalorie} kcal/jour", 20px, Bold, Plus Jakarta Sans, primary)
>               - **Text** ("Objectif calorique quotidien", 13px, Inter, muted)
>         - **SizedBox** (h: 16)
>         - **RestrictionsSection**
>           - **Text** ("Restrictions", 14px, Bold, Inter, uppercase, letter-spacing)
>           - **SizedBox** (h: 8)
>           - **Row** (gap: 8, flex-wrap)
>             - **RestrictionChip** (bg: cream, rounded-full, px: 12, py: 6)
>               - **Text** (diet name, 13px, Inter, primaryText)
>             - **AllergyChip** (bg: accent2/10, rounded-full, px: 12, py: 6)
>               - **Text** (allergy name, 13px, Inter, accent2)
>       - **ActionButtonsRow** (gap: 12)
>         - **Button** ("Régénérer", flex: 1, outlined Teal, rounded-2xl [16px], h: 48px)
>         - **Button** ("Liste de courses", flex: 1, bg: Teal, white text, rounded-2xl [16px], h: 48px)
>       - **DailyRecapCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm)
>         - **Text** ("Récapitulatif quotidien", 18px, Bold, Plus Jakarta Sans)
>         - **SizedBox** (h: 16)
>         - (Embedded DailyRecapvViewWidget content)
>
> **Meal Type Color System**:
> | Type | Badge Color | Text Color | Icon |
> |------|------------|------------|------|
> | Petit-Déjeuner | #FFF3E0 | #FF9F1C | wb_sunny_rounded |
> | Déjeuner | #E8F5E9 | #3BB78F | lunch_dining_rounded |
> | Collation | #E3F2FD | #4D96FF | cookie_rounded |
> | Dîner | #E0F2F1 | #006A63 | dinner_dining_rounded |
