# Audit: Referral Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/referral/referral_page.dart`
**FF source**: `flutterflow_application/akeli/lib/referral/referral_widget.dart`
**Stitch source**: `stitch/referral/`

---

## Step 1: [BASE] Widget Tree

- **FutureBuilder** (ReferralRow by currentUserUid — loading: SpinKitDoubleBounce centered)
  - **GestureDetector** (dismiss keyboard)
    - **Scaffold** (bg: primaryBackground)
      - **AppBar** (bg: primary, elevation: 2, centerTitle: true, no leading)
        - **leading**: FlutterFlowIconButton (arrow_back_rounded, 30px, secondaryBackground, borderRadius: 30, buttonSize: 60) → pop
      - **SafeArea**
        - **Expanded** → **AuthUserStreamWidget** → **FutureBuilder** (UserSubscriptionRow)
          - **SingleChildScrollView** (center)
            - **Conditional**: if no referral exists
              - Container (bg: primaryBackground, padding: 20)
              - **Text** ("Créer un code de parrainage", titleLarge Outfit)
              - **Text** ("L'applicatino vous a plu ? Vo...", bodyMedium Poppins, center)
              - **TextFormField** (w: 200, bg: secondaryBackground, radius: 8, hintText: "Entrez votre nom")
              - **FFButtonWidget** ("Créer", primary bg, white text, radius: 8, h: 40) → createAReferralCall
              - **Text** ("Vous avez déja un code de parrainage ?", titleMedium Poppins, center)
              - **TextFormField** (w: 200, bg: secondaryBackground, radius: 8, hintText: "Entrez votre code")
              - **FFButtonWidget** ("Créer", primary bg, white text, radius: 8, h: 40) → update referral by code
            - **Conditional**: if referral exists
              - **Text** ("Votre code de parrainage est le suivant", headlineMedium Outfit, center)
              - **Row** (center, gap: 10)
                - **Text** (referralCode, headlineMedium Outfit)
                - **Conditional**: if !editCode
                  - Icon (edit, 24px) → toggle edit mode
                - **Conditional**: if editCode
                  - **TextFormField** (w: 200, bg: secondaryBackground, radius: 8, controller: code text)
                  - Icon (check_rounded, 24px, primary) → save code
              - **Text** ("Nombre de filleul", titleLarge Outfit, center)
              - **Text** ("{filleulCount}", headlineMedium Outfit, secondary)
              - **Text** ("Vous avez déja un code de parrainage ?", titleMedium Poppins, center)
              - **TextFormField** (w: 200, bg: secondaryBackground, radius: 8, hintText: "Entrez un autre code")
              - **FFButtonWidget** ("Créer", primary bg, white text, radius: 8, h: 40) → update referral

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | AppBar bg, buttons |
| secondary | `#FF9F1C` | Filleul count text |
| primaryBackground | `#F9F9E8` | Scaffold bg |
| secondaryBackground | `#FFFFFF` | Text field bg |
| primaryText | `#2F2F2F` | Body text |
| tertiary | `#3F3F44` | Loading spinner |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| headlineMedium | Outfit | 24px | 400 | primaryText (referral code display) |
| titleLarge | Outfit | 22px | 500 | primaryText (section headers) |
| titleMedium | Poppins | 18px | 400 | primaryText |
| bodyMedium | Poppins | 14px | 400 | primaryText (descriptions) |
| titleSmall | Poppins | 16px | 500 | white (button text) |

### Widget-Specific Attributes
- **AppBar**: bg: #3BB78F, elevation: 2, centerTitle: true
- **Back button**: arrow_back_rounded, 30px, white, borderRadius: 30, buttonSize: 60
- **Text fields**: w: 200, bg: #FFFFFF, radius: 8px, transparent border
- **Buttons**: h: 40, bg: primary, white text, radius: 8px, padding: 16/0
- **Section spacing**: 10px gap between elements

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Referral page into a clean, modern referral code management experience.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for cards.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text.
> - **Visual Air**: Increase padding inside cards (24px). Center the referral code prominently.
> - **Interactive Cues**: Use the brand Teal (#3BB78F) for action buttons and the referral code display.
>
> **Functional Structure to Preserve**:
> - If no referral: Create new code OR enter existing code
> - If referral exists: Display code (editable), show filleul count, option to change code
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **AppBar** (bg: transparent, elevation: 0)
>     - **BackButton** (circle, bg: white/80, icon: arrow_back)
>   - **SingleChildScrollView** (px: 16, py: 24)
>     - **Column** (spacing: 24, center)
>       - **Text** ("Parrainage", 28px, Bold, Plus Jakarta Sans)
>       - **ReferralCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm, center)
>         - **IconBadge** (48x48, circle, bg: primary/15, icon: gift, primary)
>         - **SizedBox** (h: 16)
>         - **Text** ("Votre code de parrainage", 14px, Inter, muted)
>         - **Text** ("{CODE}", 32px, Bold, Plus Jakarta Sans, primary, letter-spacing: 4)
>         - **SizedBox** (h: 16)
>         - **Text** ("{count} filleul(s)", 16px, Inter, secondary)
>       - **ChangeCodeCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm)
>         - **Text** ("Changer de code", 16px, Bold, Plus Jakarta Sans)
>         - **TextField** (bg: cream, rounded-2xl [16px], p: 16, 15px Inter)
>         - **Button** ("Enregistrer", full-width, bg: Teal, white text, rounded-2xl [16px], h: 48px)
