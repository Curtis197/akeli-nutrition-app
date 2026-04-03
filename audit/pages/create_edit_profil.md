# Audit: Create/Edit Profile Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/profile/create_edit_profile_page.dart`
**FF source**: `flutterflow_application/akeli/lib/create_edit_profil/create_edit_profil_widget.dart`
**Stitch source**: `stitch/create_edit_profil/`

---

## Step 1: [BASE] Widget Tree

- **FutureBuilder** (UsersRow by currentUserUid — loading: SpinKitDoubleBounce centered)
  - **Scaffold** (bg: secondaryBackground)
    - **AppBar** (PreferredSize h: 100, bg: secondaryBackground, elevation: 0, no leading)
      - **FlexibleSpaceBar**
        - **Row** (padding-left: 12)
          - FlutterFlowIconButton (arrow_back_rounded, 30px, primary, borderRadius: 30, buttonSize: 50) → pop
        - **Text** ("Créer / Mettre à jour mon prof...", headlineMedium Outfit 22px, primary, center)
    - **SafeArea**
      - **Column**
        - **Container** (100x100, circle, bg: alternate)
          - **Visibility** (if profilImageUrl exists)
            - Padding (2px)
              - Container (90x90, circle, Image.memory — uploaded file)
        - **FFButtonWidget** ("Ajouter une image", primary bg, white text, radius: 8, h: 40) → selectMediaWithSourceBottomSheet
        - **SwitchListTile.adaptive** (title: "Compte public" titleLarge Outfit, subtitle: "Les autres utilisateeur pourro..." labelMedium Poppins, activeColor: alternate, activeTrackColor: primary)
          - onChanged: toggle public field on UsersRow → show SnackBar
        - **TextFormField** (labelText: userName or "entrer votre nom", border: 2px alternate, radius: 8, focused: primary, contentPadding: 20/24, textCapitalization: words)
        - **TextFormField** (labelText: description or "entrer votre description", border: 2px alternate, radius: 8, focused: primary, contentPadding: 20/24, maxLines: 5, textCapitalization: words)
        - **Text** ("Changer de langue", titleMedium Poppins, primaryText, center)
        - **FlutterFlowDropDown** (w: 200, h: 40, bg: secondaryBackground, radius: 8, transparent border, options: language names)
        - **FFButtonWidget** ("Confirmer", w: 150, h: 50, primary bg, white text titleMedium, radius: 12, elevation: 2, padding-top: 24)
          - onTap: Update UsersRow (user_name, description, public, language) → upload profile image if exists → setAppLanguage

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | Back button, title, button bg, focused borders, activeTrackColor |
| secondary | `#FF9F1C` | SnackBar bg |
| alternate | `#E5E5E5` | Avatar bg, field borders, activeColor |
| primaryText | `#2F2F2F` | Body text, language label |
| secondaryText | `#5A5A5A` | — |
| secondaryBackground | `#FFFFFF` | Scaffold bg, AppBar bg, field bg, dropdown bg |
| tertiary | `#3F3F44` | Loading spinner |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| headlineMedium | Outfit | 22px | 400 | primary (AppBar title) |
| titleLarge | Outfit | 22px | 500 | primaryText (switch title) |
| titleMedium | Poppins | 18px | 400 | primaryText (language label), white (button text) |
| labelMedium | Poppins | 14px | 400 | field labels, switch subtitle |
| bodyMedium | Poppins | 14px | 400 | field values |

### Widget-Specific Attributes
- **AppBar**: PreferredSize h: 100, bg: #FFFFFF, elevation: 0
- **Back button**: arrow_back_rounded, 30px, primary, buttonSize: 50
- **Avatar**: 100x100 circle, bg: alternate, inner: 90x90 circle
- **Add image button**: h: 40, bg: primary, white text, radius: 8px, padding: 16/0
- **SwitchListTile**: adaptive, activeColor: alternate, activeTrackColor: primary
- **Text fields**: border: 2px alternate, radius: 8px, focused: 2px primary, contentPadding: 20/24
- **Description field**: maxLines: 5
- **Dropdown**: w: 200, h: 40, bg: #FFFFFF, radius: 8px, transparent border
- **Confirm button**: w: 150, h: 50, bg: primary, white text titleMedium, radius: 12px, elevation: 2, padding-top: 24

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Create/Edit Profile page into a clean, modern profile editing experience.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for the profile card.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text.
> - **Visual Air**: Increase padding inside the card (24px). Use generous spacing between fields (16px).
> - **Interactive Cues**: Use the brand Teal (#3BB78F) for focused fields and action buttons.
>
> **Functional Structure to Preserve**:
> - Profile image upload with preview
> - Public/private account toggle
> - Name and description text fields
> - Language dropdown
> - Confirm button that saves all changes
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **AppBar** (bg: transparent, elevation: 0)
>     - **BackButton** (circle, bg: white/80, icon: arrow_back)
>   - **SingleChildScrollView** (px: 16, py: 24)
>     - **Column** (spacing: 24, center)
>       - **AvatarSection** (center)
>         - **Avatar** (100x100, circle, border: 3px primary, shadow-md)
>         - **SizedBox** (h: 8)
>         - **Button** ("Changer la photo", text-button, 14px Inter, primary)
>       - **ProfileCard** (bg: #FFFFFF, rounded-3xl [24px], p: 24, shadow-sm, full-width)
>         - **Column** (spacing: 16)
>           - **SwitchRow** (icon: public, title: "Compte public", subtitle: "Visible par les autres utilisateurs", switch)
>           - **Divider** (h: 1)
>           - **TextField** (label: "Nom", prefixIcon: person, bg: cream, rounded-2xl [16px], p: 16, 15px Inter)
>           - **TextField** (label: "Description", prefixIcon: description, bg: cream, rounded-2xl [16px], p: 16, 15px Inter, maxLines: 3)
>           - **Dropdown** (label: "Langue", options: [Français, English, العربية], bg: cream, rounded-2xl [16px], p: 16, 15px Inter)
>       - **Button** ("Enregistrer", full-width, bg: Teal, white text, rounded-2xl [16px], h: 52px, shadow-md)
