# Audit: Community Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/community/community_page.dart`
**FF source**: `flutterflow_application/akeli/lib/community/community_widget.dart`
**Stitch source**: `stitch/community/`

---

## Step 1: [BASE] Widget Tree

- **FutureBuilder** (UsersRow — loading: SpinKitDoubleBounce centered)
  - **GestureDetector** (dismiss keyboard)
    - **Scaffold** (bg: secondaryBackground)
      - **AppBar** (bg: secondaryBackground, elevation: 2, centerTitle: true, no leading)
        - **title**: Text ("Discussion", headlineMedium Outfit 28px, primary)
      - **SafeArea**
        - **Container** (padding: 20)
          - **Conditional**: if paidPlan → **Expanded**
            - **Column**
              - **TabBar** (center, labelColor: primaryText, unselectedLabelColor: secondaryText, indicator: primary)
                - Tab 1: "Conversation"
                - Tab 2: "Groupe"
              - **TabBarView** (2 tabs, Expanded)
                - **Tab 1: Conversations**
                  - **SingleChildScrollView**
                    - **Column**
                      - **Search Bar** (padding: 30/10/30/0)
                        - **TextFormField** (filled, bg: secondaryBackground, radius: 50, suffixIcon: search_rounded)
                          - hintText: "Chercher une conversation"
                          - onFieldSubmitted: SupabaseGroup.searchAPrivateConversationCall → sets inSearch = true
                      - **Conversation Demands Section** (conditional: if demands not empty)
                        - Container (bg: secondaryBackground, radius: 8, padding: 12)
                        - **Text** ("Demandes", titleLarge Outfit)
                        - **ListView** (shrinkWrap)
                          - Per demand:
                            - **Row**
                              - ClipRRect avatar (50x50, circle, Image.network)
                              - Column (userName: bodyLarge, description: bodySmall)
                              - Icon (delete, 24px, secondary) → delete demand
                              - Icon (add_circle_outlined, 24px, tertiary) → accept demand → create/find conversation → navigate to ChatPage
                      - **StreamBuilder** (ConversationParticipantRow — if inSearch == false)
                        - **ListView.builder** (shrinkWrap)
                          - Per participant:
                            - **FutureBuilder** (ChatConversationRow where grouped == false)
                              - **ChatUserWidget** (embedded component, chatConv + currentUser params)
                      - **Search Results** (if inSearch == true)
                        - **ListView.builder**
                          - Per search result:
                            - **FutureBuilder** (ChatConversationRow)
                              - **ChatUserWidget** (embedded)
                - **Tab 2: Groups**
                  - **SingleChildScrollView**
                    - **Column**
                      - **Search Bar** (padding: 0/20/0/0)
                        - **TextFormField** (w: 300, filled, bg: secondaryBackground, radius: 50, suffixIcon: search_outlined)
                          - hintText: "Chercher un groupe"
                          - onFieldSubmitted: if participation → searchAGroupByNameCall (userId + name), else → searchAGroupCall (name) → sets inSearch = true
                      - **Radio Filter** (padding: 0/15)
                        - **FlutterFlowRadioButton** (options: "Tous" / "Participant", horizontal, primary radio, labelMedium Poppins)
                          - onChanged: toggles participation boolean, resets inSearch = false
                      - **Create Group Button** (padding: 0/15)
                        - **FFButtonWidget** ("Créer un groupe", primary bg, white text, radius: 8, h: 40)
                          - onTap → showModalBottomSheet (h: 450, GroupCreationWidget)
                      - **All Groups List** (if participation == false && inSearch == false)
                        - **FutureBuilder** (ChatConversationRow where grouped == true, order by last_message_time)
                          - **ListView.builder**
                            - Per group:
                              - **FutureBuilder** (ConversationGroupRow by conversation_id)
                                - Container (bg: secondaryBackground, radius: 10, padding: 10)
                                - **InkWell** (onTap → checkIfAUserIsInAGroupCall → if member: ChatPage, else: GroupPage)
                                  - **Row** (spaceBetween)
                                    - ClipRRect avatar (50x50, circle, Image.network — group image or default)
                                    - Column (group name: labelLarge Poppins, description: labelSmall Poppins, w: 200)
                                    - Icon (arrow_forward_ios, 24px, primaryText) → navigate to ChatPage
                      - **Search Results** (if participation == false && inSearch == true)
                        - **ListView.builder** (filtered groups from searchAGroupCall)
                          - Same group card structure
                      - **My Groups List** (if participation == true && inSearch == false)
                        - **FutureBuilder** (groups where user is participant)
                          - **ListView.builder**
                            - Same group card structure
                      - **My Groups Search Results** (if participation == true && inSearch == true)
                        - **ListView.builder** (filtered groups from searchAGroupByNameCall)
                          - Same group card structure

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens (Light Mode)
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | AppBar title, TabBar indicator, radio buttons, buttons |
| secondary | `#FF9F1C` | Delete icon in demands |
| tertiary | `#3F3F44` | Loading spinner, add_circle icon in demands |
| alternate | `#E5E5E5` | — |
| primaryText | `#2F2F2F` | TabBar active label, body text, arrow_forward_ios |
| secondaryText | `#5A5A5A` | TabBar inactive label, radio inactive, user description |
| primaryBackground | `#F9F9E8` | — |
| secondaryBackground | `#FFFFFF` | Scaffold bg, AppBar bg, search field bg, card bg, demands card bg |
| accent1 | `#4D96FF` | — |
| accent2 | `#FF6B6B` | Error borders |
| info | `#FFFFFF` | Button text |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| headlineMedium | Outfit | 28px | 500 | primary |
| titleLarge | Outfit | 22px | 500 | primaryText |
| titleMedium | Poppins | 18px | 400 | primaryText / secondaryText |
| titleSmall | Poppins | 16px | 500 | white (on buttons) |
| labelLarge | Poppins | 16px | 400 | secondaryText (group names) |
| labelMedium | Poppins | 14px | 400 | secondaryText (radio, search hints) |
| labelSmall | Poppins | 12px | 400 | group descriptions |
| bodyLarge | Poppins | 16px | 400 | primaryText (user names) |
| bodyMedium | Poppins | 14px | 400 | search field text |
| bodySmall | Poppins | 12px | 400 | user descriptions |

### Spacing & Radius
| Token | Value |
|-------|-------|
| sm | 4px |
| md | 8px |
| lg | 10px |
| xl | 24px |
| pill | 50px |

### Widget-Specific Attributes
- **AppBar**: bg: #FFFFFF, elevation: 2, centerTitle: true, no leading
- **Title**: "Discussion", headlineMedium Outfit 28px, primary (#3BB78F)
- **TabBar**: labelColor: primaryText, unselectedLabelColor: secondaryText, indicator: primary (#3BB78F)
- **Search fields**: filled, bg: #FFFFFF, radius: 50 (pill), suffixIcon: search_rounded/search_outlined
  - Conversation search: padding: 30/10/30/0
  - Group search: w: 300, padding: 0/20/0/0
- **Demands card**: bg: #FFFFFF, radius: 8px, padding: 12
  - Avatar: 50x50, ClipRRect radius: 50 (circle)
  - User name: bodyLarge Poppins
  - User description: bodySmall Poppins
  - Delete icon: 24px, secondary (#FF9F1C)
  - Add icon: add_circle_outlined, 24px, tertiary (#3F3F44)
- **Group card**: bg: #FFFFFF, radius: 10px, padding: 10
  - Avatar: 50x50, ClipRRect radius: 50 (circle)
  - Group name: labelLarge Poppins
  - Group description: labelSmall Poppins, w: 200
  - Arrow: arrow_forward_ios, 24px, primaryText
- **Radio filter**: horizontal, options: "Tous" / "Participant", primary radio, optionHeight: 32
- **"Créer un groupe" button**: h: 40, bg: #3BB78F, white text titleSmall Poppins, radius: 8px, padding: 16/0
- **Bottom sheets**: h: 450, transparent bg, isScrollControlled: true, no drag
- **Main container padding**: 20px all sides

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Community page into a high-fidelity, modern "Digital Editorial" messaging and group experience that feels like a premium social platform.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for all primary containers and cards. Replace the current 8px/10px/50px radii.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for body text. Create clear hierarchy between conversation/group names and their previews.
> - **Visual Air**: Increase white space between list items (12px minimum). Use generous padding (20px minimum on cards). Separate the search bar from the list with clear visual breathing room.
> - **Interactive Cues**: Apply subtle shadows (`shadow-sm`) on conversation/group cards. Use the brand Teal (#3BB78F) as the primary accent consistently. Add online status indicators on avatars.
> - **Search Experience**: Make the search bar integrated into the page header area — clean, pill-shaped, with subtle background.
>
> **Functional Structure to Preserve**:
> - **Header**: "Discussion" title, centered
> - **TabBar**: "Conversation" and "Groupe" tabs
> - **Conversation tab**: Search bar, pending demands section (with accept/reject), stream of active conversations (ChatUserWidget list), search results
> - **Group tab**: Search bar, radio filter (Tous/Participant), "Créer un groupe" button, group list with avatar + name + description + arrow, search results
> - **Group card logic**: If user is member → navigate to ChatPage, else → navigate to GroupPage (join page)
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **AppBar** (bg: transparent/white, elevation: 0)
>     - **Text** ("Discussion", 28px, Bold, Plus Jakarta Sans, primary Teal, center)
>   - **Column** (px: 16)
>     - **TabBar** (borderless, indicator: rounded pill bg: primary/15, label: primary, unselectedLabel: muted, 14px Inter)
>       - **Tab** ("Conversations", 14px Inter)
>       - **Tab** ("Groupes", 14px Inter)
>     - **TabBarView** (flex: 1)
>       - **ConversationsTab**
>         - **Column** (spacing: 16)
>           - **SearchBar** (bg: #FFFFFF, rounded-2xl [16px], p: 4, shadow-sm)
>             - **Row** (items-center, gap: 8)
>               - **Icon** (search, 20px, muted, pl: 16)
>               - **TextField** (flex: 1, bg: transparent, 15px Inter, "Chercher une conversation")
>           - **DemandsCard** (conditional, bg: #FFFFFF, rounded-3xl [24px], p: 20, shadow-sm)
>             - **HeaderRow** (flex, justify-between, items-center)
>               - **Text** ("Demandes", 18px, Bold, Plus Jakarta Sans)
>               - **Badge** (count, pill, bg: secondary, text: white, 12px)
>             - **SizedBox** (h: 12)
>             - **ListView** (spacing: 12)
>               - **DemandRow** (flex, items-center, gap: 12)
>                 - **Avatar** (48x48, circle, with online dot)
>                 - **Column** (flex: 1)
>                   - **Text** (userName, 15px, Bold, Inter)
>                   - **Text** (description, 13px, Inter, muted)
>                 - **IconButton** (close, 20px, muted)
>                 - **IconButton** (add, 20px, primary, circle, bg: primary/10)
>           - **ConversationList** (flex: 1)
>             - **ConversationItem** (bg: #FFFFFF, rounded-3xl [24px], p: 16, shadow-xs)
>               - **Row** (items-center, gap: 12)
>                 - **Avatar** (48x48, circle, with online dot)
>                 - **Column** (flex: 1)
>                   - **Row** (justify-between)
>                     - **Text** (userName, 15px, Bold, Inter)
>                     - **Text** (timeAgo, 12px, Inter, muted)
>                   - **SizedBox** (h: 4)
>                   - **Text** (lastMessage, 13px, Inter, muted, 1 line overflow)
>                 - **UnreadBadge** (conditional, circle, bg: primary, white text, 20px)
>       - **GroupsTab**
>         - **Column** (spacing: 16)
>           - **SearchBar** (bg: #FFFFFF, rounded-2xl [16px], p: 4, shadow-sm)
>             - **Row** (items-center, gap: 8)
>               - **Icon** (search, 20px, muted, pl: 16)
>               - **TextField** (flex: 1, bg: transparent, 15px Inter, "Chercher un groupe")
>           - **FilterRow** (flex, items-center, gap: 12)
>             - **Chip** ("Tous", 13px Inter, active: primary bg + white text, inactive: cream bg + primaryText, rounded-full, px: 16, py: 8)
>             - **Chip** ("Participant", 13px Inter, same style)
>             - **Spacer**
>             - **Button** ("Créer", small, bg: Teal, white text, rounded-xl [12px], px: 16, py: 8)
>           - **GroupList** (flex: 1, spacing: 12)
>             - **GroupItem** (bg: #FFFFFF, rounded-3xl [24px], p: 16, shadow-xs)
>               - **Row** (items-center, gap: 12)
>                 - **GroupAvatar** (48x48, circle, bg: cream, icon: group, primary)
>                 - **Column** (flex: 1)
>                   - **Text** (groupName, 15px, Bold, Inter)
>                   - **Text** (groupDescription, 13px, Inter, muted, 1 line overflow)
>                 - **Icon** (arrow_forward_ios, 20px, muted)
>
> **Meal Type Color System**:
> | Type | Badge Color | Text Color | Icon |
> |------|------------|------------|------|
> | Petit-Déjeuner | #FFF3E0 | #FF9F1C | wb_sunny_rounded |
> | Déjeuner | #E8F5E9 | #3BB78F | lunch_dining_rounded |
> | Collation | #E3F2FD | #4D96FF | cookie_rounded |
> | Dîner | #E0F2F1 | #006A63 | dinner_dining_rounded |
