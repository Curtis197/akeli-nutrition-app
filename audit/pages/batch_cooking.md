# Audit: Batch Cooking Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/meal_planner/batch_cooking_page.dart`
**Stitch source**: `stitch/batch_cooking/`

---

## Step 1: [BASE] Widget Tree

- **Scaffold** (bg: AkeliColors.background)
  - **AppBar** (bg: transparent, elevation: 0)
    - leading: BackButton
    - title: Text('Batch Cooking', inherited textTheme)
  - **FloatingActionButton** (bg: AkeliColors.primary)
    - Icon(add, white)
    - onPressed: _showCreateSessionSheet(context)
  - **body**: **sessionsAsync.when** (cookingSessionsProvider)
    - loading: Center → CircularProgressIndicator
    - error: Center → Text('Erreur: $e', bodyMedium, AkeliColors.error)
    - data:
      - empty → **_EmptyState**
      - non-empty → **ListView.separated** (padding: fromLTRB(md, md, md, 100), separator: SizedBox(h: sm))
        - **_CookingSessionCard** per session

### _EmptyState
- Center → Padding(all: xl [32px])
  - Column(mainSize: min)
    - Text('🍲', fontSize: 56)
    - SizedBox(h: md [16px])
    - Text('Aucune session cette semaine', titleMedium, bold, center)
    - SizedBox(h: sm [8px])
    - Text('Appuyez sur + pour créer votre première session batch.', bodyMedium, outline, center)

### _CookingSessionCard
- Container (bg: white, radius: AkeliRadius.card [24px], padding: all md [16px], shadow: black @ 4% blur 8 offset(0,2))
  - Row
    - **Thumbnail** — Container (56×56, radius: AkeliRadius.sm [8px], bg: primary @ 8%)
      - recipeThumbnail set: ClipRRect(radius: sm [8px]) → Image.network(cover)
      - recipeThumbnail null: Center → Text('🍲', fontSize: 28)
    - SizedBox(w: md [16px])
    - **Expanded** → Column(crossAxis: start)
      - Text(recipeTitle ?? 'Recette', titleSmall, w700)
      - SizedBox(h: 4)
      - Text('{day} {month}. · {totalPortions} portions', bodySmall, outline)
      - SizedBox(h: 8)
      - Row
        - **Expanded** → ClipRRect(radius: 4) → LinearProgressIndicator
          - value: portionsUsed / totalPortions (0.0 if totalPortions == 0)
          - backgroundColor: surfaceContainerHighest
          - valueColor: primary (hasAvailablePortions == true) / outline (exhausted)
          - minHeight: 6
        - SizedBox(w: sm [8px])
        - Text('{portionsUsed}/{totalPortions}', labelSmall, outline, w600)

### _showCreateSessionSheet (Modal Bottom Sheet)
- showModalBottomSheet (isScrollControlled: true, bg: AkeliColors.background, top radius: 20)
  - Padding(fromLTRB: lg, lg, lg, viewInsets.bottom + lg)
    - Column(mainSize: min, crossAxis: start)
      - Text('Nouvelle session', titleLarge, bold)
      - SizedBox(h: md [16px])
      - **Info Banner** — Container(padding: all md, bg: secondaryContainer @ 40%, radius: md [12px])
        - Row
          - Icon(info_outline, primary, 18px)
          - SizedBox(w: sm [8px])
          - Expanded → Text('La création de sessions batch sera disponible prochainement…', bodySmall, onSurfaceVariant)
      - SizedBox(h: md [16px])
      - SizedBox(w: infinity) → **ElevatedButton** (onPressed: null — disabled)
        - style: bg: primary, disabledBg: surfaceContainerHighest, padding: v md, radius: md [12px]
        - child: Text('Bientôt disponible', labelLarge, outline, w700)

### CookingSession Model Fields (relevant to UI)
| Field | Type | Usage |
|-------|------|-------|
| recipeTitle | String? | Card title (fallback: 'Recette') |
| recipeThumbnail | String? | Thumbnail image URL (fallback: 🍲 emoji) |
| plannedDate | DateTime | Formatted as '{day} {abbr-month}.' |
| totalPortions | int | Progress denominator + label |
| portionsUsed | int | Progress numerator + label |
| hasAvailablePortions | bool (getter) | Controls progress bar color |
| portionsAvailable | int (getter) | totalPortions - portionsUsed |

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens
| Token | Value | Usage |
|-------|-------|-------|
| AkeliColors.background | (cream) | Scaffold bg, modal sheet bg |
| AkeliColors.primary | `#3BB78F` | FAB bg, progress bar (available), info icon, thumbnail bg tint |
| AkeliColors.outline | (medium grey) | Empty-state body text, card metadata text, progress bar (exhausted), disabled button text |
| AkeliColors.error | (red) | Error state text |
| AkeliColors.secondaryContainer | (light orange) | Info banner bg (@ 40% opacity) |
| AkeliColors.onSurfaceVariant | (medium grey) | Info banner body text |
| AkeliColors.surfaceContainerHighest | (light grey) | Progress bar background, disabled button bg |
| Colors.white | `#FFFFFF` | Card bg, FAB icon |

### Typography
| Style | Usage | Key attributes |
|-------|-------|----------------|
| titleLarge | Modal sheet title ('Nouvelle session') | bold |
| titleMedium | Empty-state headline | bold, center |
| titleSmall | Card recipe title | w700 |
| bodyMedium | Empty-state body text; error text | outline / AkeliColors.error |
| bodySmall | Card metadata row; info banner text | outline / onSurfaceVariant |
| labelSmall | Portions fraction label | outline, w600 |
| labelLarge | Disabled button text | outline, w700 |

### Spacing & Radius Tokens
| Token | Value | Usage |
|-------|-------|-------|
| AkeliSpacing.sm | 8px | List separator, icon-text gap in banner, progress bar right gap |
| AkeliSpacing.md | 16px | List padding, card padding, modal padding, thumbnail gap, banner padding |
| AkeliSpacing.lg | 24px | Modal side padding |
| AkeliSpacing.xl | 32px | Empty-state outer padding |
| AkeliRadius.sm | 8px | Thumbnail container & clip radius |
| AkeliRadius.md | 12px | Info banner radius, bottom sheet button radius |
| AkeliRadius.card | 24px | Session card radius |
| `4` (literal) | 4px | Progress bar clip radius |
| `20` (literal) | 20px | Modal bottom sheet top radius |

### Widget-Specific Attributes
- **AppBar**: transparent bg, elevation 0, default BackButton, title inherits theme
- **FAB**: bg: primary, icon: add (white), no label, bottom-right
- **Thumbnail container**: 56×56, radius: 8px, bg: primary @ 8%; image clips to same radius
- **Card**: bg: white, radius: 24px, padding: 16px, shadow: black @ 4% blur 8 offset(0,2)
- **Progress bar**: minHeight: 6px, clip radius: 4px, color switches on `hasAvailablePortions`
- **List**: padding bottom: 100px (clears FAB + bottom nav bar)
- **Modal**: isScrollControlled: true (respects keyboard), padding adjusts for viewInsets.bottom

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Batch Cooking page into a high-fidelity, modern "Digital Editorial" experience while preserving the existing functional hierarchy and session-tracking identity.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px) for all cards and containers. Replace the current 8px/12px radii.
> - **Modern Typography**: `Plus Jakarta Sans` for headers and labels, `Inter` for metadata and body. Strong weight contrast (w800 titles vs w400 body).
> - **Visual Air**: Generous padding (24px minimum on cards). Breathing room between the page title and first card. Clear section grouping.
> - **Interactive Cues**: Subtle shadows (`shadow-sm`) on cards. Progress bar styled as a premium pill, teal fill with a muted cream background.
> - **Layered Design**: Cream/off-white page background (#F9F9E8), pure white session cards creating editorial lift.
> - **Empty State**: Full-screen centered illustration-style empty state with emoji hero, headline, and subtle CTA hint.
> - **Modal Sheet**: Frosted glass-style bottom sheet with a clear "coming soon" communication and a styled disabled button.
>
> **Functional Structure to Preserve**:
> - **AppBar**: Back button (left) + page title
> - **FAB**: Bottom-right, primary teal, + icon → opens create-session modal
> - **Session list**: Vertical scrollable list of cooking session cards
> - **Session card**: Thumbnail (image or emoji), recipe name, date + portions metadata, portions progress bar + fraction
> - **Empty state**: Emoji, headline, instructional body text
> - **Create modal**: Title, info banner (coming soon message), disabled submit button
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **AppBar** (bg: transparent, elevation: 0)
>     - **BackButton** (left)
>     - **Text** ("Batch Cooking", 20px, Bold, Plus Jakarta Sans, onSurface)
>   - **FloatingActionButton** (bottom-right, bg: Teal #3BB78F, icon: add, white, rounded-full, shadow-lg)
>   - **body**:
>     - *empty state*: **Center** → **Column** (gap: 16px, items-center)
>       - **Text** ('🍲', 56px)
>       - **Text** ("Aucune session cette semaine", 18px, Bold, Plus Jakarta Sans, center)
>       - **Text** ("Appuyez sur + pour créer votre première session batch.", 14px, Inter, outline, center)
>     - *session list*: **ListView** (gap: 8px, px: 16, pb: 100)
>       - **SessionCard** (bg: #FFFFFF, rounded-3xl [24px], p: 16, shadow-sm)
>         - **Row** (gap: 16px, items-center)
>           - **Thumbnail** (56×56, rounded-xl [12px], bg: Teal @ 8%)
>             - Image or emoji '🍲' (28px, centered)
>           - **Column** (flex: 1, gap: 4px, crossAxis: start)
>             - **Text** (Recipe name, 15px, Bold, Plus Jakarta Sans, onSurface, 1 line)
>             - **Text** ('{day} {month}. · {N} portions', 12px, Inter, muted)
>             - **SizedBox** (h: 8px)
>             - **Row** (gap: 8px, items-center)
>               - **Expanded** → **ProgressBar** (h: 6px, rounded-full, bg: cream, fill: Teal or outline)
>               - **Text** ('{used}/{total}', 11px, Inter, muted, w600)
>   - **Modal Bottom Sheet** (bg: cream, top radius: 20px, isScrollControlled)
>     - **Column** (mainSize: min, crossAxis: start, p: 24)
>       - **Text** ("Nouvelle session", 18px, Bold, Plus Jakarta Sans)
>       - **SizedBox** (h: 16px)
>       - **InfoBanner** (bg: secondaryContainer @ 40%, rounded-xl [12px], p: 16)
>         - **Row** (gap: 8px)
>           - **Icon** (info_outline, Teal, 18px)
>           - **Expanded** → **Text** ("La création de sessions batch sera disponible prochainement…", 12px, Inter, onSurfaceVariant)
>       - **SizedBox** (h: 16px)
>       - **Button** ("Bientôt disponible", full-width, disabled, bg: surfaceContainerHighest, text: outline, rounded-xl [12px], h: 48px)

---

## Step 4: [STITCH] High-Fidelity Widget Tree
*Waiting for Stitch HTML...*

---

## Step 5: [COMPARISON] Delta
| Delta Type | Modification Required |
| :--- | :--- |
| **[LAYOUT]** | *TBD* |
| **[DESIGN]** | *TBD* |

---

## Step 6: [APPROVAL]
- [ ] User approved

---

## Step 7: [VISUAL] Screenshot Analysis & Blueprint
*Waiting for Stitch generation and user approval...*

---

## Step 8: [TRANSCRIPTION] Notes
*Waiting for Stitch generation and user approval...*
