# Audit: Auth / Login Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/auth/auth_page.dart`
**FF source**: `flutterflow_application/akeli/lib/user_authentification/authentification/authentification_widget.dart`
**Stitch source**: `stitch/auth/`

---

## Step 1: [BASE] Widget Tree

- **GestureDetector** (dismiss keyboard)
  - **Scaffold** (bg: primaryBackground)
    - **SafeArea**
      - **Stack**
        - **Align** (top-center)
          - **Column** (mainAxisAlignment: center)
            - **Header Section**
              - **Text** ("AKELI", displaySmall Outfit, primary, center)
              - **Text** ("Bienvenue sur Akeli", headlineSmall Outfit, center, padding-bottom: 40)
            - **Auth Card Container** (padding: 12, maxWidth: 570, h: 630 mobile / 530 tablet)
              - Container (bg: secondaryBackground, radius: 12, shadow: blur 4, offset 0,2, color: #33000000, border: 2px primaryBackground)
              - Padding (top: 12)
                - **Column**
                  - **TabBar** (isScrollable: true, labelPadding: 32/0, indicator: primary 3px)
                    - Tab 1: "S'inscrire" (titleMedium Poppins, labelColor: primaryText, unselectedLabelColor: secondaryText)
                    - Tab 2: "Se connecter" (titleMedium Poppins)
                  - **TabBarView** (2 tabs, Expanded)
                    - **Tab 1: Sign Up** (padding: 24/16/24/0)
                      - **SingleChildScrollView**
                        - **Column** (crossAxisAlignment: start)
                          - **Text** ("Se créer un compte", headlineMedium Outfit)
                          - **Text** ("Commencez avec Afrohealth inscrivez-vous...", labelMedium Poppins, padding-bottom: 24)
                          - **TextFormField** (Email, labelLarge Poppins, radius: 40, border: 2px alternate, focused: primary, contentPadding: 24, filled, bg: secondaryBackground, autofillHints: email, autofocus)
                          - **TextFormField** (Password, labelLarge Poppins, radius: 40, border: 2px alternate, focused: primary, contentPadding: 24, filled, suffixIcon: visibility toggle, autofillHints: password)
                          - **TextFormField** (Confirm Password, labelLarge Poppins, radius: 40, border: 2px alternate, focused: primary, contentPadding: 24, filled, suffixIcon: visibility toggle, autofillHints: password)
                          - **FFButtonWidget** ("Commencer", w: 230, h: 52, bg: primary, white text titleSmall Poppins, radius: 40, elevation: 3, center)
                            - onTap: Firebase create account → create Supabase UsersRow → create UserSubscription → create NotificationPreferences → navigate to InscriptionpageWidget
                    - **Tab 2: Login** (padding: 24/16/24/0)
                      - **SingleChildScrollView**
                        - **Column** (crossAxisAlignment: start)
                          - **Text** ("Heureux de vous revoir !", headlineMedium Outfit)
                          - **Text** ("Remplissez les information ci-dessous...", labelMedium Poppins, padding-bottom: 24)
                          - **TextFormField** (Email, labelLarge Poppins, radius: 12, border: 1px alternate, focused: primary, contentPadding: 24/24/0/24, filled, bg: secondaryBackground, autofillHints: email, autofocus)
                          - **TextFormField** (Password, labelLarge Poppins, radius: 12, border: 1px alternate, focused: primary, contentPadding: 24/24/0/24, filled, suffixIcon: visibility toggle, autofillHints: password)
                          - **FFButtonWidget** ("Se connecter", w: 230, h: 52, bg: primary, white text titleSmall Poppins, radius: 40, elevation: 3, center)
                            - onTap: Firebase sign in → create Supabase UsersRow if missing → if has goals + health params → HomePage, else → InscriptionpageWidget
                          - **FFButtonWidget** ("Mot de passe oublié ?", h: 44, transparent bg, transparent border, text: bold bodyMedium Poppins, radius: 40, padding: 32/0)
                            - onTap: Firebase resetPassword (requires email field filled)

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens (Light Mode)
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | "AKELI" logo, TabBar indicator, focused borders, buttons |
| primaryText | `#2F2F2F` | TabBar active label, body text |
| secondaryText | `#5A5A5A` | TabBar inactive label, password visibility toggle icon |
| primaryBackground | `#F9F9E8` | Scaffold bg, card border (2px) |
| secondaryBackground | `#FFFFFF` | Auth card bg, text field bg, "Mot de passe oublié" button bg |
| alternate | `#E5E5E5` | Text field borders |
| error | `#FF6B6B` | Error borders |
| info | `#FFFFFF` | Button text |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| displaySmall | Outfit | 48px | 700 | primary |
| headlineMedium | Outfit | 24px | 400 | primaryText |
| headlineSmall | Outfit | 24px | 500 | primaryText |
| titleMedium | Poppins | 18px | 400 | primaryText / secondaryText |
| titleSmall | Poppins | 16px | 500 | white (on buttons) |
| labelMedium | Poppins | 14px | 400 | secondaryText |
| labelLarge | Poppins | 16px | 400 | secondaryText (field labels) |
| bodyMedium | Poppins | 14px | 700 (bold) | primaryText |
| bodyLarge | Poppins | 16px | 400 | primaryText (field values) |

### Spacing & Radius
| Token | Value |
|-------|-------|
| sm | 4px |
| md | 8px |
| lg | 12px |
| xl | 24px |
| pill | 40px |

### Widget-Specific Attributes
- **Scaffold**: bg: #F9F9E8 (primaryBackground)
- **"AKELI" logo**: displaySmall Outfit 48px 700w, primary (#3BB78F), center
- **Welcome text**: headlineSmall Outfit 24px 500w, primaryText, center, padding-bottom: 40
- **Auth card**: maxWidth: 570, h: 630 (mobile) / 530 (tablet ≥768px), bg: #FFFFFF, radius: 12px, shadow: blur 4px, offset (0,2), color: #33000000, border: 2px #F9F9E8
- **TabBar**: isScrollable: true, labelPadding: 32/0, indicator: primary (#3BB78F) 3px thickness
  - Active label: titleMedium Poppins, primaryText
  - Inactive label: titleMedium Poppins, secondaryText
- **Sign-up fields**: radius: 40px (pill), border: 2px alternate, focused: 2px primary, contentPadding: 24 (all sides)
- **Login fields**: radius: 12px, border: 1px alternate, focused: 1px primary, contentPadding: 24/24/0/24
- **Primary buttons** ("Commencer" / "Se connecter"): w: 230, h: 52, bg: #3BB78F, white text titleSmall Poppins 500w, radius: 40px, elevation: 3, centered
- **"Mot de passe oublié" button**: h: 44, transparent bg, transparent border 2px, text: bodyMedium Poppins **bold**, radius: 40px, padding: 32/0, hoverColor: primaryBackground
- **Password visibility toggle**: visibility_outlined / visibility_off_outlined, 24px, secondaryText

### Animations
- **Container**: FadeIn (0→1, 400ms) + MoveUp (80→0, 400ms) + ScaleIn (0.8→1, 400ms, delay 150ms)
- **Tab content columns**: FadeIn (0→1, 400ms, delay 300ms) + MoveUp (20→0, 400ms, delay 300ms)

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Auth/Login page into a high-fidelity, modern "Digital Editorial" authentication experience that feels premium and trustworthy while preserving the dual-tab (Sign Up / Login) structure.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for the auth card. Replace the current 12px/40px radii with a consistent design language.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text. Make the "AKELI" logo a bold editorial statement.
> - **Visual Air**: Increase padding inside the auth card (32px minimum). Separate fields with generous spacing (20px gap).
> - **Interactive Cues**: Apply subtle shadows (`shadow-lg`) on the auth card. Use the brand Teal (#3BB78F) as the primary accent consistently.
> - **Field Design**: Transform pill-shaped fields into modern rounded rectangles (16px radius) with subtle backgrounds and clean label positioning.
>
> **Functional Structure to Preserve**:
> - **Top**: "AKELI" brand logo + "Bienvenue sur Akeli" welcome text
> - **Auth card**: Tabbed interface with "S'inscrire" and "Se connecter"
> - **Sign-up tab**: Email, Password, Confirm Password fields + "Commencer" CTA → navigates to onboarding
> - **Login tab**: Email, Password fields + "Se connecter" CTA + "Mot de passe oublié" button
> - **Password visibility toggles** on all password fields
> - **Auto-navigation**: After auth, check if user has goals/health params → Home or Onboarding
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8, center content)
>   - **Column** (mainAxisAlignment: center, px: 24)
>     - **BrandHeader** (center, mb: 32)
>       - **Text** ("AKELI", 40px, Bold, Plus Jakarta Sans, primary Teal, letter-spacing: 2px)
>       - **Text** ("Bienvenue sur Akeli", 16px, Inter, muted, mt: 8)
>     - **AuthCard** (bg: #FFFFFF, rounded-3xl [24px], w: 100%, maxWidth: 440, p: 32, shadow-lg)
>       - **TabBar** (borderless, indicator: rounded pill bg: primary/15, label: primary, unselectedLabel: muted, 14px Inter)
>         - **Tab** ("S'inscrire", 14px Inter)
>         - **Tab** ("Se connecter", 14px Inter)
>       - **TabBarView** (mt: 24)
>         - **SignUpTab**
>           - **Text** ("Créer votre compte", 24px, Bold, Plus Jakarta Sans)
>           - **Text** ("Rejoignez la communauté Akeli", 14px, Inter, muted, mb: 24)
>           - **Column** (spacing: 16)
>             - **TextField** (label: "Email", prefixIcon: mail_outline 20px, rounded-2xl [16px], bg: cream, 16px Inter)
>             - **TextField** (label: "Mot de passe", prefixIcon: lock_outline 20px, rounded-2xl [16px], bg: cream, visibility toggle suffix)
>             - **TextField** (label: "Confirmer le mot de passe", prefixIcon: lock_outline 20px, rounded-2xl [16px], bg: cream, visibility toggle suffix)
>           - **SizedBox** (h: 24)
>           - **Button** ("Commencer", full-width, bg: Teal, white text, rounded-2xl [16px], h: 52px, 16px Bold Inter, shadow-md)
>         - **LoginTab**
>           - **Text** ("Heureux de vous revoir !", 24px, Bold, Plus Jakarta Sans)
>           - **Text** ("Connectez-vous à votre compte", 14px, Inter, muted, mb: 24)
>           - **Column** (spacing: 16)
>             - **TextField** (label: "Email", prefixIcon: mail_outline 20px, rounded-2xl [16px], bg: cream, 16px Inter)
>             - **TextField** (label: "Mot de passe", prefixIcon: lock_outline 20px, rounded-2xl [16px], bg: cream, visibility toggle suffix)
>           - **SizedBox** (h: 24)
>           - **Button** ("Se connecter", full-width, bg: Teal, white text, rounded-2xl [16px], h: 52px, 16px Bold Inter, shadow-md)
>           - **SizedBox** (h: 16)
>           - **TextButton** ("Mot de passe oublié ?", 14px, Inter, primary, center)
>
> **Meal Type Color System**:
> | Type | Badge Color | Text Color | Icon |
> |------|------------|------------|------|
> | Petit-Déjeuner | #FFF3E0 | #FF9F1C | wb_sunny_rounded |
> | Déjeuner | #E8F5E9 | #3BB78F | lunch_dining_rounded |
> | Collation | #E3F2FD | #4D96FF | cookie_rounded |
> | Dîner | #E0F2F1 | #006A63 | dinner_dining_rounded |
