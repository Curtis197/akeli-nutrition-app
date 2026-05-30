import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../providers/dm_provider.dart';
import '../../shared/widgets/chat_bubble.dart';

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

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: AkeliColors.background,
        elevation: 0,
        leading: const BackButton(),
        title: Text(appBarTitle),
        actions: [
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
