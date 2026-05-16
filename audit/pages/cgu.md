# Audit: CGU / Terms of Service Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/legal/terms_of_service_page.dart`
**FF source**: `flutterflow_application/akeli/lib/cgu/cgu_widget.dart`
**Stitch source**: `stitch/cgu/`

---

## Step 1: [BASE] Widget Tree

- **Scaffold** (bg: secondaryBackground)
  - **AppBar** (bg: primary, elevation: 2, centerTitle: true, no leading)
    - **leading**: FlutterFlowIconButton (arrow_back_rounded, 30px, secondaryBackground, borderRadius: 30, buttonSize: 60) → pop
  - **SafeArea**
    - **Stack**
      - **FlutterFlowWebView** (h: 87% of screen, html: true, no scroll)
        - Inline HTML content: Terms of service document with embedded CSS

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
- **WebView**: 87% screen height, inline HTML with embedded CSS

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the CGU/Terms of Service page into a clean, readable legal document view with native Flutter widgets instead of WebView.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for content cards.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text.
> - **Visual Air**: Increase padding between sections (24px). Use generous line height (1.6).
> - **Interactive Cues**: Use the brand Teal (#3BB78F) for section headers.
>
> **Functional Structure to Preserve**:
> - Back button on colored AppBar
> - Full terms of service content
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **AppBar** (bg: transparent, elevation: 0)
>     - **BackButton** (circle, bg: white/80, icon: arrow_back)
>   - **SingleChildScrollView** (px: 16, py: 20)
>     - **Column** (spacing: 24)
>       - **TitleSection** (center)
>         - **Text** ("Conditions Générales d'Utilisation", 24px, Bold, Plus Jakarta Sans)
>         - **Text** ("En vigueur au ...", 13px, Inter, muted, italic)
>       - **SectionCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm)
>         - **Text** (section title, 18px, Bold, Plus Jakarta Sans, primary)
>         - **SizedBox** (h: 12)
>         - **Text** (content, 15px, Inter, primaryText, lineHeight: 1.6)
