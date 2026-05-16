# Audit: User Profile Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/profile/user_profile_page.dart`
**FF source**: `flutterflow_application/akeli/lib/userprofile/userprofile_widget.dart`
**Stitch source**: `stitch/profile/`

---

## Step 1: [BASE] Widget Tree

- **Scaffold** (bg: primaryBackground, top padding: 40)
  - **Container** (full size)
    - **Stack** (alignment: top-center)
      - **Column**
        - **Row** (empty — placeholder)
        - **Container** (150x150, circle, bg: primaryBackground, border: 2px secondary)
          - **Visibility** (if no profilImageUrl)
            - ClipRRect (radius: 100, Image.network default)
        - **Conditional**: if userName exists
          - Text (userName, headlineSmall Outfit)
      - **Align** (center)
        - **SingleChildScrollView** (padding-top: 250)
          - **Container** (full width, h: 800, bg: secondaryBackground, shadow: blur 4, offset 0,-2, radius: topLeft 16, topRight 16)
            - **Padding** (top: 12)
              - **Column** (crossAxisAlignment: start)
                - **Conditional**: if viewing other user (not self)
                  - **Row** (padding: 15/0)
                    - **Expanded**
                      - **FutureBuilder** (searchAConversationCall API)
                        - **FutureBuilder** (ChatConversationRow by API conversationId)
                          - **Conditional**: if not found && no demand && user is public
                            - FFButtonWidget ("Ajouter", h: 30, primary bg, white text, radius: 8, icon: add 15px)
                              - onTap: insert ConversationDemand → conversationRequestCall
                          - **Conditional**: if found (conversation exists)
                            - FFButtonWidget ("Ecrire", h: 30, transparent bg, primary text, primary border, radius: 8, icon: send_rounded 15px) → navigate to ChatPage
                            - FFButtonWidget ("Quitter la Conversation", h: 30, secondary bg, white text, radius: 8) → delete messages, participants, conversation
                    - **Conditional**: if demand exists
                      - Container (radius: 8, border: tertiary)
                        - Padding (8/5)
                          - Row
                            - Text ("demande envoyée", labelSmall, tertiary)
                            - Icon (check_sharp, 18px, tertiary)
                      - FFButtonWidget ("Annuler", h: 30, transparent bg, primary text, primary border, radius: 8) → delete demand
                - **TabBar** (isScrollable: true, indicator: primary)
                  - Tab 1: "Recette"
                  - Tab 2: "Abonné(e)s"
                  - Tab 3: "Abonnements"
                - **TabBarView** (3 tabs, h: 500)
                  - **Tab 1: Recipes**
                    - **FutureBuilder** (ReceipeRow by userId)
                      - **ListView.builder**
                        - Per recipe: **RecipeReviewWidget** (embedded)
                  - **Tab 2: Followers**
                    - **FutureBuilder** (FollowersRow by userId)
                      - **ListView.separated** (separator: 10px)
                        - Per follower:
                          - **FutureBuilder** (UsersRow by followerId)
                            - Container (bg: secondaryBackground, radius: 8, border: 1px alternate, padding: 10)
                            - **Row**
                              - ClipRRect avatar (50x50, circle, Image.network)
                              - Column (userName: bodyLarge, description: bodySmall, padding: 10)
                              - Icon (delete, 24px, secondary) → remove follower
                  - **Tab 3: Following**
                    - **FutureBuilder** (FollowersRow where followingId == userId)
                      - **ListView.separated** (separator: 10px)
                        - Per following:
                          - **FutureBuilder** (UsersRow by userId)
                            - Container (bg: secondaryBackground, radius: 8, border: 1px alternate, padding: 10)
                            - **Row**
                              - ClipRRect avatar (50x50, circle, Image.network)
                              - Column (userName: bodyLarge, description: bodySmall, padding: 10)
                              - Icon (delete, 24px, secondary) → unfollow

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens (Light Mode)
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | TabBar indicator, "Ajouter" button, "Ecrire" text/border, "Annuler" text/border |
| secondary | `#FF9F1C` | Profile avatar border, "Quitter la Conversation" button, delete icons |
| tertiary | `#3F3F44` | "demande envoyée" text/icon, loading spinner |
| alternate | `#E5E5E5` | Follower/following card borders |
| primaryText | `#2F2F2F` | Body text, user names |
| secondaryText | `#5A5A5A` | User descriptions |
| primaryBackground | `#F9F9E8` | Scaffold bg, avatar bg |
| secondaryBackground | `#FFFFFF` | Card bg, tab content bg, button bg (outlined) |
| info | `#FFFFFF` | Button text |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| headlineSmall | Outfit | 24px | 500 | primaryText (user name) |
| titleMedium | Poppins | 18px | 400 | — |
| labelSmall | Poppins | 12px | 400 | button text, "demande envoyée" |
| labelMedium | Poppins | 14px | 400 | — |
| bodyLarge | Poppins | 16px | 400 | user names in follower list |
| bodyMedium | Poppins | 14px | 400 | — |
| bodySmall | Poppins | 12px | 400 | user descriptions |

### Spacing & Radius
| Token | Value |
|-------|-------|
| sm | 4px |
| md | 8px |
| lg | 16px |
| xl | 24px |

### Widget-Specific Attributes
- **Avatar**: 150x150, circle, bg: #F9F9E8, border: 2px #FF9F1C (secondary)
- **User name**: headlineSmall Outfit 24px 500w, below avatar
- **Card sheet**: full width, h: 800, bg: #FFFFFF, shadow: blur 4, offset (0,-2), topLeft/topRight radius: 16px
  - Top padding: 12px
- **Action buttons**: h: 30, radius: 8px, padding: 10/0
  - "Ajouter": bg: primary, white text, icon: add 15px right-aligned
  - "Ecrire": transparent bg, primary text, primary border, icon: send_rounded 15px right-aligned
  - "Quitter la Conversation": bg: secondary, white text
  - "Annuler": transparent bg, primary text, primary border
- **Demand badge**: radius: 8px, border: 1px tertiary, padding: 8/5
  - Text: "demande envoyée", labelSmall, tertiary
  - Icon: check_sharp, 18px, tertiary
- **TabBar**: isScrollable: true, indicator: primary (#3BB78F)
  - Tabs: "Recette", "Abonné(e)s", "Abonnements"
- **TabBarView**: h: 500
- **Follower/Following card**: bg: #FFFFFF, radius: 8px, border: 1px #E5E5E5, padding: 10
  - Avatar: 50x50, circle
  - User name: bodyLarge Poppins
  - Description: bodySmall Poppins, padding: 10
  - Delete icon: 24px, secondary (#FF9F1C)
- **Separator**: 10px gap between list items

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the User Profile page into a high-fidelity, modern "Digital Editorial" profile experience that feels premium and social.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for all primary containers and cards. Replace the current 8px/16px radii.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text. Create strong visual hierarchy between the profile header and tab content.
> - **Visual Air**: Increase padding inside cards (20px minimum). Use generous spacing between follower/following items (16px).
> - **Interactive Cues**: Apply subtle shadows on cards. Use the brand Teal (#3BB78F) as the primary accent consistently.
> - **Profile Header**: Make the avatar larger (120px) with a gradient border ring. Add a frosted glass overlay effect on the top section.
>
> **Functional Structure to Preserve**:
> - **Profile header**: Large circular avatar + user name
> - **Action buttons** (viewing other users): "Ajouter" (send demand), "Ecrire" (open chat), "Quitter la Conversation" (delete), "Annuler" (cancel demand), "demande envoyée" badge
> - **TabBar**: "Recette", "Abonné(e)s", "Abonnements"
> - **Recipe tab**: List of user's recipes (RecipeReviewWidget)
> - **Followers tab**: List of followers with avatar, name, description, delete action
> - **Following tab**: List of followed users with avatar, name, description, unfollow action
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **Stack**
>     - **ProfileHeader** (h: 280, relative)
>       - **GradientBg** (h: 200, linear-gradient: primary/10 → secondary/10)
>       - **Avatar** (120x120, circle, border: 4px white, shadow-lg, absolute bottom-center)
>       - **BackButton** (absolute top-left, circle, bg: white/80, icon: arrow_back)
>       - **UserName** (absolute, below avatar, 24px Bold, Plus Jakarta Sans, center)
>     - **ActionButtonsRow** (conditional, px: 24, mt: 16, gap: 8)
>       - **Button** ("Ajouter", flex: 1, bg: Teal, white text, rounded-2xl [16px], h: 40px)
>       - **Button** ("Ecrire", flex: 1, outlined Teal, rounded-2xl [16px], h: 40px)
>     - **ContentSheet** (bg: #FFFFFF, rounded-t-3xl [24px], shadow-lg, mt: 8, flex: 1)
>       - **TabBar** (borderless, indicator: rounded pill bg: primary/15, label: primary, unselectedLabel: muted, 14px Inter)
>         - **Tab** ("Recettes", 14px Inter)
>         - **Tab** ("Abonné(e)s", 14px Inter)
>         - **Tab** ("Abonnements", 14px Inter)
>       - **TabBarView** (flex: 1)
>         - **RecipesTab**
>           - **ListView** (spacing: 12, p: 16)
>             - **RecipeCard** (embedded RecipeReviewWidget)
>         - **FollowersTab**
>           - **ListView** (spacing: 12, p: 16)
>             - **UserCard** (bg: cream, rounded-2xl [16px], p: 16)
>               - **Row** (items-center, gap: 12)
>                 - **Avatar** (48x48, circle)
>                 - **Column** (flex: 1)
>                   - **Text** (userName, 15px, Bold, Inter)
>                   - **Text** (description, 13px, Inter, muted)
>                 - **IconButton** (delete, 20px, muted)
>         - **FollowingTab**
>           - Same as FollowersTab
>
> **Meal Type Color System**:
> | Type | Badge Color | Text Color | Icon |
> |------|------------|------------|------|
> | Petit-Déjeuner | #FFF3E0 | #FF9F1C | wb_sunny_rounded |
> | Déjeuner | #E8F5E9 | #3BB78F | lunch_dining_rounded |
> | Collation | #E3F2FD | #4D96FF | cookie_rounded |
> | Dîner | #E0F2F1 | #006A63 | dinner_dining_rounded |
