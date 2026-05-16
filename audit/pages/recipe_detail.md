# Audit: Recipe Detail Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/recipes/recipe_detail_page.dart`
**FF source**: `flutterflow_application/akeli/lib/receipe_detail/receipe_detail_widget.dart`
**Stitch source**: `stitch/recipe_detail/`

---

## Step 1: [BASE] Widget Tree

- **FutureBuilder** (ReceipeRow — loading: SpinKitDoubleBounce centered)
  - **GestureDetector** (dismiss keyboard)
    - **Scaffold** (bg: secondaryBackground)
      - **NestedScrollView** (floatHeaderSlivers: false)
        - **headerSliverBuilder**
          - **SliverAppBar** (bg: primary, elevation: 0, centerTitle: true)
            - **leading**: FlutterFlowIconButton (arrow_back_rounded, 30px, secondaryBackground color, transparent border, borderRadius: 30, buttonSize: 60) → pop
        - **body** (SafeArea, top: false)
          - **SingleChildScrollView**
            - **Column**
              - **Recipe Title** (padding: 20/30/20/0)
                - Text (recipe name, headlineMedium Outfit, 32px, primary, center)
              - **Image Carousel + Meta Section** (padding: 5/20/5/50)
                - **FutureBuilder** (ReceipeImageRow list)
                  - **CarouselSlider** (h: 200px, viewportFraction: 0.85, enlargeCenterPage: true, enlargeFactor: 0.25)
                    - Per image:
                      - **Hero** + **ClipRRect** (radius: 8px) → Image.network (w: 300, h: 200, BoxFit.cover)
                      - onTap → FlutterFlowExpandedImageView (full-screen, fade transition)
                - **Wrap** (spacing: 10, runSpacing: 10) — Macro Badges
                  - **Calories Badge**: Container (bg: secondary, border: secondary, radius: 8px, padding: 8/5)
                    - Text ("{quantity} kcal", bodyMedium Poppins 500w, secondaryBackground)
                  - **Protein Badge**: Container (bg: tertiary, border: secondary, radius: 8px, padding: 8/5)
                    - Text ("{quantity} g protéine", bodyMedium Poppins 500w, secondaryBackground)
                  - **Carbs Badge**: Container (bg: tertiary, border: secondary, radius: 8px, padding: 8/5)
                    - Text ("{quantity} g de glucide", bodyMedium Poppins 500w, secondaryBackground)
                  - **Fat Badge**: Container (bg: tertiary, border: secondary, radius: 8px, padding: 8/5)
                    - Text ("{quantity} g de lipide", bodyMedium Poppins 500w, secondaryBackground)
                - **Cooking Info Row** (center, gap: 10)
                  - **Cooking time**: Row (access_time_outlined 22px, secondaryText + "{hours}h{minutes}min", bodyMedium Poppins)
                  - **Difficulty**: Row ("Difficulté" label secondaryText + "{difficulty}" value, bodyMedium Poppins)
                - **Meal Type Icons Row** (center, gap: 10) — conditional per type
                  - breakfast: wb_sunny (24px, secondary) + "Petit-déjeuner" (bodyMedium, secondary)
                  - lunch: lunch_dining_rounded (24px, tertiary) + "Déjeuner" (bodyMedium, tertiary)
                  - snack: cookie_rounded (24px, accent1) + "Collation" (bodyMedium, accent1)
                  - dinner: lunch_dining_rounded (24px, primary) + "Dîner" (bodyMedium, primary)
                - **Tags Wrap** (spacing: 10, runSpacing: 10)
                  - **FutureBuilder** (ReceipeTagsRow list)
                    - Per tag: Container (bg: #73E5E5, radius: 12px, padding: 8/5)
                      - Text (tag name, labelSmall Poppins)
                - **"Ajouter au calendrier" Button** (conditional: if FFAppState().mealPlan != null)
                  - FFButtonWidget ("Ajouter au calendrier", primary bg, white text, radius: 8px, h: 40)
                  - onTap → showModalBottomSheet (h: 400, AddNewMealWidget)
                - **Rating Section**
                  - **RatingBar.builder** (5 stars, star_rounded, secondary color, itemSize: 32, unratedColor: alternate, glowColor: secondary)
                  - **FutureBuilder** (ReceipeCommentsRow count)
                    - Text ("{count} avis donnés", bodyMedium Poppins)
                  - **InkWell** → "Voir tous les avis" (labelSmall Poppins, underlined)
                    - onTap → showModalBottomSheet (h: 400, CommentThreadWidget)
                - **Description Section**
                  - Text ("Description", titleLarge Outfit, primary, padding: 16/0)
                  - Text (recipe description, labelMedium Poppins, padding: 16/0)
                - **Ingredients Section**
                  - Text ("Ingredients", titleLarge Outfit, secondary, center)
                  - **FutureBuilder** (IngredientsRow list, ordered by index)
                    - **ListView.separated** (separator: 10px gap)
                      - Per ingredient:
                        - **Material** (elevation: 3, radius: 12px, bg: secondaryBackground, padding: 10)
                        - If !title: **Row** (crossAxisAlignment: start)
                          - Text (formatted quantity, titleMedium Poppins, secondary)
                          - Expanded Text (ingredient name, bodyMedium Poppins)
                        - If title: **Row**
                          - Expanded Text (section title, titleMedium Poppins, secondary)
                - **Steps Section**
                  - Text ("Etapes", titleLarge Outfit, tertiary, center)
                  - **FutureBuilder** (StepRow list, ordered by index)
                    - **ListView.separated** (separator: 10px gap)
                      - Per step:
                        - **Material** (elevation: 3, radius: 12px, bg: secondaryBackground, padding: 10)
                        - If !title: **Row** (crossAxisAlignment: start)
                          - Text (step number, titleMedium Poppins, tertiary)
                          - Expanded Text (step text, bodyMedium Poppins)
                        - If title: **Row**
                          - Expanded Text (section title, titleMedium Poppins, tertiary)
                - **Comments Section**
                  - Text ("Commentaire de la recette", headlineSmall Outfit, center)
                  - **InkWell** → "Voir tous les commentaires" (labelSmall Poppins, underlined)
                    - onTap → showModalBottomSheet (h: 400, CommentThreadWidget)
                  - **FutureBuilder** (ReceipeCommentsRow list, limit: 5)
                    - **ListView.builder**
                      - Per comment: **CommentWidget** (wrapped with model)
                  - **AuthUserStreamWidget** → **FFButtonWidget** ("Commenter", primary bg, white text, radius: 8px, h: 40)
                    - onTap → showModalBottomSheet (h: 400, AddCommentWidget)
                - **Second "Ajouter au calendrier" Button** (conditional: if FFAppState().mealPlan != null)
                  - Same as first — duplicated CTA
                - **SimilarReceipeWidget** (embedded component, receipeID param)
                - **Creator Section**
                  - **FutureBuilder** (CreatorRow by creatorId)
                    - Text ("créée par", labelLarge Poppins, center)
                    - Container (radius: 12px, border: 1px tertiary, padding: 10)
                      - **Row** (gap: 20)
                        - Container (50x50, circle, Image.network — default or creator profilUrl)
                        - Text (creator name or "créateur privé", labelLarge Poppins, tertiary)

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens (Light Mode)
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | AppBar bg, recipe title, "Description" header, dinner icon/text, all primary buttons |
| secondary | `#FF9F1C` | Calories badge bg, breakfast icon/text, star rating color, "Ingredients" header, quantity text |
| tertiary | `#3F3F44` | Protein/Carbs/Fat badges bg, difficulty text, lunch icon/text, "Etapes" header, step numbers, creator border/text |
| alternate | `#E5E5E5` | Unrated stars, tag bg (#73E5E5 = 45% opacity) |
| primaryText | `#2F2F2F` | Body text |
| secondaryText | `#5A5A5A` | Cooking time icon, "Difficulté" label |
| primaryBackground | `#F9F9E8` | — |
| secondaryBackground | `#FFFFFF` | Scaffold bg, card bg, badge text, AppBar icon |
| accent1 | `#4D96FF` | Snack icon/text |
| info | `#FFFFFF` | Button text |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| headlineMedium | Outfit | 32px (overridden) | 400 | primary |
| headlineSmall | Outfit | 24px | 500 | primaryText |
| titleLarge | Outfit | 22px | 500 | varies (primary/secondary/tertiary) |
| titleMedium | Poppins | 18px | 400 | varies (secondary/tertiary) |
| bodyMedium | Poppins | 14px | 400/500 | varies |
| labelLarge | Poppins | 16px | 400 | secondaryText/tertiary |
| labelMedium | Poppins | 14px | 400 | primaryText |
| labelSmall | Poppins | 12px | 400 | tag text, link text |

### Spacing & Radius
| Token | Value |
|-------|-------|
| sm | 4px |
| md | 8px |
| lg | 16px |
| xl | 24px |

### Widget-Specific Attributes
- **SliverAppBar**: bg: #3BB78F (primary), elevation: 0, centerTitle: true
- **Back button**: arrow_back_rounded 30px, color: #FFFFFF, buttonSize: 60, borderRadius: 30, transparent border
- **Recipe title**: padding: 20/30/20/0, Outfit 32px, primary (#3BB78F), center
- **Image carousel**: h: 200px, viewportFraction: 0.85, enlargeCenterPage: true, enlargeFactor: 0.25
- **Carousel image**: ClipRRect radius: 8px, w: 300, h: 200, BoxFit.cover
- **Macro badges**: radius: 8px, padding: 8/5, border: 1px secondary
  - Calories: bg: #FF9F1C, text: white
  - Protein/Carbs/Fat: bg: #3F3F44, text: white
- **Cooking info row**: center, gap: 10, icon: access_time_outlined 22px secondaryText
- **Meal type icons**: 24px, gap: 10, colored by type
- **Tags**: bg: #73E5E5 (semi-transparent), radius: 12px, padding: 8/5
- **"Ajouter au calendrier" button**: h: 40px, bg: #3BB78F, white text Poppins, radius: 8px, padding: 16/0
- **RatingBar**: 5 stars, star_rounded, 32px, secondary (#FF9F1C), unrated: alternate (#E5E5E5), glow: secondary
- **Rating count text**: bodyMedium Poppins
- **"Voir tous les avis" link**: labelSmall Poppins, underlined
- **Section headers**: titleLarge Outfit, colored (primary/secondary/tertiary), padding: 16/0
- **Description text**: labelMedium Poppins, padding: 16/0
- **Ingredient cards**: Material elevation: 3, radius: 12px, bg: #FFFFFF, padding: 10
  - Quantity: titleMedium Poppins, secondary (#FF9F1C)
  - Name: bodyMedium Poppins
  - Section title: titleMedium Poppins, secondary
- **Step cards**: Material elevation: 3, radius: 12px, bg: #FFFFFF, padding: 10
  - Number: titleMedium Poppins, tertiary (#3F3F44)
  - Text: bodyMedium Poppins
  - Section title: titleMedium Poppins, tertiary
- **Comments header**: headlineSmall Outfit, center
- **"Voir tous les commentaires" link**: labelSmall Poppins, underlined
- **Comment list**: limit 5, CommentWidget per item
- **"Commenter" button**: same primary style as "Ajouter"
- **Similar recipes**: SimilarReceipeWidget (embedded)
- **Creator card**: radius: 12px, border: 1px tertiary, padding: 10, gap: 20
  - Avatar: 50x50, circle
  - Name: labelLarge Poppins, tertiary

### Bottom Sheets
- All bottom sheets: h: 400px, transparent bg, isScrollControlled: true, no drag
- AddNewMealWidget, CommentThreadWidget, AddCommentWidget

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Recipe Detail page into a high-fidelity, modern "Digital Editorial" experience that feels like a premium recipe magazine while preserving all functional elements.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for all primary containers and cards. Replace the current 8px/12px radii.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text. Create strong hierarchy between section headers and content.
> - **Visual Air**: Increase white space between sections. Use generous padding (24px minimum on cards). Separate the image carousel from the meta badges with clear visual breathing room.
> - **Interactive Cues**: Apply subtle shadows (`shadow-sm`) on ingredient/step cards. Use the brand Teal (#3BB78F) as the primary accent consistently.
> - **Hero Image**: Make the image carousel the visual anchor — full-bleed with a gradient overlay for text legibility.
> - **Macro Badges**: Transform the flat colored badges into elegant pill-shaped indicators with subtle backgrounds and colored text.
>
> **Functional Structure to Preserve**:
> - **Header**: Back button on colored AppBar
> - **Recipe title**: Centered, prominent
> - **Image carousel**: Horizontal carousel with tap-to-expand, hero animation
> - **Macro badges**: Calories, protein, carbs, fat — inline pills
> - **Cooking info**: Time + difficulty — compact row
> - **Meal type tags**: Icon + label for breakfast/lunch/snack/dinner
> - **Dietary tags**: Wrap of tag pills
> - **"Ajouter au calendrier" CTA**: Opens bottom sheet for meal scheduling
> - **Rating**: 5-star rating bar + review count + "Voir tous les avis" link
> - **Description**: Section header + body text
> - **Ingredients**: Numbered/sectioned list with quantities
> - **Steps**: Numbered step-by-step instructions
> - **Comments**: Section header + "Voir tous" link + recent comments list + "Commenter" button
> - **Similar recipes**: Embedded recommendation widget
> - **Creator card**: Avatar + name, "créée par" label
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **SliverAppBar** (bg: transparent with gradient overlay on hero image)
>     - **BackButton** (circle, bg: white/90, icon: arrow_back, shadow-sm)
>   - **SingleChildScrollView**
>     - **Column**
>       - **HeroImageSection** (relative, h: 320px, overflow-hidden)
>         - **CarouselSlider** (full-width, h: 320px, snap scrolling)
>           - **Image** (w: 100%, h: 100%, object-cover)
>           - **GradientOverlay** (linear-gradient: transparent 50% → black/40)
>         - **TitleOverlay** (absolute, bottom: 24px, left: 24px, right: 24px)
>           - **Text** (Recipe name, 28px, Bold, Plus Jakarta Sans, white, drop-shadow)
>       - **MetaCard** (bg: #FFFFFF, rounded-3xl [24px], mx: 16, -mt: 24, relative z-10, p: 24, shadow-sm)
>         - **MacroPillsRow** (flex-wrap, gap: 8)
>           - **MacroPill** (bg: cream, px: 12, py: 6, rounded-full)
>             - **Text** ("450 kcal", 14px, Bold, Inter, primary)
>           - **MacroPill** (bg: cream, px: 12, py: 6, rounded-full)
>             - **Text** ("18g protéine", 14px, Inter, primaryText)
>           - **MacroPill** (bg: cream, px: 12, py: 6, rounded-full)
>             - **Text** ("52g glucide", 14px, Inter, primaryText)
>           - **MacroPill** (bg: cream, px: 12, py: 6, rounded-full)
>             - **Text** ("14g lipide", 14px, Inter, primaryText)
>         - **SizedBox** (h: 16)
>         - **InfoRow** (flex, justify-between, items-center)
>           - **InfoChip** (flex, items-center, gap: 6)
>             - **Icon** (access_time, 18px, muted)
>             - **Text** ("2h 30min", 14px, Inter, primaryText)
>           - **InfoChip** (flex, items-center, gap: 6)
>             - **Icon** (speed, 18px, muted)
>             - **Text** ("Moyen", 14px, Inter, primaryText)
>           - **MealTypeChips** (flex, gap: 8)
>             - **TypeChip** (icon + label, pill, colored by type)
>       - **TagsRow** (flex-wrap, gap: 8, mx: 16, mt: 16)
>         - **TagPill** (bg: cream, px: 12, py: 4, rounded-full, 12px Inter, muted)
>       - **ActionButtonsRow** (mx: 16, mt: 20, gap: 12)
>         - **Button** ("Ajouter au calendrier", flex: 1, bg: Teal, white text, rounded-2xl [16px], h: 48px, icon: calendar_add)
>         - **IconButton** (share, circle, bg: cream, 48px)
>       - **RatingCard** (bg: #FFFFFF, rounded-3xl [24px], mx: 16, mt: 20, p: 24, shadow-sm)
>         - **Row** (items-center, justify-between)
>           - **StarRating** (5 stars, 20px, secondary)
>           - **Text** ("4.5", 24px, Bold, Plus Jakarta Sans)
>           - **Text** ("(23 avis)", 14px, Inter, muted)
>         - **SizedBox** (h: 12)
>         - **TextButton** ("Voir tous les avis", 14px, Inter, primary)
>       - **DescriptionCard** (bg: #FFFFFF, rounded-3xl [24px], mx: 16, mt: 16, p: 24, shadow-sm)
>         - **Text** ("Description", 18px, Bold, Plus Jakarta Sans, primary)
>         - **SizedBox** (h: 12)
>         - **Text** (Description body, 15px, Inter, primaryText, lineHeight: 1.6)
>       - **IngredientsCard** (bg: #FFFFFF, rounded-3xl [24px], mx: 16, mt: 16, p: 24, shadow-sm)
>         - **HeaderRow** (flex, justify-between, items-center)
>           - **Text** ("Ingrédients", 18px, Bold, Plus Jakarta Sans, secondary)
>           - **Text** ("{count}", 14px, Inter, muted)
>         - **SizedBox** (h: 16)
>         - **ListView** (spacing: 12)
>           - **IngredientRow** (flex, items-start, gap: 12)
>             - **Text** ("200g", 14px, Bold, Inter, secondary, minWidth: 60)
>             - **Text** ("Farine de manioc", 14px, Inter, primaryText)
>           - **SectionHeader** ("Pour la sauce", 14px, Bold, Inter, secondary, uppercase, letter-spacing)
>       - **StepsCard** (bg: #FFFFFF, rounded-3xl [24px], mx: 16, mt: 16, p: 24, shadow-sm)
>         - **Text** ("Étapes", 18px, Bold, Plus Jakarta Sans, tertiary)
>         - **SizedBox** (h: 16)
>         - **ListView** (spacing: 20)
>           - **StepRow** (flex, gap: 16, items-start)
>             - **StepNumber** (w: 32, h: 32, circle, bg: tertiary @ 15%, text: tertiary, bold, center, 14px)
>             - **Text** (Step description, 15px, Inter, primaryText, lineHeight: 1.6)
>       - **CommentsCard** (bg: #FFFFFF, rounded-3xl [24px], mx: 16, mt: 16, p: 24, shadow-sm)
>         - **HeaderRow** (flex, justify-between, items-center)
>           - **Text** ("Commentaires", 18px, Bold, Plus Jakarta Sans)
>           - **TextButton** ("Voir tout", 14px, Inter, primary)
>         - **SizedBox** (h: 16)
>         - **ListView** (spacing: 16)
>           - **CommentItem** (flex, gap: 12)
>             - **Avatar** (32x32, circle)
>             - **Column** (flex: 1)
>               - **Row** (justify-between)
>                 - **Text** (userName, 14px, Bold, Inter)
>                 - **Text** (timeAgo, 12px, Inter, muted)
>               - **Text** (comment text, 14px, Inter, primaryText, lineHeight: 1.5)
>         - **SizedBox** (h: 16)
>         - **Button** ("Commenter", full-width, bg: Teal, white text, rounded-2xl [16px], h: 48px)
>       - **SimilarRecipesSection** (mx: 16, mt: 24)
>         - **Text** ("Recettes similaires", 18px, Bold, Plus Jakarta Sans)
>         - **SizedBox** (h: 12)
>         - **SingleChildScrollView** (horizontal, gap: 12)
>           - **RecipeCardMini** (w: 200px, bg: #FFFFFF, rounded-3xl [24px], overflow-hidden, shadow-sm)
>       - **CreatorCard** (bg: #FFFFFF, rounded-3xl [24px], mx: 16, mt: 16, mb: 32, p: 24, shadow-sm)
>         - **Text** ("Créée par", 12px, Inter, muted, uppercase, letter-spacing)
>         - **SizedBox** (h: 12)
>         - **Row** (items-center, gap: 16)
>           - **Avatar** (48x48, circle, border: 2px cream)
>           - **Column** (flex: 1)
>             - **Text** (Creator name, 16px, Bold, Inter)
>             - **Text** ("{count} recettes", 13px, Inter, muted)
>           - **Button** ("Voir profil", outlined, Teal, rounded-xl [12px])
>
> **Meal Type Color System**:
> | Type | Badge Color | Text Color | Icon |
> |------|------------|------------|------|
> | Petit-Déjeuner | #FFF3E0 | #FF9F1C | wb_sunny_rounded |
> | Déjeuner | #E8F5E9 | #3BB78F | lunch_dining_rounded |
> | Collation | #E3F2FD | #4D96FF | cookie_rounded |
> | Dîner | #E0F2F1 | #006A63 | dinner_dining_rounded |
