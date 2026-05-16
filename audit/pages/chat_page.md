# Audit: Chat Page
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/chat/chat_page.dart`
**FF source**: `flutterflow_application/akeli/lib/chat_page/chat_page_widget.dart`
**Stitch source**: `stitch/chat_page/`

---

## Step 1: [BASE] Widget Tree

- **StreamBuilder** (ChatMessageRow — loading: SpinKitDoubleBounce centered)
  - **GestureDetector** (dismiss keyboard)
    - **Scaffold** (bg: primaryBackground)
      - **AppBar** (bg: primary, elevation: 2, centerTitle: true, no leading)
        - **leading**: InkWell → Icon (arrow_back_ios_new, 32px, secondaryBackground) → safePop
        - **title**: Column
          - **Conditional**: if conversation.grouped == false (private chat)
            - **FutureBuilder** (UsersRow by destinedUserId)
              - **InkWell** → navigates to UserprofileWidget
                - **Row**
                  - Container (30x30, circle, Image.network — profile or default)
                  - Text (userName, titleMedium Poppins)
          - **Conditional**: if conversation.grouped == true (group chat)
            - **FutureBuilder** (ConversationGroupRow)
              - **InkWell** → navigates to GroupPageWidget
                - **Row**
                  - Container (30x30, circle, Image.network — group image or default)
                  - Text (groupName, titleMedium Poppins)
      - **SafeArea**
        - **Column**
          - **Expanded** → **RefreshIndicator** (pull-to-refresh loads older messages)
            - **ListView.builder** (reverse: true, shrinkWrap)
              - Per message: **ChatWidget** (embedded component, message param)
                - **Conditional**: if message.userId == currentUser.id (sent message)
                  - **Align** (right)
                    - Container (maxWidth: 200, bg: #264D96FF (26 = 15% opacity blue), radius: 10, padding: 8)
                      - Column (crossAxisAlignment: start)
                        - Text ("Moi", bodyMedium Poppins 500w)
                        - Text (message content, bodySmall Poppins)
                        - **Row** (justify: end, gap: 5)
                          - Icon (check_rounded, 16px, primary) — if received && readBy.length == 1
                          - Icon (done_all_rounded, 16px, primary) — if readBy.length >= 2
                          - Text (relative time, labelSmall Poppins)
                - **Conditional**: if message.userId != currentUser.id (received message)
                  - **Align** (left)
                    - Container (maxWidth: 200, bg: secondaryBackground, radius: 10, padding: 8)
                      - Column (crossAxisAlignment: start)
                        - **InkWell** → navigates to UserprofileWidget
                          - Text (sender userName, bodyMedium Poppins 500w)
                        - Text (message content, bodySmall Poppins)
                        - **Row** (justify: end, gap: 5)
                          - Icon (check_rounded, 16px, primary) — if received && readBy.length == 1
                          - Icon (done_all_rounded, 16px, primary) — if readBy.length >= 2
                          - Text (relative time, labelSmall Poppins)
          - **Message Input Bar** (bg: secondaryBackground, padding: 15)
            - **Row** (gap: 25)
              - **Expanded** → **TextFormField** (bg: alternate, radius: 8, border: 1px secondaryBackground, focused: transparent)
                - hintText: empty
                - labelStyle: labelMedium Poppins
              - **FlutterFlowIconButton** (send_rounded, 24px, white, bg: primary, borderRadius: 50, buttonSize: 40)
                - onTap: prepend message to local list → sendAMessageCall → update ChatConversation last_message_time/content → send notification → clear text field

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens (Light Mode)
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | AppBar bg, send button bg, read check icons |
| primaryText | `#2F2F2F` | Body text, arrow_forward_ios |
| secondaryText | `#5A5A5A` | — |
| primaryBackground | `#F9F9E8` | Scaffold bg |
| secondaryBackground | `#FFFFFF` | AppBar icon bg, received message bg, input bar bg |
| alternate | `#E5E5E5` | Input field bg |
| accent1 | `#4D96FF` | Sent message bg (#264D96FF = 15% opacity) |
| error | `#FF6B6B` | Error borders |
| info | `#FFFFFF` | Send icon color |
| tertiary | `#3F3F44` | Loading spinner |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| titleMedium | Poppins | 18px | 400 | primaryText (AppBar name) |
| bodyMedium | Poppins | 14px | 400/500 | sender name ("Moi" / userName) |
| bodySmall | Poppins | 12px | 400 | message content |
| labelMedium | Poppins | 14px | 400 | input field hints |
| labelSmall | Poppins | 12px | 400 | message timestamp |

### Spacing & Radius
| Token | Value |
|-------|-------|
| sm | 4px |
| md | 8px |
| lg | 10px |
| xl | 24px |

### Widget-Specific Attributes
- **AppBar**: bg: #3BB78F (primary), elevation: 2, centerTitle: true
- **Back icon**: arrow_back_ios_new, 32px, #FFFFFF (secondaryBackground)
- **AppBar avatar**: 30x30, circle, Image.network
- **AppBar name**: titleMedium Poppins, white (on primary bg)
- **Sent message bubble**: maxWidth: 200, bg: #264D96FF (15% blue), radius: 10px, padding: 8, aligned right
  - Label: "Moi", bodyMedium Poppins 500w
  - Content: bodySmall Poppins
  - Read status: check_rounded (16px, primary) or done_all_rounded (16px, primary)
  - Timestamp: labelSmall Poppins, relative format
- **Received message bubble**: maxWidth: 200, bg: #FFFFFF, radius: 10px, padding: 8, aligned left
  - Sender name: bodyMedium Poppins 500w, clickable → UserProfile
  - Content: bodySmall Poppins
  - Read status: same as sent
  - Timestamp: labelSmall Poppins, relative format
- **Message input bar**: bg: #FFFFFF, padding: 15
- **Input field**: bg: #E5E5E5 (alternate), radius: 8px, border: 1px #FFFFFF, focused: transparent
- **Send button**: send_rounded, 24px white, bg: #3BB78F, borderRadius: 50 (circle), buttonSize: 40
- **ListView**: reverse: true (newest at bottom), pull-to-refresh loads older messages (limit: 50)
- **Gap between input field and send button**: 25px

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the Chat Page into a high-fidelity, modern "Digital Editorial" messaging experience that feels like a premium chat application.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for message bubbles. Replace the current 10px/8px radii. Create asymmetric bubble shapes (like iMessage/WhatsApp).
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for messages. Create clear visual distinction between sent and received messages.
> - **Visual Air**: Increase padding between messages (8px vertical). Use generous padding inside bubbles (16px). Separate the input bar from messages with a subtle divider.
> - **Interactive Cues**: Apply subtle shadows on message bubbles. Use the brand Teal (#3BB78F) for sent messages instead of the current blue tint. Add smooth scroll-to-bottom behavior.
> - **Input Bar**: Make the input bar feel like a modern chat input — rounded pill shape with a floating send button.
>
> **Functional Structure to Preserve**:
> - **Header**: Back button + contact/group avatar + name (clickable → profile/group page)
> - **Message list**: Reverse ListView with pull-to-refresh for older messages
> - **Sent messages**: Right-aligned bubbles with "Moi" label, content, read receipts (check/double-check), timestamp
> - **Received messages**: Left-aligned bubbles with sender name (clickable → profile), content, read receipts, timestamp
> - **Input bar**: Text field + send button
> - **Real-time updates**: StreamBuilder for live message updates
>
> **Base Widget Tree to Transform**:
> - **Scaffold** (bg: cream #F9F9E8)
>   - **AppBar** (bg: #FFFFFF, elevation: 0, border-bottom: 1px cream)
>     - **BackButton** (circle, bg: cream, icon: arrow_back_ios_new, 20px)
>     - **ContactInfo** (center, flex, items-center, gap: 12)
>       - **Avatar** (36x36, circle, border: 2px cream)
>       - **Column**
>         - **Text** (contactName, 16px, Bold, Plus Jakarta Sans)
>         - **Text** ("En ligne", 12px, Inter, primary)
>   - **Column**
>     - **Expanded** → **ListView** (reverse: true, px: 16, py: 8)
>       - **MessageBubble** (sent, aligned right, mb: 8)
>         - **Container** (maxWidth: 280, bg: Teal, rounded-t-3xl [24px] rounded-bl-3xl [24px] rounded-br-md [8px], p: 16)
>           - **Text** (message content, 15px, Inter, white, lineHeight: 1.5)
>           - **SizedBox** (h: 4)
>           - **Row** (justify: end, gap: 4)
>             - **Text** (time, 11px, Inter, white/70)
>             - **Icon** (done_all_rounded, 14px, white/70)
>       - **MessageBubble** (received, aligned left, mb: 8)
>         - **Container** (maxWidth: 280, bg: #FFFFFF, rounded-t-3xl [24px] rounded-br-3xl [24px] rounded-bl-md [8px], p: 16, shadow-xs)
>           - **Text** (sender name, 12px, Bold, Inter, muted, mb: 4)
>           - **Text** (message content, 15px, Inter, primaryText, lineHeight: 1.5)
>           - **SizedBox** (h: 4)
>           - **Row** (justify: end, gap: 4)
>             - **Text** (time, 11px, Inter, muted)
>     - **InputBar** (bg: #FFFFFF, border-top: 1px cream, px: 16, py: 12)
>       - **Row** (items-end, gap: 12)
>         - **TextField** (flex: 1, bg: cream, rounded-2xl [16px], p: 16, 15px Inter, maxLines: 4, minLines: 1)
>         - **IconButton** (send, circle, bg: Teal, icon: send_rounded white, 44px, shadow-sm)
>
> **Meal Type Color System**:
> | Type | Badge Color | Text Color | Icon |
> |------|------------|------------|------|
> | Petit-Déjeuner | #FFF3E0 | #FF9F1C | wb_sunny_rounded |
> | Déjeuner | #E8F5E9 | #3BB78F | lunch_dining_rounded |
> | Collation | #E3F2FD | #4D96FF | cookie_rounded |
> | Dîner | #E0F2F1 | #006A63 | dinner_dining_rounded |
