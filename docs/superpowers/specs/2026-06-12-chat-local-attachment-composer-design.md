# Chat Local Attachment Composer

**Date:** 2026-06-12
**Status:** Approved

## Problem

When a user picks a recipe or image to share in a group or DM chat, the content is immediately uploaded and written to the database — before the user taps Send. There is no opportunity to add a caption, review the attachment, or cancel it. The goal is to stage the attachment locally in the composer, allow optional caption text, and commit everything to the DB only when Send is tapped.

## Scope

- `GroupChatPage` (covers both group chats and DM chats, since both use the same widget)
- `AkeliChatBubble` widget
- `ChatMessage` model
- `sendMessage()` function in `dm_provider.dart`
- One DB migration on `chat_message`

Out of scope: AI assistant chat (`AiChatPage`), support chat.

---

## 1. DB Schema

**Migration:** `20260612090000_add_caption_to_chat_message.sql`

```sql
ALTER TABLE chat_message ADD COLUMN caption text;
```

- Nullable. Null for all existing rows and for plain `text` messages.
- For `image` and `recipe_share` messages: holds the optional user-typed text sent alongside the attachment.
- `content` is unchanged: URL for images, recipe title for recipe shares, message body for text.

---

## 2. Data Layer

### `ChatMessage` model (`dm_provider.dart`)

Add field:
```dart
final String? caption;
```

`ChatMessage.fromJson` reads:
```dart
caption: json['caption'] as String?,
```

### `sendMessage()` signature

```dart
Future<void> sendMessage(
  WidgetRef ref,
  String conversationId,
  String content, {
  String messageType = 'text',
  String? recipeId,
  String? caption,
}) async
```

The INSERT includes `caption` when non-null and non-empty:
```dart
if (caption != null && caption.isNotEmpty) 'caption': caption,
```

---

## 3. `GroupChatPage` Composer State

### Sealed class (top of `group_chat_page.dart`)

```dart
sealed class _PendingAttachment {}

class _PendingRecipe extends _PendingAttachment {
  final Recipe recipe;
  _PendingRecipe(this.recipe);
}

class _PendingImage extends _PendingAttachment {
  final Uint8List bytes;
  final String extension;
  _PendingImage(this.bytes, this.extension);
}
```

### Widget state

```dart
_PendingAttachment? _pendingAttachment;
```

### Behaviour changes

| Method | Before | After |
|---|---|---|
| `_showRecipePicker` callback | Calls `sendMessage()` immediately | Sets `_pendingAttachment = _PendingRecipe(recipe)`, closes sheet |
| `_sendImageMessage` | Uploads bytes, calls `sendMessage()` | Reads bytes into `_PendingImage`, no upload |
| `_sendMessage` | Sends text only | If attachment present: upload (image) then `sendMessage()` with `caption: text`; clear attachment after |

### `_sendMessage` logic (pseudocode)

```
if _pendingAttachment is _PendingRecipe:
    sendMessage(conversationId, recipe.title, type='recipe_share', recipeId=recipe.id, caption=text)
    clear _pendingAttachment
else if _pendingAttachment is _PendingImage:
    setState(isUploading = true)
    url = await uploadChatImage(bytes, ext)
    sendMessage(conversationId, url, type='image', caption=text)
    clear _pendingAttachment
    setState(isUploading = false)
else:
    sendMessage(conversationId, text)

clear text field
```

- If `_pendingAttachment` is set and `text` is empty, the message is sent with `caption: null`.
- If text is non-empty and no attachment, sends a plain text message (no change from current).
- Send button is disabled while `_isUploading` (unchanged from current).

---

## 4. Attachment Preview UI

Rendered between the message list and the input bar when `_pendingAttachment != null`.

### Recipe preview

```
┌─────────────────────────────────────────────────┐
│ 🍽  Poulet yassa au citron            ×         │
└─────────────────────────────────────────────────┘
```

- Leading: recipe `thumbnailUrl` in a 44×44 ClipRRect, falling back to `Icons.restaurant`
- Title: `Text(recipe.title)` — single line, ellipsis overflow
- Trailing: `IconButton(Icons.close)` → `setState(() => _pendingAttachment = null)`
- Background: `AkeliColors.surfaceContainer`, rounded top corners

### Image preview

```
┌──────────────────────────────────────────────────┐
│ [60px tall image thumbnail]                 ×    │
└──────────────────────────────────────────────────┘
```

- `Image.memory(bytes)` at 60px height, `BoxFit.cover`, clipped to `BorderRadius.circular(8)`
- Same `×` cancel button

---

## 5. Chat Bubble Caption

`AkeliChatBubble` gains:

```dart
final String? caption;
```

When `caption` is non-null and non-empty on an `image` or `recipe_share` message, a `Text` widget renders **below** the image/recipe card inside the same bubble, with:
- Style: `bodySmall`, `AkeliColors.textPrimary`
- Padding: `EdgeInsets.fromLTRB(12, 6, 12, 10)`

Plain `text` messages: `caption` is always null, no change.

The `AkeliChatBubble` call in `GroupChatPage`'s `ListView.builder` passes `caption: msg.caption`.

---

## Files Changed

| File | Change |
|---|---|
| `supabase/migrations/20260612090000_add_caption_to_chat_message.sql` | New — adds `caption` column |
| `lib/providers/dm_provider.dart` | `ChatMessage` model + `sendMessage()` signature |
| `lib/features/community/group_chat_page.dart` | Sealed class, state, `_sendMessage`, `_sendImageMessage`, `_showRecipePicker`, preview UI |
| `lib/shared/widgets/chat_bubble.dart` | `caption` param + render below attachment |
