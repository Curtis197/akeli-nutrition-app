# Audit: Edit Info Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/settings/edit_info_page.dart`
**FF source**: `flutterflow_application/akeli/lib/edit_info/edit_info_widget.dart`
**Stitch source**: `stitch/edit_info/`

---

## Step 1: [BASE] Widget Tree

- **Scaffold** (bg: secondaryBackground)
  - **AppBar** (bg: secondaryBackground, elevation: 0, centerTitle: false, no leading)
    - **leading**: FlutterFlowIconButton (arrow_back_rounded, 30px, primary, borderRadius: 30, buttonSize: 40) → pop
  - **SafeArea**
    - **Padding** (bottom: 50)
      - **SingleChildScrollView**
        - **Column**
          - **Text** ("Modifier vos informations", headlineLarge Outfit, center, padding-bottom: 16)
          - **Container** (full width, bg: primaryBackground, radius: 12, padding: 10, px: 25)
            - **Text** ("Vos paramètre", titleLarge Outfit, primary)
            - **Row** (Icon: face_sharp 24px + Text "Votre Âge", titleMedium Poppins 600w, secondaryText)
            - **TextFormField** (w: 250, bg: secondaryBackground, radius: 8, border: 1px transparent, hintText: "Quel âge avez vous ?", filled)
              - If missingField contains age: border: 1px error, hintColor: error, textColor: error
            - **Row** (Icon: monitor_weight_rounded 24px + Text "Votre poids", titleMedium Poppins 600w, secondaryText)
            - **TextFormField** (w: 250, bg: secondaryBackground, radius: 8, border: 1px transparent, hintText: "Quel est votre poids ?", filled)
              - If missing: error styling
            - **Row** (Icon: straighten 24px + Text "Votre taille", titleMedium Poppins 600w, secondaryText)
            - **TextFormField** (w: 250, bg: secondaryBackground, radius: 8, border: 1px transparent, hintText: "Quelle est votre taille ?", filled)
            - **Row** (Icon: fitness_center 24px + Text "Niveau d'activité", titleMedium Poppins 600w, secondaryText)
            - **TextFormField** (w: 250, bg: secondaryBackground, radius: 8, border: 1px transparent, hintText: "Activité physique ?", filled)
            - **Row** (Icon: target 24px + Text "Poids cible", titleMedium Poppins 600w, secondaryText)
            - **TextFormField** (w: 250, bg: secondaryBackground, radius: 8, border: 1px transparent, hintText: "Poids cible ?", filled)
            - **Row** (Icon: calendar_today 24px + Text "Objectif temps", titleMedium Poppins 600w, secondaryText)
            - **TextFormField** (w: 250, bg: secondaryBackground, radius: 8, border: 1px transparent, hintText: "Temps objectif ?", filled)
            - **Row** (Icon: local_fire_department 24px + Text "Calorie journalière", titleMedium Poppins 600w, secondaryText)
            - **TextFormField** (w: 250, bg: secondaryBackground, radius: 8, border: 1px transparent, hintText: "Calorie journalière ?", filled)
            - **TextFormField** (per meal: breakfast, lunch, dinner, snack calorie inputs)
            - **FFButtonWidget** ("Mettre à jour", primary bg, white text, radius: 8, h: 40)
              - onTap: Update UserHealthParameter + UserGoal → refresh

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | Back button, section title, buttons, focused borders |
| error | `#FF6B6B` | Missing field borders, hints, text |
| primaryBackground | `#F9F9E8` | Container bg |
| secondaryBackground | `#FFFFFF` | Scaffold bg, field bg |
| primaryText | `#2F2F2F` | Body text |
| secondaryText | `#5A5A5A` | Field labels |
| tertiary | `#3F3F44` | Loading spinner |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| headlineLarge | Outfit | 32px | 600 | primaryText (page title) |
| titleLarge | Outfit | 22px | 500 | primary (section header) |
| titleMedium | Poppins | 18px | 600 | secondaryText (field labels) |
| bodyMedium | Poppins | 14px | 400 | error (missing fields) |
| titleSmall | Poppins | 16px | 500 | white (button text) |

### Widget-Specific Attributes
- **AppBar**: bg: #FFFFFF, elevation: 0, centerTitle: false
- **Back button**: arrow_back_rounded, 30px, primary, buttonSize: 40
- **Page title**: "Modifier vos informations", headlineLarge Outfit, center
- **Container**: bg: #F9F9E8, radius: 12px, padding: 10, px: 25
- **Field labels**: Row with icon (24px, primaryText) + text (titleMedium Poppins 600w, secondaryText), gap: 5
- **Text fields**: w: 250, bg: #FFFFFF, radius: 8px, border: 1px transparent, filled
  - Missing field: border: 1px error, hintColor: error, textColor: error
- **Update button**: h: 40, bg: primary, white text, radius: 8px

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Edit Info page into a clean, modern profile editing experience.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for the form card.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text.
> - **Visual Air**: Increase padding inside the card (24px). Use generous spacing between fields (16px).
> - **Interactive Cues**: Use the brand Teal (#3BB78F) for focused fields and the update button. Highlight missing fields with red borders.
>
> **Functional Structure to Preserve**:
> - Health parameters: age, weight, height, activity level
> - Goals: target weight, target time, daily calories, per-meal calories
> - Missing field validation with error styling
> - Update button that saves changes
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **AppBar** (bg: transparent, elevation: 0)
>     - **BackButton** (circle, bg: white/80, icon: arrow_back)
>   - **SingleChildScrollView** (px: 16, py: 20)
>     - **Column** (spacing: 20)
>       - **Text** ("Modifier vos informations", 28px, Bold, Plus Jakarta Sans)
>       - **FormCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm)
>         - **Text** ("Paramètres de santé", 14px, Bold, Inter, primary, uppercase, letter-spacing)
>         - **SizedBox** (h: 16)
>         - **FieldRow** (icon: face, label: "Âge", TextField: bg: cream, rounded-2xl [16px], p: 14, 15px Inter)
>         - **FieldRow** (icon: monitor_weight, label: "Poids", TextField: same style)
>         - **FieldRow** (icon: straighten, label: "Taille", TextField: same style)
>         - **FieldRow** (icon: fitness_center, label: "Activité", TextField: same style)
>         - **Divider** (h: 16)
>         - **Text** ("Objectifs", 14px, Bold, Inter, primary, uppercase, letter-spacing)
>         - **SizedBox** (h: 16)
>         - **FieldRow** (icon: target, label: "Poids cible", TextField: same style)
>         - **FieldRow** (icon: calendar_today, label: "Durée", TextField: same style)
>         - **FieldRow** (icon: local_fire_department, label: "Calories/jour", TextField: same style)
>       - **Button** ("Enregistrer", full-width, bg: Teal, white text, rounded-2xl [16px], h: 52px)
