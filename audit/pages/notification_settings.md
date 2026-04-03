# Audit: Notification Settings Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/settings/notification_settings_page.dart`
**FF source**: `flutterflow_application/akeli/lib/notification_setting/notification_setting_widget.dart`
**Stitch source**: `stitch/notification_settings/`

---

## Step 1: [BASE] Widget Tree

- **AuthUserStreamWidget** → **FutureBuilder** (NotificationPreferencesRow — loading: SpinKitDoubleBounce centered)
  - **Scaffold** (bg: secondaryBackground)
    - **AppBar** (bg: secondaryBackground, elevation: 0, centerTitle: false, no leading)
      - **leading**: FlutterFlowIconButton (arrow_back_rounded, 25px, primaryText, borderRadius: 30, buttonSize: 46) → pop
      - **title**: Text ("Paratmètre de notification", headlineSmall Outfit)
    - **Padding** (top: 20)
      - **Column**
        - **SwitchListTile.adaptive** (padding: 12/0 top)
          - Title: "Push Notifications" (bodyLarge Poppins, lineHeight: 2)
          - Subtitle: "Recevez vos notifications sur..." (bodyMedium Poppins, #8B97A2)
          - activeColor: primary, activeTrackColor: alternate
          - contentPadding: 24/12
        - **SwitchListTile.adaptive**
          - Title: "Chat Notifications"
          - Subtitle: "Recevez les notifications de v..."
          - Same styling
        - **SwitchListTile.adaptive**
          - Title: "Notification de Repas"
          - Subtitle: "Recevez les notifications de t..."
          - Same styling
        - **SwitchListTile.adaptive**
          - Title: "Notification de demande de con..."
          - Subtitle: "Recevez vos notifications lors..."
          - Same styling
        - **FFButtonWidget** ("Mettre à jour", w: 190, h: 50, primary bg, white text titleSmall, radius: 12, center, padding-top: 24)
          - onTap: Update NotificationPreferencesRow (or insert if null) → refresh

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | Switch activeColor, button bg |
| primaryText | `#2F2F2F` | Back button, body text |
| secondaryText | `#5A5A5A` | Switch inactive, subtitle text |
| alternate | `#E5E5E5` | Switch activeTrackColor |
| secondaryBackground | `#FFFFFF` | Scaffold bg, AppBar bg, tile bg |
| tertiary | `#3F3F44` | Loading spinner |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| headlineSmall | Outfit | 24px | 500 | primaryText (AppBar title) |
| bodyLarge | Poppins | 16px | 400 | switch titles, lineHeight: 2 |
| bodyMedium | Poppins | 14px | 400 | switch subtitles, #8B97A2 |
| titleSmall | Poppins | 16px | 500 | white (button text) |

### Widget-Specific Attributes
- **AppBar**: bg: #FFFFFF, elevation: 0, centerTitle: false
- **Back button**: arrow_back_rounded, 25px, primaryText, buttonSize: 46
- **Title**: "Paratmètre de notification", headlineSmall Outfit
- **SwitchListTile**: adaptive, contentPadding: 24/12, activeColor: primary, activeTrackColor: alternate
- **Update button**: w: 190, h: 50, bg: primary, white text, radius: 12px, top padding: 24

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Notification Settings page into a clean, modern settings experience.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for the settings card container.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text.
> - **Visual Air**: Increase padding between switches (8px gap). Use a single card container for all settings.
> - **Interactive Cues**: Use the brand Teal (#3BB78F) for active switches.
>
> **Functional Structure to Preserve**:
> - Back button + title
> - 4 notification toggles: Push, Chat, Meal reminders, Conversation demands
> - "Mettre à jour" button to save changes
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **AppBar** (bg: transparent, elevation: 0)
>     - **BackButton** (circle, bg: white/80, icon: arrow_back)
>   - **SingleChildScrollView** (px: 16, py: 20)
>     - **Column** (spacing: 20)
>       - **Text** ("Notifications", 24px, Bold, Plus Jakarta Sans)
>       - **SettingsCard** (bg: #FFFFFF, rounded-3xl [24px], p: 8, shadow-sm)
>         - **SwitchRow** (icon: notifications, title: "Push Notifications", subtitle: "Recevez vos notifications...", switch)
>         - **Divider** (h: 1)
>         - **SwitchRow** (icon: chat, title: "Chat", subtitle: "Messages et conversations", switch)
>         - **Divider** (h: 1)
>         - **SwitchRow** (icon: restaurant, title: "Rappels de repas", subtitle: "Heures de repas planifiés", switch)
>         - **Divider** (h: 1)
>         - **SwitchRow** (icon: person_add, title: "Demandes de conversation", subtitle: "Nouvelles demandes", switch)
>       - **Button** ("Enregistrer", full-width, bg: Teal, white text, rounded-2xl [16px], h: 52px)
