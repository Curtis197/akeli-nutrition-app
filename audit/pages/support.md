# Audit: Support Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/support/support_page.dart`
**FF source**: `flutterflow_application/akeli/lib/support/support_widget.dart`
**Stitch source**: `stitch/support/`

---

## Step 1: [BASE] Widget Tree

- **Scaffold** (bg: secondaryBackground)
  - **AppBar** (bg: secondaryBackground, elevation: 0, centerTitle: false, no leading)
    - **leading**: FlutterFlowIconButton (arrow_back_rounded, 30px, primaryText, borderRadius: 30, buttonSize: 60) → pop
  - **SafeArea**
    - **Padding** (16/12/16/0)
      - **SingleChildScrollView**
        - **Column** (crossAxisAlignment: start)
          - **Padding** (top: 16)
            - **Column** (gap: 12)
              - **TextFormField** ("Votre nom", labelMedium Poppins, border: 2px alternate, radius: 12, focused: primary, contentPadding: 16/12)
              - **TextFormField** ("Votre mail", labelMedium Poppins, border: 2px alternate, radius: 12, focused: primary, contentPadding: 16/12)
              - **TextFormField** (hintText: "Faîtes nous part de votre ques...", labelMedium Poppins, border: 2px alternate, radius: 12, focused: primary, contentPadding: 16/24/16/12, maxLines: 16, minLines: 6)
              - **Conditional**: if uploaded file exists
                - ClipRRect (radius: 8, Image.memory, w: 200, h: 200)
          - **Padding** (top: 16)
            - **InkWell** → Container (full width, maxWidth: 500, bg: secondaryBackground, border: 2px alternate, radius: 12, padding: 8)
              - **Row**
                - Icon (add_a_photo_rounded, 32px, primary)
                - Text ("Upload Screenshot", bodyMedium Poppins, padding-left: 16)
          - **Padding** (top: 24, bottom: 12)
            - **FFButtonWidget** ("Envoyer", full-width, primary bg, white text titleSmall, radius: 60, h: 48, elevation: 4, icon: receipt_long 15px)
              - onTap: upload screenshot to Firebase → create SupportRecord (Firestore) → show SnackBar ("Merci de nous avoir contacter...")

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | Upload icon, button bg, focused borders |
| secondary | `#FF9F1C` | SnackBar bg |
| alternate | `#E5E5E5` | Field borders, upload container border |
| primaryText | `#2F2F2F` | Body text, back button |
| secondaryBackground | `#FFFFFF` | Scaffold bg, AppBar bg, field bg |
| tertiary | `#3F3F44` | Loading spinner |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| labelMedium | Poppins | 14px | 400 | field labels |
| bodyMedium | Poppins | 14px | 400 | upload text, field values |
| titleSmall | Poppins | 16px | 500 | white (button text) |

### Widget-Specific Attributes
- **AppBar**: bg: #FFFFFF, elevation: 0, centerTitle: false
- **Back button**: arrow_back_rounded, 30px, primaryText, buttonSize: 60
- **Text fields**: border: 2px alternate, radius: 12px, focused: 2px primary, contentPadding: 16/12
- **Message field**: maxLines: 16, minLines: 6, contentPadding: 16/24/16/12
- **Upload container**: maxWidth: 500, bg: #FFFFFF, border: 2px alternate, radius: 12px, padding: 8
- **Upload icon**: add_a_photo_rounded, 32px, primary
- **Send button**: full-width, h: 48, bg: primary, white text, radius: 60px (pill), elevation: 4, icon: receipt_long 15px right
- **Field gap**: 12px
- **Page padding**: 16/12/16/0

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Support page into a clean, modern contact form experience.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for the form card.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text.
> - **Visual Air**: Increase padding inside the form card (24px). Use generous spacing between fields (16px).
> - **Interactive Cues**: Use the brand Teal (#3BB78F) for focused fields and the send button.
>
> **Functional Structure to Preserve**:
> - Name, email, message fields
> - Screenshot upload with preview
> - Send button that creates a Firestore support record
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **AppBar** (bg: transparent, elevation: 0)
>     - **BackButton** (circle, bg: white/80, icon: arrow_back)
>   - **SingleChildScrollView** (px: 16, py: 20)
>     - **Column** (spacing: 20)
>       - **Text** ("Support", 28px, Bold, Plus Jakarta Sans)
>       - **Text** ("Faîtes-nous part de votre question ou problème", 15px, Inter, muted)
>       - **FormCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm)
>         - **Column** (spacing: 16)
>           - **TextField** (label: "Votre nom", prefixIcon: person, bg: cream, rounded-2xl [16px], p: 16, 15px Inter)
>           - **TextField** (label: "Votre mail", prefixIcon: mail, bg: cream, rounded-2xl [16px], p: 16, 15px Inter)
>           - **TextArea** (label: "Votre message", prefixIcon: message, bg: cream, rounded-2xl [16px], p: 16, 15px Inter, h: 160)
>           - **UploadArea** (dashed border, bg: cream/50, rounded-2xl [16px], p: 24, center)
>             - **Icon** (add_a_photo, 32px, primary)
>             - **Text** ("Upload Screenshot", 14px, Inter, primary)
>           - **ImagePreview** (conditional, w: 200, h: 200, rounded-2xl [16px])
>       - **Button** ("Envoyer", full-width, bg: Teal, white text, rounded-2xl [16px], h: 52px, shadow-md)
