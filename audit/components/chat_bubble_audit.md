# UI Audit: ChatBubble Component

## 1. Legacy Analysis (`lib/shared/widgets/chat_bubble.dart`)

### Visual Structure
- **Container-based Bubble**: Uses `BoxDecoration` with conditional `color` and `borderRadius`.
- **Alignment**: `Align` widget with `isSent` boolean.
- **Micro-Copy**: Message text, timestamp, and optional `senderName`.
- **Status Indicators**: `isRead` checkmarks.

### Functional Logic
- **Stateless Widget**: Purely presentational.
- **Theming**: Uses `AkeliColors` and `AkeliRadius` (already partially Akeli-fied but lacks the "Editorial" depth).

### Design Gaps (Current vs. Modern)
- **Geometry**: Uses `AkeliRadius.md` (8px). Needs move to `AkeliRadius.lg` (16px) or `xl` (24px) for the "Modern Squircle" look.
- **Glassmorphism**: Currently uses flat colors with low alpha. Needs `BackdropFilter` for glass effect on the surface.
- **Typography**: Uses standard `ThemeText`. Needs explicit `Plus Jakarta Sans` styling.
- **"No-Line" Rule**: Avoid borders; use depth and tonal contrast.

---

## 2. Modernization Prompt for Stitch

**Role**: Expert Flutter UI Designer & Frontend Developer.
**Task**: Modernize the `ChatBubble` component into a high-fidelity, "Digital Editorial" style.

### Design Directives
- **Geometry**: Use `AkeliRadius.lg` (16px) for the message bubbles.
- **Theming**: 
    - **Sent**: `AkeliColors.info` (Brand Blue) with 15% opacity + `BackdropFilter` (Blur 10).
    - **Received**: `AkeliColors.surface` (White/Dark Grey) with 10% opacity + Glassmorphism.
- **Typography**: `Plus Jakarta Sans`. 
    - Message: `bodyMedium` (14px, Weight 500).
    - Meta (Time): `labelSmall` (10px, Weight 400).
- **Separation**: No lines/borders. Use subtle inner shadows or outer glows for depth.
- **Context**: Component appears in a scrolling list in `AiChatPage`.

### Functional Parity
- Keep `isSent`, `isRead`, `message`, `time`, and `senderName` parameters.
- Ensure the bubble tail logic (if any) is replaced by the simplified squircle with one corner difference (e.g., bottom-right for sent).

---

## 3. Implementation Plan (Flutter)

1.  **Refactor**: Update `lib/shared/widgets/chat_bubble.dart`.
2.  **Style**: Apply `AkeliGlass` or similar glass component if available, else implement manual `BackdropFilter` stack.
3.  **Layout**: Ensure `isSent` logic handles padding and alignment properly without standard Flutter `Alignment`.

The transcription hasn't been done correctly we need to work on it deeper
