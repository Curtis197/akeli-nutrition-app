# Chat Local Attachment Composer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stage recipe and image attachments locally in the chat composer with optional caption text, committing to the DB only when Send is tapped.

**Architecture:** A sealed `_PendingAttachment` class (private to `group_chat_page.dart`) holds a staged recipe object or raw image bytes. `_sendMessage()` consumes the attachment and text field content in one DB write. A new nullable `caption` column on `chat_message` stores the accompanying text. `AkeliChatBubble` renders the caption below the attachment card.

**Tech Stack:** Flutter 3.x, Riverpod, Supabase (Postgres migration + Storage), `image_picker`, `dart:typed_data`, `cached_network_image`

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `supabase/migrations/20260612090000_add_caption_to_chat_message.sql` | Create | Adds nullable `caption` column |
| `lib/providers/dm_provider.dart` | Modify | `ChatMessage` model + `sendMessage()` signature |
| `lib/features/community/group_chat_page.dart` | Modify | Sealed class, state, send logic, preview UI |
| `lib/shared/widgets/chat_bubble.dart` | Modify | `caption` param + render below attachment |
| `test/providers/dm_provider_test.dart` | Create | Unit tests for `ChatMessage.fromJson` with caption |
| `test/shared/widgets/chat_bubble_test.dart` | Create | Widget test for caption rendering |

---

## Task 1: DB Migration — add `caption` to `chat_message`

**Files:**
- Create: `supabase/migrations/20260612090000_add_caption_to_chat_message.sql`

- [ ] **Step 1: Create migration file**

```sql
ALTER TABLE chat_message ADD COLUMN caption text;
```

- [ ] **Step 2: Apply migration via Supabase MCP**

Use `mcp__claude_ai_Supabase__apply_migration` with:
- `project_id`: `njzqcftjzskwcpforwzf`
- `name`: `add_caption_to_chat_message`
- `query`: `ALTER TABLE chat_message ADD COLUMN caption text;`

- [ ] **Step 3: Verify the column exists**

Use `mcp__claude_ai_Supabase__execute_sql`:
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'chat_message' AND column_name = 'caption';
```
Expected: one row — `column_name=caption`, `data_type=text`, `is_nullable=YES`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260612090000_add_caption_to_chat_message.sql
git commit -m "feat: add caption column to chat_message"
```

---

## Task 2: Update `ChatMessage` model

**Files:**
- Modify: `lib/providers/dm_provider.dart`
- Create: `test/providers/dm_provider_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/providers/dm_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/providers/dm_provider.dart';

void main() {
  group('ChatMessage.fromJson', () {
    final baseJson = {
      'id': 'msg-1',
      'conversation_id': 'conv-1',
      'sender_id': 'user-a',
      'user_profile': {'first_name': 'Alice', 'avatar_url': null},
      'content': 'https://example.com/img.jpg',
      'message_type': 'image',
      'recipe_id': null,
      'sent_at': '2026-06-12T10:00:00.000Z',
    };

    test('parses caption when present', () {
      final msg = ChatMessage.fromJson(
        {...baseJson, 'caption': 'Check this out!'},
        currentUserId: 'user-b',
      );
      expect(msg.caption, 'Check this out!');
    });

    test('sets caption to null when field is absent', () {
      final msg = ChatMessage.fromJson(baseJson, currentUserId: 'user-b');
      expect(msg.caption, isNull);
    });

    test('sets caption to null when field is explicitly null', () {
      final msg = ChatMessage.fromJson(
        {...baseJson, 'caption': null},
        currentUserId: 'user-b',
      );
      expect(msg.caption, isNull);
    });
  });
}
```

- [ ] **Step 2: Run tests — confirm they fail**

```bash
flutter test test/providers/dm_provider_test.dart
```
Expected: compilation error — `ChatMessage` has no `caption` field.

- [ ] **Step 3: Add `caption` field to `ChatMessage`**

In `lib/providers/dm_provider.dart`, replace the `ChatMessage` class with:

```dart
@immutable
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String messageType;
  final String? recipeId;
  final String? caption;
  final DateTime sentAt;
  final bool isMine;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.messageType,
    this.recipeId,
    this.caption,
    required this.sentAt,
    required this.isMine,
  });

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    final profile = json['user_profile'] as Map<String, dynamic>?;
    final senderId = json['sender_id'] as String;
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: senderId,
      senderName: profile?['first_name'] as String? ?? 'Utilisateur',
      senderAvatar: profile?['avatar_url'] as String?,
      content: json['content'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      recipeId: json['recipe_id'] as String?,
      caption: json['caption'] as String?,
      sentAt: DateTime.parse(json['sent_at'] as String),
      isMine: senderId == currentUserId,
    );
  }
}
```

- [ ] **Step 4: Run tests — confirm they pass**

```bash
flutter test test/providers/dm_provider_test.dart
```
Expected: 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/providers/dm_provider.dart test/providers/dm_provider_test.dart
git commit -m "feat: add caption field to ChatMessage model"
```

---

## Task 3: Update `sendMessage()` to accept `caption`

**Files:**
- Modify: `lib/providers/dm_provider.dart`

- [ ] **Step 1: Replace `sendMessage()` with caption-aware version**

In `lib/providers/dm_provider.dart`, replace the `sendMessage` function:

```dart
Future<void> sendMessage(
  WidgetRef ref,
  String conversationId,
  String content, {
  String messageType = 'text',
  String? recipeId,
  String? caption,
}) async {
  final logger = appLogger;
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) return;

  logger.db(
      'BEFORE | table: chat_message | op: INSERT | conversationId: $conversationId | type: $messageType');
  try {
    await client.from('chat_message').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'content': content,
      'message_type': messageType,
      if (recipeId != null) 'recipe_id': recipeId,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
    });
    logger.db('AFTER | table: chat_message | inserted | type: $messageType');

    await client
        .from('conversation')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);
    logger.db('AFTER | table: conversation | updated_at bumped');
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls(
          'Permission denied | table: chat_message | INSERT | conversationId: $conversationId',
          error: e,
          stackTrace: st);
    } else {
      logger.db(
          'ERROR | table: chat_message | INSERT | code: ${e.code}',
          error: e,
          stackTrace: st);
    }
    rethrow;
  }

  // chatMessagesProvider is a realtime stream — it updates automatically.
  // Only invalidate the conversation list so the "last message" preview refreshes.
  ref.invalidate(myPrivateConversationsProvider);
}
```

- [ ] **Step 2: Analyze for errors**

```bash
flutter analyze lib/providers/dm_provider.dart
```
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/providers/dm_provider.dart
git commit -m "feat: add caption parameter to sendMessage"
```

---

## Task 4: Add `_PendingAttachment` sealed class + state variable

**Files:**
- Modify: `lib/features/community/group_chat_page.dart`

- [ ] **Step 1: Add sealed class before `GroupChatPage`**

After the last import line and before `class GroupChatPage extends ConsumerStatefulWidget`, insert:

```dart
// ---------------------------------------------------------------------------
// Pending attachment — staged locally until Send is tapped
// ---------------------------------------------------------------------------

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

- [ ] **Step 2: Add `_pendingAttachment` to widget state**

In `_GroupChatPageState`, after `bool _isUploading = false;`, add:

```dart
_PendingAttachment? _pendingAttachment;
```

- [ ] **Step 3: Analyze for errors**

```bash
flutter analyze lib/features/community/group_chat_page.dart
```
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/features/community/group_chat_page.dart
git commit -m "feat: add _PendingAttachment sealed class to GroupChatPage"
```

---

## Task 5: Stage recipe locally in `_showRecipePicker`

**Files:**
- Modify: `lib/features/community/group_chat_page.dart`

- [ ] **Step 1: Replace `_showRecipePicker` with local-staging version**

Replace the entire `_showRecipePicker` method:

```dart
void _showRecipePicker() {
  if (_resolvedConversationId == null) return;
  _logger.userAction('Recipe picker opened', screen: 'GroupChatPage');
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AkeliColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RecipePickerSheet(
      onRecipeSelected: (recipe) {
        Navigator.of(context).pop();
        _logger.userAction('Recipe staged for send', screen: 'GroupChatPage',
            metadata: {'recipeId': recipe.id, 'title': recipe.title});
        setState(() => _pendingAttachment = _PendingRecipe(recipe));
      },
    ),
  );
}
```

- [ ] **Step 2: Analyze for errors**

```bash
flutter analyze lib/features/community/group_chat_page.dart
```
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/community/group_chat_page.dart
git commit -m "feat: stage recipe locally instead of sending immediately"
```

---

## Task 6: Stage image locally in `_sendImageMessage`

**Files:**
- Modify: `lib/features/community/group_chat_page.dart`

- [ ] **Step 1: Replace `_sendImageMessage` with local-staging version**

Replace the entire `_sendImageMessage` method:

```dart
Future<void> _sendImageMessage() async {
  if (_resolvedConversationId == null) return;
  final picker = ImagePicker();
  final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
  if (file == null || !mounted) return;

  final bytes = await file.readAsBytes();
  final ext = file.name.split('.').last.toLowerCase();
  final extension = ext.isNotEmpty ? ext : 'jpg';

  _logger.userAction('Image staged for send', screen: 'GroupChatPage',
      metadata: {'size': bytes.length, 'ext': extension});
  setState(() => _pendingAttachment = _PendingImage(bytes, extension));
}
```

- [ ] **Step 2: Analyze for errors**

```bash
flutter analyze lib/features/community/group_chat_page.dart
```
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/community/group_chat_page.dart
git commit -m "feat: stage image locally instead of uploading immediately"
```

---

## Task 7: Update `_sendMessage` to handle attachment + caption

**Files:**
- Modify: `lib/features/community/group_chat_page.dart`

- [ ] **Step 1: Replace `_sendMessage` with attachment-aware version**

Replace the entire `_sendMessage` method:

```dart
void _sendMessage() {
  final text = _controller.text.trim();
  if (_pendingAttachment == null && text.isEmpty) return;
  if (_resolvedConversationId == null) return;

  _controller.clear();
  final attachment = _pendingAttachment;
  setState(() => _pendingAttachment = null);

  if (attachment is _PendingRecipe) {
    _logger.userAction('Recipe message sent', screen: 'GroupChatPage', metadata: {
      'conversationId': _resolvedConversationId,
      'recipeId': attachment.recipe.id,
      'hasCaption': text.isNotEmpty,
    });
    sendMessage(
      ref,
      _resolvedConversationId!,
      attachment.recipe.title,
      messageType: 'recipe_share',
      recipeId: attachment.recipe.id,
      caption: text.isNotEmpty ? text : null,
    ).then((_) {
      if (widget.groupId != null) {
        _notifyGroupMembers(widget.groupId!, '🍽️ ${attachment.recipe.title}');
      }
    }).catchError((Object e, StackTrace st) {
      _logger.db('ERROR | sendMessage recipe_share | $e', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'envoi")),
        );
      }
    });
  } else if (attachment is _PendingImage) {
    _logger.userAction('Image message sent', screen: 'GroupChatPage', metadata: {
      'conversationId': _resolvedConversationId,
      'hasCaption': text.isNotEmpty,
    });
    setState(() => _isUploading = true);
    uploadChatImage(ref, attachment.bytes, attachment.extension).then((url) {
      return sendMessage(
        ref,
        _resolvedConversationId!,
        url,
        messageType: 'image',
        caption: text.isNotEmpty ? text : null,
      );
    }).then((_) {
      if (widget.groupId != null && mounted) {
        _notifyGroupMembers(widget.groupId!, '📷 Photo');
      }
    }).catchError((Object e, StackTrace st) {
      _logger.db('ERROR | _sendMessage image | $e', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'envoi de l'image")),
        );
      }
    }).whenComplete(() {
      if (mounted) setState(() => _isUploading = false);
    });
  } else {
    // Plain text — no attachment
    _logger.userAction('Message sent', screen: 'GroupChatPage', metadata: {
      'conversationId': _resolvedConversationId,
      'groupId': widget.groupId,
      'length': text.length,
    });
    sendMessage(ref, _resolvedConversationId!, text).then((_) {
      if (widget.groupId != null) {
        _notifyGroupMembers(widget.groupId!, text);
      }
    }).catchError((Object e, StackTrace st) {
      _logger.db('ERROR | sendMessage | $e', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'envoi")),
        );
      }
    });
  }
}
```

- [ ] **Step 2: Analyze for errors**

```bash
flutter analyze lib/features/community/group_chat_page.dart
```
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/community/group_chat_page.dart
git commit -m "feat: handle attachment + caption in _sendMessage"
```

---

## Task 8: Attachment preview UI

**Files:**
- Modify: `lib/features/community/group_chat_page.dart`

- [ ] **Step 1: Add `_buildAttachmentPreview()` method**

Add this method to `_GroupChatPageState`, directly before the `build()` method:

```dart
Widget _buildAttachmentPreview() {
  final attachment = _pendingAttachment;
  if (attachment == null) return const SizedBox.shrink();

  _logger.provider('_buildAttachmentPreview | type: ${attachment.runtimeType}');

  final Widget leading;
  final String label;

  if (attachment is _PendingRecipe) {
    leading = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: attachment.recipe.thumbnailUrl != null
          ? Image.network(
              attachment.recipe.thumbnailUrl!,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 44,
                color: AkeliColors.surface,
                child: const Icon(Icons.restaurant, size: 20,
                    color: AkeliColors.outline),
              ),
            )
          : Container(
              width: 44,
              height: 44,
              color: AkeliColors.surface,
              child: const Icon(Icons.restaurant, size: 20,
                  color: AkeliColors.outline),
            ),
    );
    label = attachment.recipe.title;
  } else {
    final img = attachment as _PendingImage;
    leading = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.memory(
        img.bytes,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      ),
    );
    label = 'Photo';
  }

  return Container(
    color: AkeliColors.surfaceContainer,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: [
        leading,
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AkeliColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          color: AkeliColors.textSecondary,
          onPressed: () {
            _logger.userAction('Attachment cancelled', screen: 'GroupChatPage');
            setState(() => _pendingAttachment = null);
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Insert preview call into the input bar**

In the `build()` method, inside the bottom `Container`'s `Column`, add `_buildAttachmentPreview()` as the **first** child, before `if (_isUploading)`:

```dart
Container(
  color: AkeliColors.surface,
  padding: const EdgeInsets.symmetric(
      horizontal: AkeliSpacing.sm, vertical: AkeliSpacing.sm),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildAttachmentPreview(),   // ← new
      if (_isUploading)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text('Envoi en cours…',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AkeliColors.textSecondary)),
            ],
          ),
        ),
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: AkeliColors.primary,
            tooltip: 'Joindre',
            onPressed: _isUploading ? null : _showAttachOptions,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                _logger.userAction('Message submitted via keyboard',
                    screen: 'GroupChatPage');
                _sendMessage();
              },
              decoration: InputDecoration(
                hintText: 'Écrire un message…',
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AkeliRadius.pill)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AkeliSpacing.md,
                    vertical: AkeliSpacing.sm),
              ),
            ),
          ),
          const SizedBox(width: AkeliSpacing.xs),
          IconButton(
            icon: const Icon(Icons.send_rounded),
            color: AkeliColors.primary,
            onPressed: _isUploading
                ? null
                : () {
                    _logger.userAction('Send button tapped',
                        screen: 'GroupChatPage');
                    _sendMessage();
                  },
          ),
        ],
      ),
    ],
  ),
),
```

- [ ] **Step 3: Analyze for errors**

```bash
flutter analyze lib/features/community/group_chat_page.dart
```
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/features/community/group_chat_page.dart
git commit -m "feat: add attachment preview strip to chat composer"
```

---

## Task 9: Add caption to `AkeliChatBubble`

**Files:**
- Modify: `lib/shared/widgets/chat_bubble.dart`
- Modify: `lib/features/community/group_chat_page.dart`
- Create: `test/shared/widgets/chat_bubble_test.dart`

- [ ] **Step 1: Write failing widget test**

Create `test/shared/widgets/chat_bubble_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/shared/widgets/chat_bubble.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  group('AkeliChatBubble caption', () {
    testWidgets('renders caption on image bubble when present', (tester) async {
      await tester.pumpWidget(_wrap(
        const AkeliChatBubble(
          message: 'https://example.com/img.jpg',
          time: '10:00',
          isSent: true,
          messageType: 'image',
          caption: 'Check this out!',
        ),
      ));
      await tester.pump(const Duration(seconds: 2)); // let image request timeout
      expect(find.text('Check this out!'), findsOneWidget);
    });

    testWidgets('no extra text widget when caption is null on text bubble',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const AkeliChatBubble(
          message: 'Hello',
          time: '10:00',
          isSent: true,
          messageType: 'text',
        ),
      ));
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Check this out!'), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run tests — confirm they fail**

```bash
flutter test test/shared/widgets/chat_bubble_test.dart
```
Expected: compilation error — `AkeliChatBubble` has no `caption` parameter.

- [ ] **Step 3: Update `AkeliChatBubble` with `caption` field**

Replace the `AkeliChatBubble` class and `_buildContent` in `lib/shared/widgets/chat_bubble.dart`:

```dart
class AkeliChatBubble extends ConsumerWidget {
  final String message;
  final String time;
  final bool isSent;
  final String? senderName;
  final bool isRead;
  final String messageType;
  final String? recipeId;
  final String? caption;

  const AkeliChatBubble({
    super.key,
    required this.message,
    required this.time,
    required this.isSent,
    this.senderName,
    this.isRead = false,
    this.messageType = 'text',
    this.recipeId,
    this.caption,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.provider('AkeliChatBubble build() | type: $messageType');

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContent(context, ref),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AkeliColors.textSecondary,
                      ),
                ),
                if (isSent && isRead) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 12, color: AkeliColors.success),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return switch (messageType) {
      'image'        => _ImageBubble(url: message, isSent: isSent, senderName: senderName, caption: caption),
      'recipe_share' => _RecipeBubble(recipeId: recipeId ?? message, isSent: isSent, ref: ref, context: context, senderName: senderName, caption: caption),
      _              => _TextBubble(text: message, isSent: isSent, senderName: senderName),
    };
  }
}
```

- [ ] **Step 4: Update `_ImageBubble` with caption**

Replace `_ImageBubble` in `lib/shared/widgets/chat_bubble.dart`:

```dart
class _ImageBubble extends StatelessWidget {
  final String url;
  final bool isSent;
  final String? senderName;
  final String? caption;

  const _ImageBubble({
    required this.url,
    required this.isSent,
    this.senderName,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _bubbleBorderRadius(isSent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (senderName != null)
            Container(
              width: double.infinity,
              color: AkeliColors.surfaceContainer,
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
              child: Text(
                senderName!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AkeliColors.primary,
                ),
              ),
            ),
          CachedNetworkImage(
            imageUrl: url,
            width: 220,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 220,
              height: 160,
              color: AkeliColors.surfaceContainer,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 220,
              height: 100,
              color: AkeliColors.surfaceContainer,
              child: const Icon(Icons.broken_image_outlined, color: AkeliColors.outline),
            ),
          ),
          if (caption != null && caption!.isNotEmpty)
            Container(
              width: double.infinity,
              color: isSent
                  ? AkeliColors.info.withValues(alpha: 0.15)
                  : AkeliColors.surface,
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Text(
                caption!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AkeliColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Update `_RecipeBubble` with caption**

Replace `_RecipeBubble` in `lib/shared/widgets/chat_bubble.dart`:

```dart
class _RecipeBubble extends StatelessWidget {
  final String recipeId;
  final bool isSent;
  final WidgetRef ref;
  final BuildContext context;
  final String? senderName;
  final String? caption;

  const _RecipeBubble({
    required this.recipeId,
    required this.isSent,
    required this.ref,
    required this.context,
    this.senderName,
    this.caption,
  });

  @override
  Widget build(BuildContext _) {
    final recipeAsync = ref.watch(recipeDetailProvider(recipeId));

    return GestureDetector(
      onTap: () {
        appLogger.userAction('Recipe share tapped', screen: 'ChatBubble',
            metadata: {'recipeId': recipeId});
        context.push(AkeliRoutes.recipeDetailPath(recipeId));
      },
      child: Container(
        width: 220,
        decoration: _bubbleDecoration(isSent),
        clipBehavior: Clip.hardEdge,
        child: recipeAsync.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Recette introuvable',
              style: TextStyle(color: AkeliColors.textSecondary, fontSize: 13),
            ),
          ),
          data: (recipe) {
            if (recipe == null) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Recette supprimée',
                    style: TextStyle(
                        color: AkeliColors.textSecondary, fontSize: 13)),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (senderName != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Text(
                      senderName!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AkeliColors.primary,
                      ),
                    ),
                  ),
                if (recipe.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: recipe.thumbnailUrl!,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      height: 110,
                      color: AkeliColors.surfaceContainer,
                      child: const Icon(Icons.restaurant,
                          color: AkeliColors.outline),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AkeliColors.textPrimary,
                        ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      12, 0, 12,
                      caption != null && caption!.isNotEmpty ? 4 : 10),
                  child: Row(
                    children: [
                      if (recipe.calories100g != null) ...[
                        const Icon(Icons.local_fire_department_rounded,
                            size: 13, color: AkeliColors.secondary),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.calories100g!.round()} kcal/100g',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: AkeliColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      Text(
                        'Voir →',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: AkeliColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                if (caption != null && caption!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Text(
                      caption!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AkeliColors.textPrimary,
                          ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Pass `caption` in the `ListView.builder` in `GroupChatPage`**

In `lib/features/community/group_chat_page.dart`, find the `AkeliChatBubble(...)` call inside the `ListView.builder` and add `caption: msg.caption`:

```dart
child: AkeliChatBubble(
  message: msg.content,
  time: _formatTime(msg.sentAt),
  isSent: msg.isMine,
  senderName: msg.isMine
      ? (currentUserProfile?.firstName ?? 'Moi')
      : (participantNames[msg.senderId] ?? msg.senderName),
  isRead: false,
  messageType: msg.messageType,
  recipeId: msg.recipeId,
  caption: msg.caption,
),
```

- [ ] **Step 7: Run widget tests**

```bash
flutter test test/shared/widgets/chat_bubble_test.dart
```
Expected: 2 tests pass.

- [ ] **Step 8: Full codebase analyze**

```bash
flutter analyze lib/
```
Expected: No issues found.

- [ ] **Step 9: Commit**

```bash
git add lib/shared/widgets/chat_bubble.dart lib/features/community/group_chat_page.dart test/shared/widgets/chat_bubble_test.dart
git commit -m "feat: add caption support to AkeliChatBubble and wire through GroupChatPage"
```
