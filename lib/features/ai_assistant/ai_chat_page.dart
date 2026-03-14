import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class ChatMessage {
  final String id;
  final String role; // user / assistant
  final String content;
  final DateTime createdAt;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isLoading = false,
  });
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

class AiChatNotifier extends AutoDisposeNotifier<List<ChatMessage>> {
  String? _conversationId;

  @override
  List<ChatMessage> build() => [];

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    final loadingMsg = ChatMessage(
      id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
      role: 'assistant',
      content: '',
      createdAt: DateTime.now(),
      isLoading: true,
    );

    state = [...state, userMsg, loadingMsg];

    try {
      final res = await supabase.functions.invoke(
        'ai-assistant-chat',
        body: {
          'message': content.trim(),
          if (_conversationId != null) 'conversation_id': _conversationId,
        },
      );

      final data = res.data as Map<String, dynamic>;
      _conversationId = data['conversation_id'] as String?;
      final reply = data['reply'] as String? ?? 'Désolé, je n\'ai pas compris.';

      final assistantMsg = ChatMessage(
        id: data['message_id'] as String? ??
            'assistant_${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        content: reply,
        createdAt: DateTime.now(),
      );

      // Replace loading with actual response
      state = [
        ...state.where((m) => !m.isLoading),
        assistantMsg,
      ];
    } catch (e) {
      state = [
        ...state.where((m) => !m.isLoading),
        ChatMessage(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          role: 'assistant',
          content: 'Désolé, une erreur est survenue. Réessayez dans un moment.',
          createdAt: DateTime.now(),
        ),
      ];
    }
  }

  void clear() {
    state = [];
    _conversationId = null;
  }
}

final aiChatProvider =
    NotifierProvider.autoDispose<AiChatNotifier, List<ChatMessage>>(
        AiChatNotifier.new);

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    await ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(aiChatProvider);
    final hasLoading = messages.any((m) => m.isLoading);

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: AkeliColors.background,
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AkeliColors.primary,
              child:
                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            ),
            SizedBox(width: AkeliSpacing.sm),
            Text('Assistant Akeli'),
          ],
        ),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                ref.read(aiChatProvider.notifier).clear();
              },
              tooltip: 'Nouvelle conversation',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _WelcomeView(
                    onSuggestion: (s) {
                      _inputCtrl.text = s;
                      _sendMessage();
                    },
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(AkeliSpacing.md),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final msg = messages[i];
                      return _MessageBubble(message: msg);
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
              border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: InputDecoration(
                      hintText: 'Posez votre question nutritionnelle...',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AkeliRadius.full),
                        borderSide:
                            const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AkeliRadius.full),
                        borderSide:
                            const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AkeliSpacing.md,
                          vertical: AkeliSpacing.sm),
                      filled: true,
                      fillColor: AkeliColors.background,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: AkeliSpacing.xs),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: FilledButton(
                    onPressed: hasLoading ? null : _sendMessage,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      maximumSize: const Size(48, 48),
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                    ),
                    child: hasLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  final void Function(String) onSuggestion;

  const _WelcomeView({required this.onSuggestion});

  static const _suggestions = [
    'Quels aliments riches en protéines pour ma culture ?',
    'Quel est mon apport calorique recommandé ?',
    'Comment perdre du poids avec la cuisine africaine ?',
    'Donne-moi une recette pour ce soir.',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AkeliSpacing.xl),
          const CircleAvatar(
            radius: 36,
            backgroundColor: AkeliColors.primary,
            child: Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: AkeliSpacing.lg),
          Text(
            'Bonjour, je suis votre assistant nutritionnel Akeli.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AkeliSpacing.sm),
          Text(
            'Posez-moi vos questions sur la nutrition, les recettes africaines ou votre plan alimentaire.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AkeliColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AkeliSpacing.xl),
          Text('Suggestions',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AkeliSpacing.md),
          ..._suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: AkeliSpacing.sm),
              child: InkWell(
                onTap: () => onSuggestion(s),
                borderRadius: BorderRadius.circular(AkeliRadius.md),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AkeliSpacing.md),
                  decoration: BoxDecoration(
                    color: AkeliColors.surface,
                    borderRadius: BorderRadius.circular(AkeliRadius.md),
                    border:
                        Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          size: 16, color: AkeliColors.secondary),
                      const SizedBox(width: AkeliSpacing.sm),
                      Expanded(
                        child: Text(s,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AkeliColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: AkeliSpacing.sm),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AkeliColors.primary,
              child: Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 14),
            ),
            const SizedBox(width: AkeliSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AkeliSpacing.md,
                vertical: AkeliSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isUser ? AkeliColors.primary : AkeliColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AkeliRadius.md),
                  topRight: const Radius.circular(AkeliRadius.md),
                  bottomLeft:
                      Radius.circular(isUser ? AkeliRadius.md : 4),
                  bottomRight:
                      Radius.circular(isUser ? 4 : AkeliRadius.md),
                ),
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFFE0E0E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.isLoading
                  ? const _TypingIndicator()
                  : Text(
                      message.content,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : AkeliColors.textPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AkeliSpacing.sm),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AkeliColors.secondary,
              child: Icon(Icons.person_rounded,
                  color: Colors.white, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(
          reverse: true,
          period: Duration(milliseconds: 600 + i * 150),
        ),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Transform.translate(
              offset: Offset(0, -4 * _animations[i].value),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AkeliColors.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
