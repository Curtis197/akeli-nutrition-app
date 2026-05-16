# Audit: RGPD / Privacy Policy Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/legal/privacy_policy_page.dart`
**FF source**: `flutterflow_application/akeli/lib/rgpd/rgpd_widget.dart`
**Stitch source**: `stitch/rgpd/`

---

## Step 1: [BASE] Widget Tree

- **Scaffold** (bg: secondaryBackground)
  - **AppBar** (bg: primary, elevation: 2, centerTitle: true, no leading)
    - **leading**: FlutterFlowIconButton (arrow_back_rounded, 30px, secondaryBackground, borderRadius: 30, buttonSize: 60) → pop
  - **SafeArea**
    - **Column**
      - **FlutterFlowWebView** (full height, html: true, no scroll)
        - Inline HTML content: Privacy policy document with sections (responsable, données collectées, finalités, droits, sécurité, cookies, contact)

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | AppBar bg |
| secondaryBackground | `#FFFFFF` | Scaffold bg |

### Widget-Specific Attributes
- **AppBar**: bg: #3BB78F, elevation: 2, centerTitle: true
- **Back button**: arrow_back_rounded, 30px, white, borderRadius: 30, buttonSize: 60
- **WebView**: full screen height, inline HTML with embedded CSS styling

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the RGPD/Privacy Policy page into a clean, readable legal document view with native Flutter widgets instead of WebView.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for content cards.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text.
> - **Visual Air**: Increase padding between sections (24px). Use generous line height (1.6).
> - **Interactive Cues**: Use the brand Teal (#3BB78F) for section headers and links.
>
> **Functional Structure to Preserve**:
> - Back button on colored AppBar
> - Full privacy policy content: data controller, collected data, processing purposes, user rights, security, cookies, contact
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **AppBar** (bg: transparent, elevation: 0)
>     - **BackButton** (circle, bg: white/80, icon: arrow_back)
>   - **SingleChildScrollView** (px: 16, py: 20)
>     - **Column** (spacing: 24)
>       - **TitleSection** (center)
>         - **Text** ("Politique de Confidentialité", 24px, Bold, Plus Jakarta Sans)
>         - **Text** ("En vigueur au 28 octobre 2025", 13px, Inter, muted, italic)
>       - **SummaryCard** (bg: primary/5, rounded-3xl [24px], p: 20)
>         - **Text** ("En résumé", 16px, Bold, Plus Jakarta Sans)
>         - **BulletList** (spacing: 8, 14px Inter)
>       - **SectionCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm)
>         - **Text** ("1. Responsable du traitement", 18px, Bold, Plus Jakarta Sans, primary)
>         - **SizedBox** (h: 12)
>         - **Text** (content, 15px, Inter, primaryText, lineHeight: 1.6)
>       - (Repeat for each section)
