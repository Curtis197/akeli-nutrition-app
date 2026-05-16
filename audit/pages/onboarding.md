# Audit: Onboarding / Inscription Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/onboarding/onboarding_page.dart`
**FF source**: `flutterflow_application/akeli/lib/inscriptionpage/inscriptionpage_widget.dart`
**Stitch source**: `stitch/onboarding/`

---

## Step 1: [BASE] Widget Tree

- **GestureDetector** (dismiss keyboard)
  - **Scaffold** (bg: secondaryBackground)
    - **SafeArea**
      - **Column**
        - **Expanded** → **Container** (h: 500)
          - **Stack**
            - **Padding** (bottom: 40)
              - **PageView** (horizontal scroll, 6 pages)
                - **Page 0: Language Selection**
                  - Column (center, padding: 20)
                    - Container (bg: primaryBackground, h: 700, w: 100%)
                    - **Text** ("Choisir sa langue", headlineSmall Outfit)
                    - **FutureBuilder** (LanguageTable)
                      - **FlutterFlowDropDown** (w: 200, h: 40, bg: secondaryBackground, radius: 8, border: transparent)
                    - **FFButtonWidget** ("Valider", primary bg, white text, radius: 8, h: 40)
                - **Page 1: Consent / CGU**
                  - Column (center)
                    - **Row** (center)
                      - ClipRRect image (50x50, Akeli logo)
                      - Text ("AKELI", headlineMedium Outfit, primary)
                    - **Text** ("Bienvenue dans votre application...", titleLarge Outfit, primary, center)
                    - **Text** ("Avant de commencer, veuillez accepter...", labelLarge Poppins, center)
                    - **Consent Card** (bg: primaryBackground, radius: 12, padding: 15)
                      - **Text** ("📋 Consentement requis", titleLarge Outfit, secondaryText)
                      - **Section: Données collectées**
                        - Icon (info, 24px, accent1) + Text ("Données collectées", bodyMedium)
                        - Bullet list: "Poids, taille, âge...", "Allergies...", "Historique..."
                      - **Section: Vos droits**
                        - Icon (info, 24px, accent1) + Text ("Vos droits", bodyMedium)
                        - Text ("Accès, rectification, suppression...", w: 300)
                      - **Divider** (thickness: 3, color: secondaryBackground)
                      - **Checkbox RGPD** (activeColor: primary, side: 2px alternate, radius: 4)
                        - Text ("J'accepte les conditions...") + InkWell → "Lire les CGU" (underlined, primary) → navigates to CguWidget
                      - **Checkbox CGU** (activeColor: primary, side: 2px alternate, radius: 4)
                        - Text ("J'accepte la collecte...") + InkWell → "Lire la politique..." (underlined, primary) → navigates to RgpdWidget
                    - **Conditional Button** (if both checkboxes checked)
                      - FFButtonWidget ("Confirmer", alternate bg disabled OR primary bg enabled, white text, radius: 8, h: 40)
                        - onTap: Update CGU + confidentiality → nextPage
                - **Page 2: Health Parameters**
                  - SingleChildScrollView
                  - **Row** (justify: end) → "Passer" (underlined, labelMedium) + arrow_forward_sharp → HomePage
                  - **Text** ("Créons votre profil personnalisé", headlineLarge Outfit, primary, center)
                  - **Name Section**
                    - Text ("Comment vous appelez-vous ?", titleLarge Outfit)
                    - **FutureBuilder** (UsersRow)
                      - TextFormField (w: 200, bg: primaryBackground, radius: 8, border: 1px alternate, focused: transparent)
                  - **Age Section**
                    - RichText ("Quel âge avez-vous ?" + "(16-99 ans)", titleLarge Outfit)
                    - TextFormField (w: 200, bg: primaryBackground, radius: 8, border: 1px alternate, keyboardType: number)
                    - Conditional error text ("Veuillez entrer un âge valide", bodyMedium, accent2)
                  - **Sex Section**
                    - Text ("Quel est votre sexe ?", titleLarge Outfit)
                    - **FlutterFlowDropDown** (options: "Masculin", "Féminin", w: 200, h: 40, bg: primaryBackground, radius: 8)
                  - **Weight Section**
                    - RichText ("Quel est votre poids actuel ?" + "(12-300 kg)", titleLarge Outfit)
                    - TextFormField (w: 200, bg: primaryBackground, radius: 8, border: 1px alternate, keyboardType: decimal)
                    - Conditional error text (accent2)
                  - **Height Section**
                    - RichText ("Quel est votre taille ?" + "(100-250 cm)", titleLarge Outfit)
                    - TextFormField (w: 200, bg: primaryBackground, radius: 8, border: 1px alternate, keyboardType: number)
                    - Conditional error text (accent2)
                  - **Activity Level Section**
                    - Text ("Pratiquez vous une activité physique ?", titleLarge Outfit)
                    - **FlutterFlowRadioButton** (4 options vertical, primary radio, labelMedium Poppins)
                      - "Aucune (travail de bureau...)"
                      - "Légère (marche occasionnelle...)"
                      - "Modéré (sport 3-4x/semaine)"
                      - "Intensive (sport quotidien...)"
                  - **FFButtonWidget** ("Suivant", primary bg, white text, radius: 8, h: 40)
                    - onTap: Validate ranges → insert/update UserHealthParameter → nextPage
                - **Page 3: Goals**
                  - SingleChildScrollView
                  - **Row** (justify: end) → "Passer" (underlined) + arrow → HomePage
                  - **Text** ("Quels sont vos objectifs ?", headlineLarge Outfit, primaryText, center)
                  - **Target Weight Section**
                    - Text ("Le poids que vous voulez atteindre...", titleLarge Outfit)
                    - TextFormField (w: 200, bg: primaryBackground, radius: 8, border: 1px alternate)
                      - onFieldSubmitted: calls calculateRegimeTime API → sets riskLevel, riskMessage, time
                  - **Timeline Slider Section**
                    - Text ("En combien de mois voulez-vous...", titleLarge Outfit, center)
                    - **Slider.adaptive** (min: 0, max: 12, divisions: 12, activeColor: accent1, inactiveColor: alternate)
                  - **Weekly Loss Display** (conditional)
                    - RichText ("{weeklyLoss} kg par semaine", titleMedium Poppins, primary)
                  - **Risk Message** (conditional)
                    - Container (w: 300)
                    - Text (riskMessage, titleSmall Poppins, color by riskLevel: safe=primary, moderate=secondary, dangerous=accent2)
                  - **Motivation Section**
                    - RichText ("Quelles sont vos motivations ?" + "(Optionnel)", titleLarge Outfit, center)
                    - TextFormField (w: 300, bg: primaryBackground, radius: 8, border: 1px alternate, maxLines: 8)
                  - **Navigation Row** (gap: 30)
                    - FFButtonWidget ("Précédent", transparent bg, primary border/text, radius: 8, h: 40)
                    - FFButtonWidget ("Suivant", primary bg, white text, radius: 8, h: 40)
                      - onTap: insert/update UserGoal → nextPage
                - **Page 4: Preferences**
                  - SingleChildScrollView
                  - **Row** (justify: end) → "Passer" (underlined) + arrow → HomePage
                  - **Text** ("Quelles sont vos préférences ?", headlineLarge Outfit, center)
                  - **Diet Section**
                    - Text ("Avez vous un régime particulier ?", titleLarge Outfit)
                    - **CheckboxListTile** ("Sans Porc", labelLarge Poppins, activeColor: primary, radius: 8, tileColor: secondaryBackground)
                    - **CheckboxListTile** ("Sans Viande", labelLarge Poppins, activeColor: primary, radius: 8, tileColor: secondaryBackground)
                  - **Allergies Section**
                    - Text ("Avez vous des allergies ?", titleLarge Outfit)
                    - Container (bg: secondaryBackground)
                      - **FutureBuilder** (UserAllergiesRow list)
                        - **ListView.builder**
                          - Per allergy: Row
                            - Text (allergy name, titleSmall, secondaryText) OR TextfieldWidget (if editing)
                            - If editing: Icon (check_rounded, 24px) → save
                            - If not editing: Icon (edit, 24px) → toggle edit mode
                            - Icon (delete_rounded, 24px) → delete
                      - **Add Allergy Row**
                        - TextFormField (w: 250, bg: secondaryBackground, radius: 8, hintText: "Entrez vos Allergies")
                        - Icon (add_circle_rounded, 32px, primaryText) → insert
                  - **Food Region Section**
                    - Text ("Quelle est votre gastronomie préférée ?", titleLarge Outfit, center)
                    - **FlutterFlowRadioButton** (7 options vertical, primary radio)
                      - "Afrique du Nord", "Afrique de l'Ouest", "Afrique Centrale", "Afrique de l'Est", "Afrique du Sud", "Caraïbes", "Européenne"
                  - **Special Diet Text**
                    - Text ("Optez vous pour un régime particulier ?", titleLarge Outfit, center)
                    - TextFormField (w: 200, bg: secondaryBackground, radius: 8, hintText: "TextField")
                  - **Navigation Row** (gap: 30)
                    - FFButtonWidget ("Précédent", primary bg, white text, radius: 8, h: 40)
                    - FFButtonWidget ("Confirmer", primary bg, white text, radius: 8, h: 40)
                      - onTap: insert/update UserPreferences → call dietPlan API → if success: nextPage, else: showModalBottomSheet (DietPlanErrorWidget, h: 400)
                - **Page 5: Summary**
                  - SingleChildScrollView
                  - **Text** ("Récapitulatif", displaySmall Outfit, normal weight, padding: 24/0)
                  - **Text** ("Voici un résumé de votre profil...", bodyMedium Poppins, secondaryText, lineHeight: 1.4, padding: 24/0)
                  - **Profile Summary Card** (bg: primaryBackground, radius: 16, padding: 0/24)
                    - **Row** (padding: 12)
                      - Container (48x48, circle, bg: accent1, Icon: person_sharp, primaryBackground)
                      - **FutureBuilder** (UsersRow + UserHealthParameterRow)
                        - RichText ("{name} {age} ans, {height} cm, {weight} kg", titleMedium Poppins 600w)
                    - **Activity Row** (padding: 12)
                      - Container (48x48, circle, bg: primary, Icon: fitness_center, white)
                      - **FutureBuilder** (UserHealthParameterRow)
                        - Text ("Niveau d'activité: {activityLevel}", bodyMedium Poppins)
                    - **Goal Row** (padding: 12)
                      - Container (48x48, circle, bg: secondary, Icon: flag, white)
                      - **FutureBuilder** (UserGoalRow)
                        - Text ("Objectif: {targetWeight} kg en {targetTime} mois", bodyMedium Poppins)
                        - Text ("Motivation: {objectif}", bodySmall Poppins, secondaryText)
                    - **Preference Row** (padding: 12)
                      - Container (48x48, circle, bg: primary, Icon: restaurant, white)
                      - **FutureBuilder** (UserPreferencesRow)
                        - Text ("Région: {foodRegion}", bodyMedium Poppins)
                        - Text ("Régime: {particularDiet}", bodySmall Poppins, secondaryText)
                  - **FFButtonWidget** ("Commencer l'aventure", primary bg, white text, radius: 8, h: 40, w: 230, center)
                    - onTap: navigate to HomePageWidget

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens (Light Mode)
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | Buttons, checkboxes, radio buttons, AKELI logo, safe risk text |
| secondary | `#FF9F1C` | Moderate risk text, goal icon bg |
| tertiary | `#3F3F44` | Loading spinner |
| alternate | `#E5E5E5` | Checkbox borders, slider inactive, disabled button bg |
| primaryText | `#2F2F2F` | Body text, profile summary text |
| secondaryText | `#5A5A5A` | Consent text, labels, inactive radio, subtitle text |
| primaryBackground | `#F9F9E8` | Page 0 bg, form field bg, summary card bg |
| secondaryBackground | `#FFFFFF` | Scaffold bg, card bg, dropdown bg |
| accent1 | `#4D96FF` | Info icons, profile icon bg, slider active, goal text |
| accent2 | `#FF6B6B` | Validation errors, dangerous risk text |
| info | `#FFFFFF` | Button text, check color |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| displaySmall | Outfit | 48px | 400 (normal) | primaryText |
| headlineLarge | Outfit | 32px | 500 | primary/primaryText |
| headlineMedium | Outfit | 24px | 400 | primary |
| headlineSmall | Outfit | 24px | 500 | primaryText |
| titleLarge | Outfit | 22px | 500 | primary/primaryText/secondaryText |
| titleMedium | Poppins | 18px | 400/600 | primaryText |
| titleSmall | Poppins | 16px | 500 | primaryText/white |
| labelLarge | Poppins | 16px | 400 | secondaryText |
| labelMedium | Poppins | 14px | 400 | secondaryText |
| bodyMedium | Poppins | 14px | 400 | primaryText/secondaryText |
| bodySmall | Poppins | 12px | 400 | secondaryText |

### Spacing & Radius
| Token | Value |
|-------|-------|
| sm | 4px |
| md | 8px |
| lg | 16px |
| xl | 24px |

### Widget-Specific Attributes
- **Scaffold**: bg: #FFFFFF
- **PageView**: 6 pages, horizontal scroll
- **Page 0 (Language)**: Container bg: #F9F9E8, h: 700, centered column
  - Dropdown: w: 200, h: 40, bg: #FFFFFF, radius: 8, transparent border
  - Button: h: 40, bg: #3BB78F, white text, radius: 8
- **Page 1 (Consent)**: Card bg: #F9F9E8, radius: 12, padding: 15
  - Checkboxes: activeColor: #3BB78F, side: 2px #E5E5E5, radius: 4
  - Links: underlined, primary (#3BB78F)
  - Divider: thickness: 3, color: #FFFFFF
- **Page 2 (Health)**: Form fields w: 200, bg: #F9F9E8, radius: 8, border: 1px #E5E5E5, focused: transparent
  - RadioButton: primary (#3BB78F), optionHeight: 32, vertical
  - Error text: bodyMedium, accent2 (#FF6B6B)
- **Page 3 (Goals)**: Slider: activeColor: accent1 (#4D96FF), inactiveColor: #E5E5E5, min: 0, max: 12, divisions: 12
  - Risk message colors: safe=#3BB78F, moderate=#FF9F1C, dangerous=#FF6B6B
  - Motivation field: w: 300, maxLines: 8
- **Page 4 (Preferences)**: CheckboxListTile: tileColor: #FFFFFF, radius: 8, padding: 12/0, activeColor: #3BB78F
  - Allergy list: bg: #FFFFFF, edit/delete icons 24px
  - Add field: w: 250, bg: #FFFFFF, radius: 8, transparent border
  - Add icon: add_circle_rounded, 32px, primaryText
  - RadioButton: 7 options, primary (#3BB78F)
- **Page 5 (Summary)**: Summary card bg: #F9F9E8, radius: 16
  - Icon containers: 48x48, circle, colored bg + white icon
    - Profile: accent1 (#4D96FF)
    - Activity: primary (#3BB78F)
    - Goal: secondary (#FF9F1C)
    - Preference: primary (#3BB78F)
  - Final button: w: 230, h: 40, bg: #3BB78F, white text, radius: 8
- **All buttons**: h: 40, radius: 8, padding: 16/0, elevation: 0
- **Navigation buttons**: "Précédent" (transparent/primary border), "Suivant" (primary bg)
- **"Passer" links**: labelMedium Poppins, underlined, secondaryText, with arrow_forward_sharp 18px

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Onboarding/Inscription multi-page wizard into a high-fidelity, modern "Digital Editorial" onboarding experience that feels premium, conversational, and frictionless.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for all primary containers and cards. Replace the current 8px/12px/16px radii.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text. Create conversational, question-based prompts instead of form labels.
> - **Visual Air**: Increase white space between form fields (24px minimum). Use generous padding (32px minimum on cards). Each step should feel like a single focused question.
> - **Interactive Cues**: Apply subtle shadows (`shadow-sm`) on cards. Use the brand Teal (#3BB78F) as the primary accent consistently. Add progress indicators (dots or bar) showing wizard progress.
> - **Conversational Design**: Replace form-field-heavy layout with large, centered questions and minimal input fields. Think Typeform-style onboarding.
>
> **Functional Structure to Preserve**:
> - **6-page PageView wizard** with horizontal swipe navigation
> - **Page 0**: Language selection dropdown + validate button
> - **Page 1**: Consent/CGU — data collection notice, user rights, two checkboxes (RGPD + CGU), links to read full policies, confirm button (disabled until both checked)
> - **Page 2**: Health parameters — name, age (16-99), sex, weight (12-300kg), height (100-250cm), activity level (4 radio options), validation with error messages, "Passer" skip link
> - **Page 3**: Goals — target weight, timeline slider (0-12 months), weekly weight loss calculation, risk level message (safe/moderate/dangerous), optional motivation text, nav buttons
> - **Page 4**: Preferences — Sans Porc checkbox, Sans Viande checkbox, allergies list (CRUD: add/edit/delete), food region radio (7 African regions + European), special diet text, nav buttons, diet plan API call
> - **Page 5**: Summary — profile card with icon sections (name/age/weight/height, activity level, goals, preferences), "Commencer l'aventure" CTA → HomePage
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **Column**
>     - **ProgressBar** (top, mx: 32, mt: 16)
>       - **LinearProgressIndicator** (h: 4px, radius: 4px, progress: currentPage/6, progressColor: Teal, bg: cream)
>     - **Expanded** → **PageView** (6 pages)
>       - **Page 0: Language**
>         - **Column** (center, gap: 32)
>           - **Text** ("Choisir votre langue", 28px, Bold, Plus Jakarta Sans)
>           - **Dropdown** (w: 280, bg: #FFFFFF, rounded-2xl [16px], p: 16, shadow-sm)
>           - **Button** ("Valider", w: 280, bg: Teal, white text, rounded-2xl [16px], h: 52px)
>       - **Page 1: Consent**
>         - **Column** (center, px: 24, gap: 24)
>           - **Text** ("Bienvenue sur Akeli", 28px, Bold, Plus Jakarta Sans)
>           - **Text** ("Avant de commencer...", 15px, Inter, muted)
>           - **ConsentCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm)
>             - **Text** ("📋 Consentement", 18px, Bold, Plus Jakarta Sans)
>             - **SizedBox** (h: 16)
>             - **Section** ("Données collectées", 14px, Bold, Inter)
>               - Bullet list (13px, Inter, muted)
>             - **SizedBox** (h: 16)
>             - **Section** ("Vos droits", 14px, Bold, Inter)
>               - Text (13px, Inter, muted)
>             - **Divider** (h: 16)
>             - **Checkbox** ("J'accepte les CGU", 14px, Inter) + **TextButton** ("Lire les CGU", primary)
>             - **Checkbox** ("J'accepte la politique de confidentialité", 14px, Inter) + **TextButton** ("Lire", primary)
>           - **Button** ("Confirmer", full-width, bg: Teal if both checked else muted, white text, rounded-2xl [16px], h: 52px)
>       - **Page 2: Profile**
>         - **Column** (px: 24, gap: 24)
>           - **Row** (justify: end)
>             - **TextButton** ("Passer →", 14px, Inter, muted)
>           - **Text** ("Votre profil", 28px, Bold, Plus Jakarta Sans, center)
>           - **FormCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm)
>             - **Column** (spacing: 20)
>               - **QuestionInput** ("Comment vous appelez-vous ?", 16px, Bold, Inter)
>                 - **TextField** (bg: cream, rounded-2xl [16px], p: 16, 16px Inter)
>               - **QuestionInput** ("Quel âge avez-vous ? (16-99)", 16px, Bold, Inter)
>                 - **TextField** (bg: cream, rounded-2xl [16px], p: 16, 16px Inter, numeric)
>               - **QuestionInput** ("Quel est votre sexe ?", 16px, Bold, Inter)
>                 - **SegmentedButton** (Masculin / Féminin, rounded-full, active: Teal bg)
>               - **QuestionInput** ("Quel est votre poids ? (12-300 kg)", 16px, Bold, Inter)
>                 - **TextField** (bg: cream, rounded-2xl [16px], p: 16, 16px Inter, decimal)
>               - **QuestionInput** ("Quelle est votre taille ? (100-250 cm)", 16px, Bold, Inter)
>                 - **TextField** (bg: cream, rounded-2xl [16px], p: 16, 16px Inter, numeric)
>               - **QuestionInput** ("Niveau d'activité physique ?", 16px, Bold, Inter)
>                 - **RadioOptions** (4 options, vertical, gap: 12, 14px Inter, active: Teal dot)
>           - **Button** ("Suivant", full-width, bg: Teal, white text, rounded-2xl [16px], h: 52px)
>       - **Page 3: Goals**
>         - **Column** (px: 24, gap: 24)
>           - **Row** (justify: end) → **TextButton** ("Passer →", 14px, Inter, muted)
>           - **Text** ("Vos objectifs", 28px, Bold, Plus Jakarta Sans, center)
>           - **GoalCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm)
>             - **QuestionInput** ("Poids cible (kg)", 16px, Bold, Inter)
>               - **TextField** (bg: cream, rounded-2xl [16px], p: 16, 16px Inter)
>             - **SizedBox** (h: 24)
>             - **QuestionInput** ("En combien de mois ?", 16px, Bold, Inter, center)
>               - **Slider** (min: 0, max: 12, activeColor: accent1, thumb: Teal, track: rounded)
>               - **Text** ("{months} mois", 20px, Bold, Plus Jakarta Sans, center)
>             - **SizedBox** (h: 16)
>             - **RiskBadge** (conditional, rounded-full, px: 16, py: 8, colored by risk)
>               - **Text** ("{riskMessage}", 13px, Inter, colored)
>             - **SizedBox** (h: 24)
>             - **QuestionInput** ("Vos motivations ? (optionnel)", 16px, Bold, Inter, center)
>               - **TextArea** (bg: cream, rounded-2xl [16px], p: 16, 14px Inter, h: 120)
>           - **Row** (gap: 12)
>             - **Button** ("Précédent", flex: 1, outlined Teal, rounded-2xl [16px], h: 52px)
>             - **Button** ("Suivant", flex: 1, bg: Teal, white text, rounded-2xl [16px], h: 52px)
>       - **Page 4: Preferences**
>         - **Column** (px: 24, gap: 24)
>           - **Row** (justify: end) → **TextButton** ("Passer →", 14px, Inter, muted)
>           - **Text** ("Vos préférences", 28px, Bold, Plus Jakarta Sans, center)
>           - **PreferenceCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm)
>             - **QuestionInput** ("Régimes particuliers", 16px, Bold, Inter)
>               - **ToggleRow** ("Sans Porc", toggle switch)
>               - **ToggleRow** ("Sans Viande", toggle switch)
>             - **SizedBox** (h: 20)
>             - **QuestionInput** ("Allergies", 16px, Bold, Inter)
>               - **AllergyList** (spacing: 8)
>                 - **AllergyChip** (bg: cream, rounded-full, px: 12, py: 6)
>                   - **Text** (allergy name, 13px, Inter)
>                   - **Icon** (close, 14px, muted)
>               - **AddAllergyRow** (mt: 8, gap: 8)
>                 - **TextField** (flex: 1, bg: cream, rounded-xl [12px], p: 12, 14px Inter)
>                 - **IconButton** (add, circle, bg: Teal, icon: white)
>             - **SizedBox** (h: 20)
>             - **QuestionInput** ("Gastronomie préférée", 16px, Bold, Inter)
>               - **RadioOptions** (7 regions, vertical, gap: 10, 14px Inter)
>             - **SizedBox** (h: 16)
>             - **TextField** ("Régime particulier (optionnel)", bg: cream, rounded-2xl [16px], p: 16, 14px Inter)
>           - **Row** (gap: 12)
>             - **Button** ("Précédent", flex: 1, outlined Teal, rounded-2xl [16px], h: 52px)
>             - **Button** ("Confirmer", flex: 1, bg: Teal, white text, rounded-2xl [16px], h: 52px)
>       - **Page 5: Summary**
>         - **Column** (px: 24, gap: 24)
>           - **Text** ("Récapitulatif", 32px, Bold, Plus Jakarta Sans)
>           - **Text** ("Voici votre profil personnalisé", 15px, Inter, muted)
>           - **SummaryCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm)
>             - **ProfileHeader** (flex, items-center, gap: 16)
>               - **Avatar** (48x48, circle, bg: accent1, icon: person, white)
>               - **Text** ("{Name}, {age} ans, {weight} kg, {height} cm", 16px, Bold, Inter)
>             - **Divider** (h: 16)
>             - **SummarySection** (flex, items-center, gap: 12)
>               - **IconBadge** (24x24, circle, bg: primary, icon: fitness_center, white)
>               - **Column**
>                 - **Text** ("Activité", 12px, Inter, muted, uppercase)
>                 - **Text** ("{activityLevel}", 14px, Inter)
>             - **SummarySection** (flex, items-center, gap: 12)
>               - **IconBadge** (24x24, circle, bg: secondary, icon: flag, white)
>               - **Column**
>                 - **Text** ("Objectif", 12px, Inter, muted, uppercase)
>                 - **Text** ("{targetWeight} kg en {months} mois", 14px, Inter)
>             - **SummarySection** (flex, items-center, gap: 12)
>               - **IconBadge** (24x24, circle, bg: primary, icon: restaurant, white)
>               - **Column**
>                 - **Text** ("Préférences", 12px, Inter, muted, uppercase)
>                 - **Text** ("{foodRegion}", 14px, Inter)
>           - **Button** ("Commencer l'aventure", full-width, bg: Teal, white text, rounded-2xl [16px], h: 52px, shadow-md)
>
> **Meal Type Color System**:
> | Type | Badge Color | Text Color | Icon |
> |------|------------|------------|------|
> | Petit-Déjeuner | #FFF3E0 | #FF9F1C | wb_sunny_rounded |
> | Déjeuner | #E8F5E9 | #3BB78F | lunch_dining_rounded |
> | Collation | #E3F2FD | #4D96FF | cookie_rounded |
> | Dîner | #E0F2F1 | #006A63 | dinner_dining_rounded |
