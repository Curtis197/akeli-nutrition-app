import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logger.dart';
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
  @override
  List<ChatMessage> build() {
    appLogger.provider('AiChatNotifier build()');
    return [];
  }

  Future<void> sendMessage(String content) async {
    appLogger.provider('AiChatNotifier sendMessage | content length: ${content.trim().length}');
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

    appLogger.provider('AiChatNotifier → loading (sending)');
    state = [...state, userMsg, loadingMsg];

    try {
      // Mocking AI response instead of calling Supabase
      await Future.delayed(const Duration(seconds: 2));
      
      String reply = "C'est une excellente question ! ";
      if (content.toLowerCase().contains('protéine')) {
        reply += "Pour un apport optimal en protéines dans la cuisine africaine, privilégiez le niébé (haricots), les arachides, ainsi que le poisson frais ou séché. Le fonio est aussi une excellente céréale complète.";
      } else if (content.toLowerCase().contains('calorique') || content.toLowerCase().contains('poids')) {
        reply += "Votre apport calorique idéal dépend de votre métabolisme de base. En général, on recommande une approche équilibrée riche en fibres (légumes feuilles comme le Bissap ou le Moringa) et modérée en huiles de palme ou d'arachide.";
      } else {
        reply += "En tant qu'assistant Akeli, je vous recommande de suivre votre plan de repas personnalisé dans l'onglet 'Planning' pour atteindre vos objectifs santé tout en savourant nos saveurs locales.";
      }
 
      final assistantMsg = ChatMessage(
        id: 'assistant_${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        content: reply,
        createdAt: DateTime.now(),
      );
 
      // Replace loading with actual response
      state = [
        ...state.where((m) => !m.isLoading),
        assistantMsg,
      ];
      appLogger.provider('AiChatNotifier → data | messages: ${state.length}');
    } catch (e) {
      appLogger.provider('AiChatNotifier → error | send failed | $e', error: e);
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
    appLogger.provider('AiChatNotifier clear()');
    state = [];
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
  final _logger = appLogger;

  @override
  void dispose() {
    _logger.provider('AiChatPage disposed');
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
    _logger.userAction('Send message tapped', screen: 'AiChatPage', metadata: {'contentLength': text.length});
    if (text.isEmpty) return;
    _inputCtrl.clear();
    await ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(aiChatProvider);
    final hasLoading = messages.any((m) => m.isLoading);
    _logger.provider('AiChatPage build() | messageCount: ${messages.length} | hasLoading: $hasLoading');

    return Scaffold(
      backgroundColor: AkeliColors.surface,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 16),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: AkeliColors.surface.withValues(alpha: 0.8),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 8,
                left: 16,
                right: 16,
              ),
              child: Row(
                children: [
                  const BackButton(color: AkeliColors.primary),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AkeliColors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: AkeliColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Assistant Akeli',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AkeliColors.onSurface, letterSpacing: -0.5),
                        ),
                        Text(
                          'En ligne',
                          style: TextStyle(fontSize: 12, color: AkeliColors.primary, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam, color: AkeliColors.onSurfaceVariant),
                    onPressed: () {},
                  ),
                  if (messages.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AkeliColors.onSurfaceVariant),
                      onPressed: () {
                        _logger.userAction('Clear conversation tapped', screen: 'AiChatPage');
                        ref.read(aiChatProvider.notifier).clear();
                      },
                      tooltip: 'Nouvelle conversation',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          messages.isEmpty
              ? _WelcomeView(
                  onSuggestion: (s) {
                    _inputCtrl.text = s;
                    _sendMessage();
                  },
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 32,
                    bottom: MediaQuery.of(context).padding.bottom + 120,
                    left: 16,
                    right: 16,
                  ),
                  itemCount: messages.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AkeliColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            "AUJOURD'HUI",
                            style: TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                        ),
                      );
                    }
                    final msg = messages[i - 1];
                    return _MessageBubble(message: msg);
                  },
                ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: AkeliColors.surface.withValues(alpha: 0.9),
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 32,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AkeliColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AkeliColors.onSurfaceVariant),
                                onPressed: () {},
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _inputCtrl,
                                  minLines: 1,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    hintText: 'Message...',
                                    hintStyle: TextStyle(color: AkeliColors.onSurfaceVariant),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  style: const TextStyle(fontSize: 16, color: AkeliColors.onSurface),
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) {
                                    _logger.userAction('Message submitted via keyboard', screen: 'AiChatPage');
                                    _sendMessage();
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.mood, color: AkeliColors.onSurfaceVariant),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AkeliColors.primary, AkeliColors.primaryContainer],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AkeliColors.primary.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: hasLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AkeliColors.onPrimary),
                                )
                              : const Icon(Icons.send, color: AkeliColors.onPrimary),
                          onPressed: hasLoading
                              ? null
                              : () {
                                  _logger.userAction('Send button tapped', screen: 'AiChatPage');
                                  _sendMessage();
                                },
                        ),
                      ),
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
    appLogger.d('WelcomeView build()');
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 64,
        left: 24,
        right: 24,
        bottom: 120,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AkeliColors.surfaceContainerLowest,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AkeliColors.primary, size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bonjour, je suis votre assistant nutritionnel Akeli.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AkeliColors.onSurface, letterSpacing: -0.5, height: 1.2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Posez-moi vos questions sur la nutrition, les recettes africaines ou votre plan alimentaire.',
            style: TextStyle(fontSize: 16, color: AkeliColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Suggestions',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AkeliColors.onSurfaceVariant, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          ..._suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  appLogger.userAction('Suggestion tapped', screen: 'AiChatPage', metadata: {'suggestion': s.substring(0, s.length > 30 ? 30 : s.length)});
                  onSuggestion(s);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, size: 20, color: AkeliColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(s, style: const TextStyle(fontSize: 15, color: AkeliColors.onSurface, fontWeight: FontWeight.w500)),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AkeliColors.onSurfaceVariant),
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
    final timeStr = "${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? null : AkeliColors.surfaceContainerLowest,
                gradient: isUser
                    ? const LinearGradient(
                        colors: [AkeliColors.primary, AkeliColors.primaryContainer],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: Radius.circular(isUser ? 24 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 24),
                ),
                boxShadow: [
                  if (!isUser)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  message.isLoading
                      ? const _TypingIndicator()
                      : Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: isUser ? AkeliColors.onPrimary : AkeliColors.onSurface,
                          ),
                        ),
                  if (!message.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: isUser ? AkeliColors.onPrimary.withValues(alpha: 0.7) : AkeliColors.onSurfaceVariant,
                            ),
                          ),
                          if (isUser) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.done_all, size: 14, color: AkeliColors.onPrimary.withValues(alpha: 0.7)),
                          ]
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
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
  final _logger = appLogger;

  @override
  void initState() {
    super.initState();
    _logger.provider('TypingIndicator initState()');
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
    _logger.provider('TypingIndicator disposed');
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (i) => AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.translate(
                offset: Offset(0, -4 * _animations[i].value),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AkeliColors.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

