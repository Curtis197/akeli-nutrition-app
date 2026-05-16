# Audit: Payment/Subscription Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/settings/payment_subscription_page.dart`
**FF source**: `flutterflow_application/akeli/lib/payment_subscription/payment_subscription_widget.dart`
**Stitch source**: `stitch/payment_subscription/`

---

## Step 1: [BASE] Widget Tree

- **Scaffold** (bg: primaryBackground)
  - **AppBar** (bg: primaryBackground, elevation: 0, centerTitle: true, no leading)
    - **leading**: FlutterFlowIconButton (arrow_back_rounded, 30px, primaryText, borderRadius: 30, buttonSize: 60) → safePop
  - **SafeArea** (padding-top: 12)
    - **Column** (crossAxisAlignment: center)
      - **Text** ("Option d'abonnement", headlineMedium Outfit 500w)
      - **Subscription Info Card** (padding: 16/12)
        - Container (bg: secondaryBackground, radius: 8, shadow: blur 5, offset 0,2)
        - **Text** ("Votre abonnement", titleLarge Outfit)
        - **Text** ("Vous bénéficiez d'un accès com...", labelMedium Poppins)
      - **Delete Account Card** (padding: 16/12)
        - Container (bg: secondaryBackground, radius: 8, shadow: blur 5, offset 0,2)
        - **CheckboxListTile** (title: "Supprimer mon compte" headlineSmall Outfit 1.5lh, subtitle: "Toutes vos données seront supp..." bodySmall Poppins, activeColor: primary)
      - **Cancel Subscription Card** (conditional: if paidPlan, padding: 16/12)
        - Container (bg: secondaryBackground, radius: 8, shadow: blur 5, offset 0,2)
        - **CheckboxListTile** (title: "Annuler l'abonnement" headlineSmall Outfit, subtitle: "Vous perdrez immédiatement l'a..." bodySmall Poppins, activeColor: primary)
      - **Get Subscription Card** (conditional: if freePlan, padding: 16/12)
        - Container (bg: secondaryBackground, radius: 8, shadow: blur 5, offset 0,2)
        - **CheckboxListTile** (title: "Annuler l'abonnement" headlineSmall Outfit, subtitle: "Vous perdrez immédiatement l'a..." bodySmall Poppins, activeColor: primary)
      - **Expanded** → **Column** (justify: end, padding-bottom: 30)
        - **FFButtonWidget** ("Confirmer", primary bg, white text titleSmall, radius: 8, h: 40)
          - onTap: Update UsersRow (free_plan, paid_plan) → if suppressAccount: delete user + sign out → else: navigate to HomePage

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | Checkbox activeColor, button bg |
| primaryText | `#2F2F2F` | Back button, body text |
| secondaryText | `#5A5A5A` | Checkbox inactive |
| primaryBackground | `#F9F9E8` | Scaffold bg, AppBar bg |
| secondaryBackground | `#FFFFFF` | Card bg |
| tertiary | `#3F3F44` | Loading spinner |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| headlineMedium | Outfit | 24px | 500 | primaryText (page title) |
| headlineSmall | Outfit | 24px | 500 | primaryText (checkbox titles, 1.5lh) |
| titleLarge | Outfit | 22px | 500 | primaryText (card title) |
| labelMedium | Poppins | 14px | 400 | card subtitle |
| bodySmall | Poppins | 12px | 400 | checkbox subtitles |
| titleSmall | Poppins | 16px | 500 | white (button text) |

### Widget-Specific Attributes
- **AppBar**: bg: #F9F9E8, elevation: 0, centerTitle: true
- **Back button**: arrow_back_rounded, 30px, primaryText, buttonSize: 60
- **Page title**: "Option d'abonnement", headlineMedium Outfit 500w, center
- **Cards**: bg: #FFFFFF, radius: 8px, shadow: blur 5, offset (0,2), color: #34111417
  - Card padding: 8/12
- **CheckboxListTile**: activeColor: primary, contentPadding: 12/0
- **Confirm button**: h: 40, bg: primary, white text, radius: 8px, padding: 16/0
- **Card gap**: 12px
- **Bottom padding**: 30px

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Payment/Subscription page into a clean, modern subscription management experience.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for all cards.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text.
> - **Visual Air**: Increase padding inside cards (20px). Use generous spacing between cards (16px).
> - **Interactive Cues**: Use the brand Teal (#3BB78F) for active states. Add warning styling for destructive actions.
>
> **Functional Structure to Preserve**:
> - Current subscription status display
> - Delete account option (with confirmation checkbox)
> - Cancel subscription option (if paid)
> - Confirm button that updates subscription settings
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **AppBar** (bg: transparent, elevation: 0)
>     - **BackButton** (circle, bg: white/80, icon: arrow_back)
>   - **SingleChildScrollView** (px: 16, py: 20)
>     - **Column** (spacing: 20)
>       - **Text** ("Abonnement", 28px, Bold, Plus Jakarta Sans)
>       - **StatusCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm)
>         - **Row** (items-center, gap: 12)
>           - **IconBadge** (40x40, circle, bg: primary/15, icon: star, primary)
>           - **Column**
>             - **Text** ("Plan actuel", 12px, Inter, muted, uppercase)
>             - **Text** ("{planName}", 18px, Bold, Plus Jakarta Sans)
>       - **DangerCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm, border: 1px accent2/20)
>         - **Text** ("Zone dangereuse", 14px, Bold, Inter, accent2, uppercase)
>         - **SizedBox** (h: 16)
>         - **SwitchRow** (icon: delete_forever, title: "Supprimer mon compte", subtitle: "Toutes vos données seront supprimées", switch)
>         - **SwitchRow** (conditional, icon: cancel, title: "Annuler l'abonnement", subtitle: "Perte immédiate de l'accès premium", switch)
>       - **Button** ("Confirmer", full-width, bg: Teal, white text, rounded-2xl [16px], h: 52px)
