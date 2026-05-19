import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/core/router.dart';
import 'package:akeli/shared/widgets/chat_bubble.dart';

class _ChatMessage {
  final String text;
  final String time;
  final bool isMine;
  final String senderName;
  final bool isRead;
  const _ChatMessage({required this.text, required this.time, required this.isMine, required this.senderName, this.isRead = false});
}

class GroupChatPage extends StatefulWidget {
  final String groupId;
  const GroupChatPage({super.key, required this.groupId});
  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final _controller = TextEditingController();
  late List<_ChatMessage> _messages;
  final _logger = appLogger;

  @override
  void initState() {
    super.initState();
    _logger.provider('GroupChatPage initState() | groupId: ${widget.groupId}');
    _messages = [
      const _ChatMessage(text: 'Bonjour tout le monde !', time: '09:00', isMine: false, senderName: 'Marie'),
      const _ChatMessage(text: 'Salut Marie ! Comment ça va ?', time: '09:02', isMine: true, senderName: 'Moi', isRead: true),
      const _ChatMessage(text: "J'ai essay\u00e9 la recette de quinoa, excellent !", time: '09:05', isMine: false, senderName: 'Jean'),
      const _ChatMessage(text: 'Super ! Je vais la tester ce soir.', time: '09:07', isMine: true, senderName: 'Moi', isRead: true),
      const _ChatMessage(text: 'Qui cuisine ce week-end ?', time: '09:10', isMine: false, senderName: 'Sophie'),
      const _ChatMessage(text: 'Moi ! Je prépare une salade césar.', time: '09:12', isMine: true, senderName: 'Moi', isRead: false),
    ];
  }

  @override
  void dispose() {
    _logger.provider('GroupChatPage disposed | groupId: ${widget.groupId}');
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    _logger.userAction('Message sent', screen: 'GroupChatPage', metadata: {'groupId': widget.groupId, 'contentLength': text.length});
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, time: 'maintenant', isMine: true, senderName: 'Moi', isRead: false));
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('GroupChatPage build() | groupId: ${widget.groupId} | messageCount: ${_messages.length}');
    final reversed = _messages.reversed.toList();
    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: AkeliColors.background, elevation: 0,
        leading: const BackButton(),
        title: const Text('Discussion du groupe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _logger.userAction('Group info tapped', screen: 'GroupChatPage');
              context.go(AkeliRoutes.groupDetailPath(widget.groupId));
            },
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(AkeliSpacing.md),
            itemCount: reversed.length,
            itemBuilder: (context, i) {
              final msg = reversed[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AkeliSpacing.sm),
                child: AkeliChatBubble(
                  message: msg.text, time: msg.time, isSent: msg.isMine,
                  senderName: msg.isMine ? null : msg.senderName, isRead: msg.isRead,
                ),
              );
            },
          ),
        ),
        Container(
          color: AkeliColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md, vertical: AkeliSpacing.sm),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) { _logger.userAction('Message submitted via keyboard', screen: 'GroupChatPage'); _sendMessage(); },
              decoration: InputDecoration(
                hintText: 'Écrire un message…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AkeliRadius.pill)),
                contentPadding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md, vertical: AkeliSpacing.sm),
              ),
            )),
            const SizedBox(width: AkeliSpacing.sm),
            IconButton(icon: const Icon(Icons.send), color: AkeliColors.primary, onPressed: () { _logger.userAction('Send message button tapped', screen: 'GroupChatPage'); _sendMessage(); }),
          ]),
        ),
      ]),
    );
  }
}
