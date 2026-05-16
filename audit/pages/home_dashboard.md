# Audit: Home Dashboard
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/home/home_dashboard.dart`
**FF source**: `flutterflow_application/akeli/lib/home_page/home_page/home_page_widget.dart`
**Stitch source**: `stitch/home_dashboard/`

---

## Step 1: [BASE] Widget Tree

- **FutureBuilder** (UsersRow — loading: SpinKitDoubleBounce centered)
  - **GestureDetector** (dismiss keyboard)
    - **Scaffold** (bg: secondaryBackground)
      - **floatingActionButton**: FloatingActionButton (visible if paidPlan)
        - Icon: auto_awesome, bg: primary, icon: white, elevation: 8
        - Toggles AI chat overlay (aiChat boolean)
      - **NestedScrollView** (floatHeaderSlivers: true)
        - **headerSliverBuilder**
          - **SliverAppBar** (bg: secondaryBackground, elevation: 0, centerTitle: true, no leading)
            - **leading**: Profile avatar (40x40 circle, Image.network) → navigates to UserProfile
            - **actions**:
              - **FutureBuilder** (TotalNotificationsRow)
                - InkWell → Badge (badgeColor: secondary, animated scale)
                  - Icon: notifications_sharp (32px, primary)
                - → navigates to Notifications
              - Icon: settings_sharp (32px, secondary) → navigates to ProfileSetting
        - **body** (SafeArea, top: false)
          - **Stack**
            - **SingleChildScrollView**
              - **Column**
                - **Welcome Text** (padding: 20/30)
                  - Text ("Bienvenue sur Akeli {userName}", headlineLarge, Outfit 500w, tertiary, center)
                - **WeightGraphWidget** (clickable → navigates to DashWidget)
                  - Container (bg: secondaryBackground, radius: 8px, padding: 4)
                  - **Row** (spaceEvenly, gap: 15px)
                    - **Weight Progress Column**
                      - Text ("Suivi du poids", titleLarge, Outfit)
                      - CircularPercentIndicator (radius: 45, lineWidth: 12, progressColor: primary, bg: primaryBackground)
                        - Center: percentage text or "Félicitation"/"Attention" (headlineSmall, 24px)
                      - Text ("{actualWeight} kg/{targetWeight} kg", labelMedium, Poppins)
                    - **Calorie Progress Column**
                      - Text ("Suivi de calorie", titleLarge, Outfit)
                      - CircularPercentIndicator (radius: 45, lineWidth: 12, progressColor: secondary, bg: primaryBackground)
                        - Center: "{caloriePiePercentage} %" (headlineSmall)
                      - Text ("{calorieConsumed} kcal/{targetCalorie} kcal", labelMedium, Poppins)
                - **Weight Update Section** (conditional: if weight != null)
                  - Text ("Mettre à jour son poids", headlineSmall, Outfit)
                  - **FutureBuilder** (UpdatedWeightRow — last weight)
                    - **FlutterFlowCountController** (w: 250, h: 100, bg: secondaryBackground, radius: 8px)
                      - decrementIcon: remove_rounded (40px, secondaryText/alternate)
                      - incrementIcon: add_rounded (40px, primary/alternate)
                      - countBuilder: Text (48px, Outfit 600w)
                      - stepSize: 1, padding: 12/0
                    - **FFButtonWidget** ("Mettre à jour", primary bg, white text, radius: 8px, h: 40)
                - **No Weight Fallback** (conditional: if weight == null)
                  - Text ("Votre poids n'est pas encore enregistré...", titleLarge, Outfit, center)
                  - Text ("Veuillez entrer vos paramètres", labelLarge, Poppins, center)
                  - **FFButtonWidget** ("Commencer", primary bg, white text, radius: 8px) → navigates to EditInfo
                - **Divider** (thickness: 2, color: alternate)
                - **Coaching Demands Section** (conditional: if ConversationDemandRow not empty)
                  - Container (bg: secondaryBackground, padding: 12)
                  - Text ("Demandes", titleLarge, Outfit)
                  - **ListView** (vertical, shrinkWrap)
                    - Per demand row:
                      - **Row**
                        - ClipRRect avatar (50x50, circle, Image.network)
                        - Column (userName: bodyLarge, description: bodySmall)
                        - Icon: delete (24px, secondary) → reject demand
                        - **FFButtonWidget** ("Accepter", transparent bg, tertiary border, radius: 8px, h: 30) → accept & navigate to Chat
                - **No Meal Plan Section** (conditional: if mealPlan == null)
                  - Text ("Vous n'avez pas de repas planifié...", titleLarge, Outfit, center)
                  - Text ("Voulez vous generer vos repas...", labelLarge, Poppins, center)
                  - **FFButtonWidget** ("Générer mes repas", primary bg, white text, radius: 8px) → navigates to EditInfo
                - **Today's Meals Section** (conditional: if mealPlan exists)
                  - Text ("Mes Repas du jours", headlineSmall, Outfit)
                  - **FutureBuilder** (UserTrackRow — today)
                    - **FutureBuilder** (MealRow — today's meals for this mealPlan)
                      - **CarouselSlider** (h: 300, viewportFraction: 0.8 mobile, enlargeCenterPage: true, enlargeFactor: 0.25)
                        - Per meal:
                          - **Generated meal** (containerVarItem.generated == true):
                            - Container (w: 275, h: 275, bg: secondaryBackground, radius: 8px, shadow: blur 2px, offset 0,1)
                            - **Stack**
                              - **Bottom panel** (bg: secondaryBackground, radius: 12px)
                                - FutureBuilder (ReceipeImageRow — main image)
                                  - ClipRRect image (radius: 8px, h: 170, BoxFit.cover)
                                - Padding (10px)
                                  - Text (meal name, titleMedium, Poppins, color by mealType, maxLines: 1)
                                  - Text ("{adjustedCalories} kcal", labelMedium, Poppins, color by mealType)
                                  - **Row** (Icon + mealType label, color by mealType)
                                    - breakfast: wb_sunny_rounded + "Petit-Déjenuer" (secondary)
                                    - lunch: lunch_dining_rounded + "Déjeuner" (tertiary)
                                    - snack: cookie_rounded + "Collation" (accent1)
                                    - dinner: dinner_dining_rounded + "Dîner" (primary)
                              - **Top overlay** (consumed checkbox)
                                - Row (mainAxisAlignment: end)
                                  - consumed == true: Icon check_box (24px, primary) → toggle to false
                                  - consumed == false: Icon check_box_outline_blank (24px, primary) → toggle to true
                          - **Not generated meal** (containerVarItem.generated == false):
                            - Container (w: 275, h: 275, bg: primaryBackground, radius: 8px, elevation: 3)
                            - Icon: add_rounded (100px, primary, center)
                            - Text (mealType label, titleSmall, Poppins, secondaryText)
                            - → navigates to RecipeResearchingList (sets FFAppState().mealID)
                  - **Divider** (thickness: 2, color: alternate)
                  - **Shopping List Section** (conditional: if shoppingList exists)
                    - Container (bg: secondaryBackground)
                    - Text ("Liste de Course", headlineMedium, Outfit)
                    - Text ("Voir toute la liste de coures", labelMedium, Poppins, underlined) → navigates to ShoppingList
                    - **FlutterFlowRadioButton** (options: "Tous", "Déjà acheté", "Reste à acheter")
                    - **ListView** (shopping list items)
                      - Per item: Row (checkbox + ingredient name + quantity)

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens (Light Mode)
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | FAB, progress ring (weight), buttons, dinner labels, checkboxes |
| secondary | `#FF9F1C` | Notification badge, breakfast labels, settings icon, delete icon |
| tertiary | `#3F3F44` | Welcome text color, lunch labels, "Accepter" button border/text |
| alternate | `#E5E5E5` | Dividers, disabled count icons, borders |
| primaryText | `#2F2F2F` | Body text, progress center text |
| secondaryText | `#5A5A5A` | Labels, subtitles, not-generated meal type text |
| primaryBackground | `#F9F9E8` | Progress ring bg, not-generated meal card bg |
| secondaryBackground | `#FFFFFF` | Scaffold bg, card bg, AppBar bg |
| accent1 | `#4D96FF` | Snack labels |
| accent2 | `#FF6B6B` | Error messages |
| info | `#FFFFFF` | FAB icon, button text, titleMedium default |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| headlineLarge | Outfit | 32px | 500 | tertiary (#3F3F44) |
| headlineMedium | Outfit | 24px | 400 | primaryText |
| headlineSmall | Outfit | 24px | 500 | primaryText |
| titleLarge | Outfit | 22px | 500 | primaryText |
| titleMedium | Poppins | 18px | 400 | varies by mealType |
| titleSmall | Poppins | 16px | 500 | varies / info |
| labelLarge | Poppins | 16px | 400 | secondaryText |
| labelMedium | Poppins | 14px | 400 | varies by mealType |
| labelSmall | Poppins | 12px | 400 | badge text |
| bodyLarge | Poppins | 16px | 400 | primaryText |
| bodySmall | Poppins | 12px | 400 | primaryText |

### Spacing & Radius
| Token | Value |
|-------|-------|
| sm | 4px |
| md | 8px |
| lg | 16px |
| xl | 24px |
| full | 9999px (circle) |

### Widget-Specific Attributes
- **SliverAppBar**: bg: #FFFFFF, elevation: 0, centerTitle: true, floating: true, snap: false
- **Profile avatar**: 40x40, BoxShape.circle, Clip.antiAlias
- **Notification icon**: 32px, primary (#3BB78F), badge: secondary (#FF9F1C), elevation: 4, animated scale
- **Settings icon**: 32px, secondary (#FF9F1C)
- **Welcome text**: padding: 20/30, center, Outfit 32px 500w, tertiary
- **WeightGraph card**: bg: #FFFFFF, radius: 8px, outer padding: 16/12, inner padding: 4
- **CircularPercentIndicator**: radius: 45px, lineWidth: 12px, barRadius: implicit circle, animation: true
  - Weight: progressColor: #3BB78F, bg: #F9F9E8
  - Calorie: progressColor: #FF9F1C, bg: #F9F9E8
- **Count controller**: w: 250px, h: 100px, bg: #FFFFFF, radius: 8px, icons: 40px
- **Count value text**: Outfit 48px 600w
- **"Mettre à jour" button**: h: 40px, bg: #3BB78F, text: white Poppins, radius: 8px, padding: 16/0, elevation: 0
- **"Commencer" button**: same style as above
- **Divider**: thickness: 2px, color: #E5E5E5
- **Coaching demand card**: bg: #FFFFFF, padding: 12px, radius: 0 (flat)
- **Demand avatar**: 50x50, ClipRRect radius: 50px (circle)
- **"Accepter" button**: h: 30px, transparent bg, tertiary (#3F3F44) border 1px, text: tertiary 14px, radius: 8px
- **Delete icon**: 24px, secondary (#FF9F1C)
- **No meal plan text**: titleLarge Outfit center + labelLarge Poppins center
- **"Générer mes repas" button**: same primary style
- **CarouselSlider**: h: 300px, viewportFraction: 0.8 (mobile), enlargeCenterPage: true, enlargeFactor: 0.25
- **Meal card** (generated): w: 275px, h: 275px, bg: #FFFFFF, radius: 8px, shadow: blur 2px, color: #520E151B, offset (0,1)
- **Meal card image**: ClipRRect radius: 8px, h: 170px, BoxFit.cover
- **Meal card bottom panel**: bg: #FFFFFF, radius: 12px, padding: 10px
- **Not-generated meal card**: w: 275px, h: 275px, bg: #F9F9E8, radius: 8px, elevation: 3
- **Add icon** (not-generated): add_rounded, 100px, primary, center
- **Consumed checkbox**: 24px, primary, top-right overlay
- **Shopping list section**: bg: #FFFFFF, headlineMedium Outfit title
- **RadioButton**: options "Tous" / "Déjà acheté" / "Reste à acheter"
- **FAB**: bg: #3BB78F, icon: auto_awesome (24px, white), elevation: 8

### Animations
- All carousel items: FadeIn + MoveUp (50px → 0px), duration: 600ms, easeInOut

### Meal Type Color Coding
| Type | Icon | Color | Label |
|------|------|-------|-------|
| breakfast | wb_sunny_rounded | #FF9F1C (secondary) | Petit-Déjenuer |
| lunch | lunch_dining_rounded | #3F3F44 (tertiary) | Déjeuner |
| snack | cookie_rounded | #4D96FF (accent1) | Collation |
| dinner | dinner_dining_rounded | #3BB78F (primary) | Dîner |

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
> - **Scaffold** (bg: cream #F9F9E8)
>   - **AppBar** (fixed, bg: transparent or frosted glass)
>     - **Avatar** (48x48, circle, border: 2px primary)
>     - **Spacer**
>     - **IconButton** (notifications, with badge dot, 24px)
>     - **IconButton** (settings, 24px)
>   - **SingleChildScrollView** (vertical)
>     - **Column** (spacing: 24px, px: 20)
>       - **WelcomeHeadline** (center)
>         - **Text** ("Bienvenue sur Akeli {Name}", 28px, Bold, Plus Jakarta Sans, primaryText)
>         - **Text** ("Votre journée, votre nutrition", 14px, Inter, muted)
>       - **DualProgressCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm)
>         - **Row** (gap: 24px)
>           - **Expanded** → **WeightRing** (centered column)
>             - **CircularProgressIndicator** (radius: 52px, lineWidth: 10px, gradient: Teal)
>               - Center: "{percentage}%" (20px, Bold, Plus Jakarta Sans)
>             - **Text** ("Suivi du poids", 12px, Inter, muted, uppercase, letter-spacing)
>             - **Text** ("{actual} / {target} kg", 14px, Inter, primaryText)
>           - **Expanded** → **CalorieRing** (centered column)
>             - **CircularProgressIndicator** (radius: 52px, lineWidth: 10px, gradient: Orange)
>               - Center: "{percentage}%" (20px, Bold, Plus Jakarta Sans)
>             - **Text** ("Suivi calorie", 12px, Inter, muted, uppercase, letter-spacing)
>             - **Text** ("{consumed} / {target} kcal", 14px, Inter, primaryText)
>       - **WeightUpdateCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24)
>         - **HeaderRow** (flex, justify-between, items-center)
>           - **Text** ("Mettre à jour son poids", 18px, Bold, Plus Jakarta Sans)
>           - **Icon** (scale, 20px, primary)
>         - **SizedBox** (h: 20px)
>         - **CounterRow** (flex, items-center, gap: 16px)
>           - **IconButton** (remove, circle, bg: cream, 48px)
>           - **Text** ("{weight}", 40px, Bold, Plus Jakarta Sans, primaryText)
>           - **IconButton** (add, circle, bg: cream, 48px)
>         - **SizedBox** (h: 16px)
>         - **Button** ("Enregistrer", full-width, bg: Teal, white text, rounded-2xl [16px], h: 48px)
>       - **CoachingDemandsCard** (conditional, bg: #FFFFFF, rounded-3xl [24px], p: 24)
>         - **HeaderRow** (flex, justify-between)
>           - **Text** ("Demandes de coaching", 18px, Bold, Plus Jakarta Sans)
>           - **Badge** (count, pill, bg: secondary, text: white)
>         - **SizedBox** (h: 16px)
>         - **ListView** (spacing: 12px)
>           - **DemandRow** (flex, items-center, gap: 12px)
>             - **Avatar** (40x40, circle)
>             - **Column** (flex: 1)
>               - **Text** (userName, 14px, Bold, Inter)
>               - **Text** (description, 12px, Inter, muted)
>             - **IconButton** (close, 20px, muted)
>             - **Button** ("Accepter", small, outlined, Teal, rounded-xl [12px])
>       - **TodayMealsSection**
>         - **HeaderRow** (flex, justify-between, items-center)
>           - **Text** ("Mes Repas du Jour", 20px, Bold, Plus Jakarta Sans)
>           - **TextButton** ("Voir tout", 14px, Inter, primary)
>         - **SizedBox** (h: 12px)
>         - **SingleChildScrollView** (horizontal, gap: 16px)
>           - **MealCard** (w: 280px, bg: #FFFFFF, rounded-3xl [24px], overflow-hidden, shadow-sm)
>             - **ImageContainer** (h: 160px, relative, overflow-hidden)
>               - **Image** (w: 100%, h: 100%, object-cover)
>               - **ConsumedCheckbox** (absolute, top-right, circle bg: white/90, 28px, shadow)
>               - **MealTypeBadge** (absolute, bottom-left, pill, icon + label, colored by type)
>             - **CardContent** (p: 16)
>               - **Text** (Meal name, 16px, Bold, Plus Jakarta Sans, 1 line overflow)
>               - **SizedBox** (h: 4px)
>               - **Row** (justify-between)
>                 - **Text** ("450 kcal", 14px, Inter, primary)
>                 - **Icon** (meal type icon, 20px, colored by type)
>       - **ShoppingListCard** (conditional, bg: #FFFFFF, rounded-3xl [24px], p: 24)
>         - **HeaderRow** (flex, justify-between)
>           - **Text** ("Liste de Courses", 18px, Bold, Plus Jakarta Sans)
>           - **TextButton** ("Voir tout", 14px, Inter, primary)
>         - **SizedBox** (h: 12px)
>         - **ChipRow** (filter chips: "Tous", "Déjà acheté", "Reste à acheter")
>         - **ListView** (spacing: 8px)
>           - **ShoppingItem** (Row, checkbox + name + quantity, 14px Inter)
>   - **FloatingActionButton** (bottom-right, bg: Teal, icon: auto_awesome, rounded-full, shadow-lg)
>
> **Meal Type Color System**:
> | Type | Badge Color | Text Color | Icon |
> |------|------------|------------|------|
> | Petit-Déjeuner | #FFF3E0 | #FF9F1C | wb_sunny_rounded |
> | Déjeuner | #E8F5E9 | #3BB78F | lunch_dining_rounded |
> | Collation | #E3F2FD | #4D96FF | cookie_rounded |
> | Dîner | #E0F2F1 | #006A63 | dinner_dining_rounded |

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
