import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final communityGroupsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.watch(currentUserProvider);
  final data = await supabase
      .from('community_group')
      .select('*, group_member(count)')
      .eq('is_public', true)
      .order('member_count', ascending: false)
      .limit(20);
  return (data as List<dynamic>).cast<Map<String, dynamic>>();
});

final groupMessagesProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, groupId) {
  return supabase
      .from('chat_message')
      .stream(primaryKey: ['id'])
      .eq('group_id', groupId)
      .order('created_at')
      .limit(50)
      .map((list) => list.cast<Map<String, dynamic>>());
});

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  String? _selectedGroupId;
  String? _selectedGroupName;

  @override
  Widget build(BuildContext context) {
    if (_selectedGroupId != null) {
      return _GroupChatView(
        groupId: _selectedGroupId!,
        groupName: _selectedGroupName ?? 'Groupe',
        onBack: () => setState(() {
          _selectedGroupId = null;
          _selectedGroupName = null;
        }),
      );
    }

    return _GroupListView(
      onGroupSelected: (id, name) => setState(() {
        _selectedGroupId = id;
        _selectedGroupName = name;
      }),
    );
  }
}

class _GroupListView extends ConsumerWidget {
  final void Function(String id, String name) onGroupSelected;

  const _GroupListView({required this.onGroupSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(communityGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Communauté')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Text('Aucun groupe disponible pour le moment.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AkeliSpacing.md),
            itemCount: groups.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AkeliSpacing.sm),
            itemBuilder: (context, i) {
              final group = groups[i];
              final memberCount =
                  (group['member_count'] as int?) ?? 0;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AkeliColors.primary.withOpacity(0.15),
                    backgroundImage: group['cover_url'] != null
                        ? NetworkImage(group['cover_url'] as String)
                        : null,
                    child: group['cover_url'] == null
                        ? const Icon(Icons.people_rounded,
                            color: AkeliColors.primary)
                        : null,
                  ),
                  title: Text(group['name'] as String,
                      style: Theme.of(context).textTheme.titleSmall),
                  subtitle: group['description'] != null
                      ? Text(
                          group['description'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline_rounded,
                          size: 14, color: AkeliColors.textSecondary),
                      Text(
                        '$memberCount',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AkeliColors.textSecondary),
                      ),
                    ],
                  ),
                  onTap: () => onGroupSelected(
                    group['id'] as String,
                    group['name'] as String,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _GroupChatView extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  final VoidCallback onBack;

  const _GroupChatView({
    required this.groupId,
    required this.groupName,
    required this.onBack,
  });

  @override
  ConsumerState<_GroupChatView> createState() => _GroupChatViewState();
}

class _GroupChatViewState extends ConsumerState<_GroupChatView> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _sending = true);
    try {
      await supabase.from('chat_message').insert({
        'group_id': widget.groupId,
        'sender_id': user.id,
        'content': text,
        'content_type': 'text',
      });
      _messageCtrl.clear();
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(groupMessagesProvider(widget.groupId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: widget.onBack),
        title: Text(widget.groupName),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Erreur: $err')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun message. Soyez le premier !',
                      style: TextStyle(color: AkeliColors.textSecondary),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(
                        _scrollCtrl.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(AkeliSpacing.md),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe =
                        msg['sender_id'] == currentUser?.id;
                    return _MessageBubble(
                        message: msg, isMe: isMe);
                  },
                );
              },
            ),
          ),
          // Input area
          Container(
            padding: EdgeInsets.only(
              left: AkeliSpacing.md,
              right: AkeliSpacing.sm,
              top: AkeliSpacing.sm,
              bottom:
                  MediaQuery.of(context).padding.bottom + AkeliSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: AkeliColors.surface,
              border: Border(
                  top: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Votre message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: AkeliSpacing.md,
                          vertical: AkeliSpacing.sm),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded,
                          color: AkeliColors.primary),
                  onPressed: _sending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final content = message['content'] as String? ?? '';
    final createdAt = message['created_at'] != null
        ? DateTime.parse(message['created_at'] as String).toLocal()
        : DateTime.now();
    final timeStr =
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AkeliSpacing.sm),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AkeliSpacing.md,
            vertical: AkeliSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isMe ? AkeliColors.primary : AkeliColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AkeliRadius.md),
              topRight: const Radius.circular(AkeliRadius.md),
              bottomLeft: Radius.circular(isMe ? AkeliRadius.md : 4),
              bottomRight: Radius.circular(isMe ? 4 : AkeliRadius.md),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                content,
                style: TextStyle(
                  color: isMe ? Colors.white : AkeliColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white70
                      : AkeliColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
