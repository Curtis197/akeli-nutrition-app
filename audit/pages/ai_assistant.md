# Audit: AI Assistant (Overlay Chat)
**Status**: Step 3 — [STITCH] Prompt Generation
**Flutter file**: `lib/features/ai/ai_assistant_overlay.dart`
**FF source**: `flutterflow_application/akeli/lib/a_i_assistant/ai_thread/ai_thread_widget.dart` + `ai_chat/ai_chat_widget.dart`
**Stitch source**: `stitch/ai_assistant/`

---

## Step 1: [BASE] Widget Tree

- **Visibility** (visible: parameter2 boolean — toggled by FAB on home page)
  - **Align** (bottom-right, right: 15, bottom: 120)
    - **FutureBuilder** (ConversationRow by userId)
      - **Container** (w: 275, h: 400, bg: alternate, radius: 15)
        - **Padding** (10/15/10/15)
          - **Column** (mainAxisAlignment: end)
            - **Expanded** → **ListView.builder** (reverse: true, shrinkWrap)
              - Per message: **AiChatWidget** (embedded, messageJSON param)
                - **Conditional**: if role == 'user'
                  - **Align** (right)
                    - Container (maxWidth: 200, bg: #264D96FF (15% blue), radius: 10, padding: 8)
                      - Column
                        - Text ("Moi", bodyMedium Poppins 500w)
                        - Text (message, bodySmall Poppins)
                        - **Row** (justify: end)
                          - Text (relative time, labelSmall Poppins)
                - **Conditional**: if role == 'assistant' && status == 'send'
                  - **Align** (left)
                    - Container (maxWidth: 200, bg: secondaryBackground, radius: 10, padding: 8)
                      - Column
                        - Text ("Assistant", bodyMedium Poppins 500w)
                        - Text (message, bodySmall Poppins)
                        - **Row** (justify: end)
                          - Text (relative time, labelSmall Poppins)
                - **Conditional**: if role == 'assistant' && status == 'pending'
                  - **Align** (left)
                    - Container (maxWidth: 200, bg: secondaryBackground, radius: 10, padding: 8)
                      - Column
                        - Text ("Votre assistant traite votre demande...", bodySmall Poppins 500w)
            - **Input Row**
              - **Expanded** → **TextFormField** (labelText: "Poser une question", labelMedium Poppins, bg: secondaryBackground, radius: 15, border: transparent, focused: primary, maxLines: null, autofocus: true)
              - **Container** (50x50, bg: secondary, radius: 50 (circle))
                - **InkWell** → Icon (send_rounded, 26px, secondaryBackground)
                  - onTap: insert user message → insert pending assistant message → AIassistantCall (with userContext, message, conversationId, listMessages) → update assistant message with reply → clear text field

---

## Step 2: [DESIGN] Baseline Attributes

### Color Tokens (Light Mode)
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#3BB78F` | Focused border on input field |
| secondary | `#FF9F1C` | Send button bg |
| alternate | `#E5E5E5` | AI chat panel bg |
| primaryText | `#2F2F2F` | Body text |
| secondaryText | `#5A5A5A` | — |
| primaryBackground | `#F9F9E8` | — |
| secondaryBackground | `#FFFFFF` | Received message bg, input field bg, send button icon |
| accent1 | `#4D96FF` | Sent message bg (#264D96FF = 15% opacity) |
| error | `#FF6B6B` | Error borders |
| tertiary | `#3F3F44` | Loading spinner |

### Typography
| Style | Font | Size | Weight | Color |
|-------|------|------|--------|-------|
| bodyMedium | Poppins | 14px | 500 | sender labels ("Moi" / "Assistant") |
| bodySmall | Poppins | 12px | 400/500 | message content, pending text |
| labelMedium | Poppins | 14px | 400 | input field label |
| labelSmall | Poppins | 12px | 400 | message timestamps |

### Spacing & Radius
| Token | Value |
|-------|-------|
| sm | 4px |
| md | 8px |
| lg | 15px |
| xl | 24px |

### Widget-Specific Attributes
- **AI Chat Panel**: w: 275, h: 400, bg: #E5E5E5 (alternate), radius: 15px, positioned bottom-right (right: 15, bottom: 120)
  - Inner padding: 10/15/10/15
- **Sent message bubble**: maxWidth: 200, bg: #264D96FF (15% blue), radius: 10px, padding: 8, aligned right
  - Label: "Moi", bodyMedium Poppins 500w
  - Content: bodySmall Poppins
  - Timestamp: labelSmall Poppins, relative format
- **Received message bubble**: maxWidth: 200, bg: #FFFFFF, radius: 10px, padding: 8, aligned left
  - Label: "Assistant", bodyMedium Poppins 500w
  - Content: bodySmall Poppins
  - Timestamp: labelSmall Poppins, relative format
- **Pending message**: maxWidth: 200, bg: #FFFFFF, radius: 10px, padding: 8, aligned left
  - Text: "Votre assistant traite votre demande...", bodySmall Poppins 500w
- **Input field**: labelText: "Poser une question", bg: #FFFFFF, radius: 15px, border: transparent, focused: primary (#3BB78F), maxLines: null (auto-expand), autofocus: true
- **Send button**: 50x50, circle, bg: #FF9F1C (secondary), icon: send_rounded 26px #FFFFFF
- **ListView**: reverse: true (newest at bottom)

---

## Step 3: [STITCH] Prompt

> **Objective**: Transform the AI Assistant overlay into a high-fidelity, modern "Digital Editorial" AI chat experience that feels like a premium nutrition assistant.
>
> **Aesthetic Goals**:
> - **Premium Smoothness**: Use `rounded-3xl` (24px radius) for the panel and message bubbles. Replace the current 10px/15px radii.
> - **Modern Typography**: Implement `Plus Jakarta Sans` for headers and `Inter` for messages. Create clear visual distinction between user and AI messages.
> - **Visual Air**: Increase padding inside the panel (20px). Use generous padding inside bubbles (16px). Add subtle dividers between the message list and input area.
> - **Interactive Cues**: Apply subtle shadows on the panel (`shadow-xl`) and message bubbles. Use the brand Teal (#3BB78F) for user messages instead of the current blue tint. Replace the orange send button with a Teal one.
> - **Panel Design**: Make the floating panel feel like a glassmorphic overlay — frosted background with smooth edges.
>
> **Functional Structure to Preserve**:
> - **Floating panel**: Positioned bottom-right, toggled by FAB on home page
> - **Message list**: Reverse ListView with user and AI messages
> - **User messages**: Right-aligned bubbles with "Moi" label, content, timestamp
> - **AI messages**: Left-aligned bubbles with "Assistant" label, content, timestamp
> - **Pending state**: "Votre assistant traite votre demande..." while waiting for response
> - **Input area**: Auto-expanding text field + send button
> - **API call**: AIassistantCall with userContext, message, conversationId, listMessages
>
> **Base Widget Tree to Transform**:
> - **OverlayPanel** (positioned bottom-right, w: 320, h: 480, frosted glass bg, rounded-3xl [24px], shadow-xl, border: 1px white/20)
>   - **Column** (flex: 1)
>     - **PanelHeader** (px: 20, py: 16, border-bottom: 1px white/10)
>       - **Row** (items-center, gap: 12)
>         - **IconBadge** (32x32, circle, bg: Teal/15, icon: auto_awesome, Teal)
>         - **Column**
>           - **Text** ("Assistant Akeli", 15px, Bold, Plus Jakarta Sans)
>           - **Text** ("En ligne", 12px, Inter, primary)
>     - **Expanded** → **ListView** (reverse: true, px: 16, py: 12)
>       - **MessageBubble** (user, aligned right, mb: 8)
>         - **Container** (maxWidth: 240, bg: Teal, rounded-t-3xl [24px] rounded-bl-3xl [24px] rounded-br-md [8px], p: 16)
>           - **Text** (message content, 14px, Inter, white, lineHeight: 1.5)
>           - **SizedBox** (h: 4)
>           - **Text** (time, 11px, Inter, white/60, right-aligned)
>       - **MessageBubble** (ai, aligned left, mb: 8)
>         - **Container** (maxWidth: 240, bg: white/90, rounded-t-3xl [24px] rounded-br-3xl [24px] rounded-bl-md [8px], p: 16, shadow-xs)
>           - **Row** (items-center, gap: 6, mb: 4)
>             - **Icon** (auto_awesome, 14px, Teal)
>             - **Text** ("Assistant", 12px, Bold, Inter, Teal)
>           - **Text** (message content, 14px, Inter, primaryText, lineHeight: 1.5)
>           - **SizedBox** (h: 4)
>           - **Text** (time, 11px, Inter, muted, right-aligned)
>       - **PendingBubble** (aligned left, mb: 8)
>         - **Container** (bg: white/90, rounded-2xl [16px], p: 16, shadow-xs)
>           - **Row** (items-center, gap: 8)
>             - **DotAnimation** (3 dots, Teal, bouncing)
>             - **Text** ("Réflexion en cours...", 13px, Inter, muted)
>     - **InputBar** (px: 16, py: 12, border-top: 1px white/10)
>       - **Row** (items-end, gap: 8)
>         - **TextField** (flex: 1, bg: white/80, rounded-2xl [16px], p: 14, 14px Inter, maxLines: 4, minLines: 1, "Poser une question")
>         - **IconButton** (send, circle, bg: Teal, icon: send_rounded white, 40px, shadow-sm)
>
> **Meal Type Color System**:
> | Type | Badge Color | Text Color | Icon |
> |------|------------|------------|------|
> | Petit-Déjeuner | #FFF3E0 | #FF9F1C | wb_sunny_rounded |
> | Déjeuner | #E8F5E9 | #3BB78F | lunch_dining_rounded |
> | Collation | #E3F2FD | #4D96FF | cookie_rounded |
> | Dîner | #E0F2F1 | #006A63 | dinner_dining_rounded |
