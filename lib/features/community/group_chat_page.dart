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
import '../../providers/food_region_provider.dart';
import '../../shared/widgets/chat_bubble.dart';
import '../../shared/widgets/avatar.dart';

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

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || _resolvedConversationId == null) return;
    _logger.userAction('Message sent', screen: 'GroupChatPage', metadata: {
      'conversationId': _resolvedConversationId,
      'groupId': widget.groupId,
      'length': text.length,
    });
    _controller.clear();
    sendMessage(ref, _resolvedConversationId!, text).then((_) {
      if (widget.groupId != null) {
        _notifyGroupMembers(widget.groupId!, text);
      }
    }).catchError((e) {
      _logger.db('ERROR | sendMessage | $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'envoi")),
        );
      }
    });
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
                        if (groupDetails.valueOrNull?['description'] != null &&
                            (groupDetails.valueOrNull!['description'] as String).trim().isNotEmpty)
                          Text(
                            groupDetails.valueOrNull!['description'] as String,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AkeliColors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                        senderName: msg.isMine ? null : msg.senderName,
                        isRead: false,
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
                horizontal: AkeliSpacing.md, vertical: AkeliSpacing.sm),
            child: Row(
              children: [
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
                const SizedBox(width: AkeliSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.send_rounded),
                  color: AkeliColors.primary,
                  onPressed: () {
                    _logger.userAction('Send button tapped',
                        screen: 'GroupChatPage');
                    _sendMessage();
                  },
                ),
              ],
            ),
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
    'cuisine_africaine': 'Cuisine Africaine', 'batch_cooking': 'Batch Cooking',
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
