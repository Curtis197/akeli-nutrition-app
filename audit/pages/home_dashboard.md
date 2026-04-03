# Audit: Home Dashboard
**Status**: Step 1 — [BASE] Widget Tree
**Flutter file**: `lib/features/home/home_dashboard.dart`
**FF source**: `flutterflow_application/akeli/lib/home_page/home_page/home_page_widget.dart`
**Stitch source**: `stitch/home_dashboard/`

---

## Step 1: [BASE] Widget Tree
- **Scaffold**
  - **FloatingActionButton**
    - Icon: `auto_awesome` (AI Chat Toggle)
  - **NestedScrollView**
    - **SliverAppBar**
      - **leading**: Profile Picture (`Container` -> `Image.network`, circular)
      - **actions**:
        - **InkWell** -> `badges.Badge` -> `Icon(notifications_sharp)`
        - **InkWell** -> `Icon(settings_sharp)`
    - **Body** (SafeArea)
      - **Stack**
        - **SingleChildScrollView**
          - **Column**
            - **Text** ("Bienvenue sur Akeli [Name]")
            - **Column**
              - **WeightGraphWidget** (Custom FlutterFlow Component)
              //there is two graph widget one weight grah and one calorie graph
            - **Column**
              - **Text** ("Mettre à jour son poids")
              - **Container** -> **FlutterFlowCountController** (+/- counter)
              - **ButtonWidget** ("Mettre à jour")
            - **Divider**
            - **Visibility** (Demandes Coaching) // these demand onf conversation
              - **Column**
                - **Text** ("Demandes")
                - **ListView** -> **Row** (Photo, Name, Accept/Decline actions)
            - **Visibility** (No Meal Plan)
              - **Column**
                - **Text** ("Vous n'avez pas de repas...")
                - **ButtonWidget** ("Générer mes repas")
            - **Visibility** (Active Meal Plan)
              - **Column**
                - **Text** ("Mes Repas du jours")
                - **CarouselSlider**
                  - **Card** (Image, Title, Calories, Type Icon, Checkbox)


 //the widget tree is unfinished the page dont stop at "mes repas du jour". 
---

## Step 2: [DESIGN] Baseline Attributes
- **Scaffold** (bg: `secondaryBackground`)
  - **FloatingActionButton** (bg: `primary`, elevation: 8.0, icon color: `info`)
  - **SliverAppBar** (bg: `secondaryBackground`, elevation: 0.0)
    - **Profile Picture** (Container: 40x40, shape: circle)
    - **Notification Badge** (badgeColor: `secondary`, icon: `primary`, 32px)
    - **Settings Icon** (color: `secondary`, 32px)
  - **Body** (SafeArea)
    - **Column**
      - **Text** ("Bienvenue...", `headlineLarge`: `Outfit`, 500w, `tertiary`)
      - **Text** ("Mettre à jour son poids", `headlineSmall`: `Outfit`)
      - **FlutterFlowCountController** (bg: `secondaryBackground`, radius: 8px, w: 250, h: 100)
      - **ButtonWidget** ("Mettre à jour", bg: `primary`, text: `white`, radius: 8px)
      - **CarouselSlider**
        - **Card** (radius: 12px, border: 1px light gray, elevation: 1-3)

---

## Step 3: [STITCH] Prompt
> **Objective**: Transform the Home Dashboard into a high-fidelity, modern "Digital Editorial" experience while respecting the existing functional hierarchy.
> 
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (Radius 24px) for all primary containers and cards.
> - **Modern Typography**: Implement `Inter` or `Plus Jakarta Sans` with high contrast between headers and body text.
> - **Visual Air**: Increase white space and use centered alignments for headers to create a "clean" look.
> - **Interactive Cues**: Apply subtle shadows (`shadow-sm` or custom `blur-xl`).
> - Provide a high-impact, typographic-driven weight update section instead of a standard counter. Include circular progress rings for macro tracking rather than standard linear graphs.
> 
> **Base Widget Tree to Transform**:
> - **Scaffold** 
>   - **FloatingActionButton** (AI Chat Toggle)
>   - **SliverAppBar** (Profile Picture, Notification Badge, Settings Icon)
>   - **Body** (Scrollable Column)
>     - **Text** ("Bienvenue sur Akeli [Name]", Large Headline)
>     - **WeightGraphWidget** (Weight tracking visualization)
>     - **Column** (Weight Update: "Mettre à jour son poids", +/- counter, submit button)
>     - **Visibility** (Coaching Requests list)
>     - **CarouselSlider** (Meals of the day: Cards with Image, Title, Calories, Checkbox)

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
