import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/food_region_provider.dart';
import '../../shared/models/recipe.dart';
import '../../shared/widgets/chat_bubble.dart';
import '../../shared/widgets/avatar.dart';

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

class GroupChatPage extends ConsumerStatefulWidget {
  final String? groupId;
  final String? conversationId;
  final String? title;

  const GroupChatPage({
    super.key,
    this.groupId,
    this.conversationId,
    this.title,
  }) : assert(
          (groupId != null) != (conversationId != null),
          'Exactly one of groupId or conversationId must be provided',
        );

  @override
  ConsumerState<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends ConsumerState<GroupChatPage> {
  final _controller = TextEditingController();
  final _logger = appLogger;
  String? _resolvedConversationId;
  bool _isUploading = false;
  _PendingAttachment? _pendingAttachment;

  @override
  void initState() {
    super.initState();
    _logger.provider(
        'GroupChatPage initState() | groupId: ${widget.groupId} | conversationId: ${widget.conversationId}');
    if (widget.conversationId != null) {
      _resolvedConversationId = widget.conversationId;
      _markRead();
    }
  }

  @override
  void dispose() {
    _logger.provider('GroupChatPage disposed');
    _controller.dispose();
    super.dispose();
  }

  void _markRead() {
    if (_resolvedConversationId == null) return;
    markConversationRead(ref, _resolvedConversationId!).catchError((e) {
      _logger.db('ERROR | markConversationRead | $e');
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final attachment = _pendingAttachment;
    if (text.isEmpty && attachment == null) return;
    if (_resolvedConversationId == null) return;

    _logger.userAction('Message sent', screen: 'GroupChatPage', metadata: {
      'conversationId': _resolvedConversationId,
      'groupId': widget.groupId,
      'type': attachment == null ? 'text' : (attachment is _PendingRecipe ? 'recipe_share' : 'image'),
    });

    _controller.clear();
    setState(() => _pendingAttachment = null);

    try {
      if (attachment is _PendingRecipe) {
        final caption = text.isNotEmpty ? text : null;
        await sendMessage(
          ref,
          _resolvedConversationId!,
          attachment.recipe.title,
          messageType: 'recipe_share',
          recipeId: attachment.recipe.id,
          caption: caption,
        );
        if (widget.groupId != null && mounted) {
          _notifyGroupMembers(widget.groupId!, '🍽️ ${attachment.recipe.title}');
        }
      } else if (attachment is _PendingImage) {
        setState(() => _isUploading = true);
        final caption = text.isNotEmpty ? text : null;
        final url = await uploadChatImage(ref, attachment.bytes, attachment.extension);
        await sendMessage(
          ref,
          _resolvedConversationId!,
          url,
          messageType: 'image',
          caption: caption,
        );
        if (widget.groupId != null && mounted) {
          _notifyGroupMembers(widget.groupId!, '📷 Photo');
        }
      } else {
        await sendMessage(ref, _resolvedConversationId!, text);
        if (widget.groupId != null && mounted) {
          _notifyGroupMembers(widget.groupId!, text);
        }
      }
    } catch (e, st) {
      _logger.db('ERROR | _sendMessage | $e', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'envoi")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _notifyGroupMembers(String groupId, String text) {
    final preview = text.substring(0, min(100, text.length));
    _logger.edge('notify-group-message', 'BEFORE | groupId: $groupId');
    final client = ref.read(supabaseClientProvider);
    client.functions.invoke(
      'notify-group-message',
      body: {'group_id': groupId, 'message_preview': preview},
    ).then((_) {
      _logger.edge('notify-group-message', 'AFTER | success');
    }).catchError((Object e, StackTrace st) {
      _logger.edge('notify-group-message', 'ERROR | $e', error: e, stackTrace: st);
    });
  }

  void _showAttachOptions() {
    _logger.userAction('Attach button tapped', screen: 'GroupChatPage');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AkeliColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AkeliColors.primary,
                  child: Icon(Icons.image_outlined, color: Colors.white),
                ),
                title: const Text('Photo'),
                subtitle: const Text('Depuis votre galerie'),
                onTap: () {
                  Navigator.of(context).pop();
                  _sendImageMessage();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AkeliColors.secondary,
                  child: Icon(Icons.restaurant_menu_outlined, color: Colors.white),
                ),
                title: const Text('Recette'),
                subtitle: const Text('Partager une recette Akeli'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showRecipePicker();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendImageMessage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    final extension = ext.isNotEmpty ? ext : 'jpg';

    _logger.userAction('Image staged in composer', screen: 'GroupChatPage',
        metadata: {'size': bytes.length, 'ext': extension});
    setState(() => _pendingAttachment = _PendingImage(bytes, extension));
  }

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
          _logger.userAction('Recipe staged in composer', screen: 'GroupChatPage',
              metadata: {'recipeId': recipe.id, 'title': recipe.title});
          setState(() => _pendingAttachment = _PendingRecipe(recipe));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If groupId provided, resolve conversationId via provider
    if (widget.groupId != null && _resolvedConversationId == null) {
      final resolved = ref.watch(resolveConversationIdProvider(widget.groupId!));
      return resolved.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
        data: (convId) {
          if (convId == null) {
            return const Scaffold(
                body: Center(child: Text('Conversation introuvable')));
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _resolvedConversationId = convId);
              _markRead();
            }
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      );
    }

    final convId = _resolvedConversationId!;
    final isGroup = widget.groupId != null;
    final appBarTitle =
        widget.title ?? (isGroup ? 'Discussion du groupe' : 'Message privé');

    _logger.provider('GroupChatPage build() | conversationId: $convId');

    final messagesAsync = ref.watch(chatMessagesProvider(convId));
    final participantNames = ref.watch(conversationParticipantNamesProvider(convId)).valueOrNull ?? {};
    final currentUserProfile = ref.watch(userProfileProvider).valueOrNull;

    // Admin check — only needed for group chats
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final groupDetails = isGroup
        ? ref.watch(groupDetailsProvider(widget.groupId!))
        : const AsyncData<Map<String, dynamic>?>(null);
    final isAdmin = groupDetails.valueOrNull?['creator_id'] == currentUserId;

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: AkeliColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AkeliRoutes.community);
            }
          },
        ),
        title: isGroup
            ? Row(
                children: [
                  AkeliAvatar(
                    imageUrl: groupDetails.valueOrNull?['cover_url'] as String?,
                    initials: (groupDetails.valueOrNull?['name'] as String? ?? 'G').substring(0, 1).toUpperCase(),
                    size: AvatarSize.sm,
                  ),
                  const SizedBox(width: AkeliSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupDetails.valueOrNull?['name'] as String? ?? 'Discussion du groupe',
                          style: const TextStyle(fontSize: 18),
                        ),
                        Builder(builder: (context) {
                          final count = groupDetails.valueOrNull?['member_count'] as int?;
                          final subtitle = count != null
                              ? '$count membre${count > 1 ? 's' : ''}'
                              : groupDetails.valueOrNull?['description'] as String? ?? '';
                          if (subtitle.trim().isEmpty) return const SizedBox.shrink();
                          return Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AkeliColors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              )
            : Builder(
                builder: (context) {
                  final dms = ref.watch(myPrivateConversationsProvider).valueOrNull ?? <DmConversation>[];
                  DmConversation? currentDm;
                  for (final dm in dms) {
                    if (dm.conversationId == convId) {
                      currentDm = dm;
                      break;
                    }
                  }
                  return Row(
                    children: [
                      AkeliAvatar(
                        imageUrl: currentDm?.otherUserAvatar,
                        initials: (widget.title != null && widget.title!.isNotEmpty) ? widget.title!.substring(0, 1).toUpperCase() : '?',
                        size: AvatarSize.sm,
                      ),
                      const SizedBox(width: AkeliSpacing.md),
                      Expanded(child: Text(appBarTitle)),
                    ],
                  );
                },
              ),
        actions: [
          if (isGroup && isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                _logger.userAction('Edit group tapped', screen: 'GroupChatPage');
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) => _EditGroupSheet(
                    groupId: widget.groupId!,
                    initialName: groupDetails.valueOrNull?['name'] as String? ?? '',
                    initialDescription: groupDetails.valueOrNull?['description'] as String?,
                    initialIsPublic: groupDetails.valueOrNull?['is_public'] as bool? ?? true,
                    initialRegionId: groupDetails.valueOrNull?['region_code'] as String?,
                    initialLanguage: groupDetails.valueOrNull?['language'] as String?,
                    initialTopic: groupDetails.valueOrNull?['topic'] as String?,
                    initialMaxMembers: groupDetails.valueOrNull?['max_members'] as int?,
                    initialCoverUrl: groupDetails.valueOrNull?['cover_url'] as String?,
                    onSaved: () => ref.invalidate(groupDetailsProvider(widget.groupId!)),
                  ),
                );
              },
            ),
          if (isGroup)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                _logger.userAction('Group info tapped',
                    screen: 'GroupChatPage');
                context.push(AkeliRoutes.groupDetailPath(widget.groupId!));
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun message pour le moment.\nSoyez le premier à écrire !',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AkeliColors.onSurfaceVariant),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(AkeliSpacing.md),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AkeliSpacing.sm),
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: AkeliColors.surface,
            padding: const EdgeInsets.symmetric(
                horizontal: AkeliSpacing.sm, vertical: AkeliSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAttachmentPreview(),
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
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    final attachment = _pendingAttachment;
    if (attachment == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AkeliColors.surfaceContainer,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AkeliRadius.md),
          topRight: Radius.circular(AkeliRadius.md),
        ),
      ),
      child: Row(
        children: [
          if (attachment is _PendingRecipe) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: attachment.recipe.thumbnailUrl != null
                  ? Image.network(
                      attachment.recipe.thumbnailUrl!,
                      width: 44, height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, size: 24, color: AkeliColors.outline),
                    )
                  : const Icon(Icons.restaurant, size: 24, color: AkeliColors.outline),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                attachment.recipe.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AkeliColors.textPrimary,
                    ),
              ),
            ),
          ] else if (attachment is _PendingImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                attachment.bytes,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Photo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AkeliColors.textSecondary,
                    ),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: AkeliColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              _logger.userAction('Attachment preview dismissed', screen: 'GroupChatPage');
              setState(() => _pendingAttachment = null);
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day &&
        dt.month == now.month &&
        dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }
}

// ---------------------------------------------------------------------------
// Recipe Picker Sheet — lets user pick a published recipe to share in chat
// ---------------------------------------------------------------------------

class _RecipePickerSheet extends ConsumerStatefulWidget {
  final void Function(Recipe) onRecipeSelected;

  const _RecipePickerSheet({required this.onRecipeSelected});

  @override
  ConsumerState<_RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends ConsumerState<_RecipePickerSheet> {
  final _logger = appLogger;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _logger.provider('RecipePickerSheet initState()');
    _searchController.addListener(() {
      if (_searchController.text != _query) {
        setState(() => _query = _searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _logger.provider('RecipePickerSheet disposed');
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('RecipePickerSheet build() | query: "$_query"');
    final recipesAsync = ref.watch(chatRecipePickerProvider(_query));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AkeliColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Partager une recette',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Rechercher une recette…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AkeliRadius.pill)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: recipesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) {
                _logger.provider('RecipePickerSheet → error | $e');
                return const Center(child: Text('Erreur de chargement'));
              },
              data: (recipes) {
                _logger.provider('RecipePickerSheet → data | count: ${recipes.length}');
                if (recipes.isEmpty) {
                  return Center(
                    child: Text(
                      _query.isEmpty ? 'Aucune recette disponible' : 'Aucun résultat pour "$_query"',
                      style: const TextStyle(color: AkeliColors.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 32),
                  itemCount: recipes.length,
                  itemBuilder: (context, i) {
                    final recipe = recipes[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: recipe.thumbnailUrl != null
                            ? Image.network(
                                recipe.thumbnailUrl!,
                                width: 52, height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 52, height: 52,
                                  color: AkeliColors.surfaceContainer,
                                  child: const Icon(Icons.restaurant, color: AkeliColors.outline),
                                ),
                              )
                            : Container(
                                width: 52, height: 52,
                                color: AkeliColors.surfaceContainer,
                                child: const Icon(Icons.restaurant, color: AkeliColors.outline),
                              ),
                      ),
                      title: Text(recipe.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: recipe.calories100g != null
                          ? Text('${recipe.calories100g!.round()} kcal/100g · ${recipe.totalTimeMin} min',
                              style: const TextStyle(color: AkeliColors.textSecondary, fontSize: 12))
                          : Text('${recipe.totalTimeMin} min',
                              style: const TextStyle(color: AkeliColors.textSecondary, fontSize: 12)),
                      trailing: const Icon(Icons.send_rounded, color: AkeliColors.primary, size: 20),
                      onTap: () {
                        _logger.userAction('Recipe selected in picker', metadata: {'recipeId': recipe.id});
                        widget.onRecipeSelected(recipe);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit Group Sheet — visible to group admin only
// ---------------------------------------------------------------------------

class _EditGroupSheet extends ConsumerStatefulWidget {
  final String groupId;
  final String initialName;
  final String? initialDescription;
  final bool initialIsPublic;
  final String? initialRegionId;
  final String? initialLanguage;
  final String? initialTopic;
  final int? initialMaxMembers;
  final String? initialCoverUrl;
  final VoidCallback? onSaved;

  const _EditGroupSheet({
    required this.groupId,
    required this.initialName,
    this.initialDescription,
    required this.initialIsPublic,
    this.initialRegionId,
    this.initialLanguage,
    this.initialTopic,
    this.initialMaxMembers,
    this.initialCoverUrl,
    this.onSaved,
  });

  @override
  ConsumerState<_EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends ConsumerState<_EditGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _maxMembersController;
  late bool _isPublic;
  String? _regionId;
  String? _language;
  String? _topic;
  bool _isLoading = false;
  String? _errorMsg;
  Uint8List? _coverImageBytes;
  String? _coverImageExtension;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (file != null) {
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last.toLowerCase();
        setState(() {
          _coverImageBytes = bytes;
          _coverImageExtension = ext.isNotEmpty ? ext : 'jpg';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la sélection de l\'image')),
        );
      }
    }
  }

  static const _languages = {
    'fr': 'Français', 'en': 'English', 'es': 'Español',
    'pt': 'Português', 'wo': 'Wolof', 'bm': 'Bambara', 'ln': 'Lingala'
  };

  static const _topics = {
    'cuisine_africaine': 'Cuisine Africaine', 'batch_cooking': 'Session de cuisine',
    'nutrition': 'Nutrition', 'sport_forme': 'Sport & Forme',
    'perte_de_poids': 'Perte de poids', 'vegetarien': 'Végétarien', 'autre': 'Autre'
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descController = TextEditingController(text: widget.initialDescription ?? '');
    _maxMembersController = TextEditingController(text: widget.initialMaxMembers?.toString() ?? '');
    _isPublic = widget.initialIsPublic;
    _regionId = widget.initialRegionId;
    _language = widget.initialLanguage;
    _topic = widget.initialTopic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final maxMemStr = _maxMembersController.text.trim();
      final maxMem = maxMemStr.isNotEmpty ? int.tryParse(maxMemStr) : null;
      
      if (_coverImageBytes != null && _coverImageExtension != null) {
        await updateGroupCover(ref, widget.groupId, _coverImageBytes!, _coverImageExtension!);
      }

      await updateGroup(
        ref,
        groupId: widget.groupId,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        isPublic: _isPublic,
        regionId: _regionId,
        language: _language,
        topic: _topic,
        maxMembers: maxMem,
      );
      widget.onSaved?.call();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() { _isLoading = false; _errorMsg = 'Erreur lors de la mise à jour'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final regionsAsync = ref.watch(foodRegionsProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AkeliSpacing.lg,
        right: AkeliSpacing.lg,
        top: AkeliSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Modifier le groupe',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AkeliSpacing.lg),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AkeliColors.surfaceContainer,
                        backgroundImage: _coverImageBytes != null
                            ? MemoryImage(_coverImageBytes!)
                            : (widget.initialCoverUrl != null
                                ? NetworkImage(widget.initialCoverUrl!)
                                : null) as ImageProvider?,
                        child: _coverImageBytes == null && widget.initialCoverUrl == null
                            ? const Icon(Icons.camera_alt, size: 32, color: AkeliColors.textSecondary)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AkeliColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AkeliSpacing.lg),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Le nom est requis';
                  return null;
                },
              ),
              const SizedBox(height: AkeliSpacing.md),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optionnelle)',
                  border: OutlineInputBorder(),
                ),
                maxLength: 200,
                maxLines: 3,
              ),
              const SizedBox(height: AkeliSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Groupe public'),
                  Switch(
                    value: _isPublic,
                    onChanged: (val) => setState(() => _isPublic = val),
                  ),
                ],
              ),
              const SizedBox(height: AkeliSpacing.md),
              regionsAsync.when(
                data: (regions) => DropdownButtonFormField<String>(
                  initialValue: _regionId,
                  decoration: const InputDecoration(
                    labelText: 'Région culinaire',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Toutes les régions')),
                    ...regions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                  ],
                  onChanged: (v) => setState(() => _regionId = v),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Erreur régions'),
              ),
              const SizedBox(height: AkeliSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _language,
                decoration: const InputDecoration(
                  labelText: 'Langue principale',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Peu importe')),
                  ..._languages.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                ],
                onChanged: (v) => setState(() => _language = v),
              ),
              const SizedBox(height: AkeliSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _topic,
                decoration: const InputDecoration(
                  labelText: 'Sujet principal',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Général')),
                  ..._topics.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                ],
                onChanged: (v) => setState(() => _topic = v),
              ),
              const SizedBox(height: AkeliSpacing.md),
              TextFormField(
                controller: _maxMembersController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nombre maximum de membres',
                  hintText: 'Laisser vide pour illimité',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AkeliSpacing.xl),
              if (_errorMsg != null) ...[
                Text(
                  _errorMsg!,
                  style: const TextStyle(color: AkeliColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AkeliSpacing.md),
              ],
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Enregistrer'),
              ),
              const SizedBox(height: AkeliSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
