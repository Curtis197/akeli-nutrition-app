import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logger.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/mode_provider.dart';

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
  List<ChatMessage> build() {
    appLogger.provider('AiChatNotifier build()');
    ref.onDispose(() => appLogger.provider('AiChatNotifier disposed'));
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

    final client = ref.read(supabaseClientProvider);
    final currentMode = ref.read(currentModeProvider);
    final body = <String, dynamic>{
      'message': content.trim(),
      if (_conversationId != null) 'conversation_id': _conversationId,
      'mode': currentMode.name,
    };

    appLogger.edge('ai-assistant-chat', 'BEFORE | mode: ${currentMode.name} | conversationId: ${_conversationId ?? "new"} | messageLength: ${content.trim().length}');

    try {
      final result = await client.functions.invoke(
        'ai-assistant-chat',
        body: body,
      );

      final data = result.data as Map<String, dynamic>;
      _conversationId = data['conversation_id'] as String?;
      final reply = data['response'] as String;

      appLogger.edge('ai-assistant-chat', 'AFTER | conversationId: $_conversationId | pathType: ${data['path_type']} | tokens: ${data['tokens_used']}');

      state = [
        ...state.where((m) => !m.isLoading),
        ChatMessage(
          id: 'assistant_${DateTime.now().millisecondsSinceEpoch}',
          role: 'assistant',
          content: reply,
          createdAt: DateTime.now(),
        ),
      ];
      appLogger.provider('AiChatNotifier → data | messages: ${state.length}');
    } catch (e, st) {
      appLogger.edge('ai-assistant-chat', 'ERROR | $e', error: e, stackTrace: st);
      appLogger.provider('AiChatNotifier → error | $e');
      state = [
        ...state.where((m) => !m.isLoading),
        ChatMessage(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          role: 'assistant',
          content: '__error__',
          createdAt: DateTime.now(),
        ),
      ];
    }
  }

  void clear() {
    appLogger.provider('AiChatNotifier clear()');
    _conversationId = null;
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
    final l10n = AppLocalizations.of(context);

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
                    child: Icon(Icons.auto_awesome_rounded, color: getAppModeColor(ref.watch(currentModeProvider))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ref.watch(currentModeProvider) == AppMode.beauty ? l10n.aiAssistantBeautyTitle : l10n.aiAssistantTitle,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AkeliColors.onSurface, letterSpacing: -0.5),
                        ),
                        Text(
                          l10n.aiAssistantOnline,
                          style: TextStyle(fontSize: 12, color: getAppModeColor(ref.watch(currentModeProvider)), letterSpacing: 0.5),
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
                      tooltip: l10n.aiAssistantNewConversation,
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
                  suggestions: ref.watch(currentModeProvider) == AppMode.beauty
                      ? [
                          l10n.aiAssistantBeautySuggestion1,
                          l10n.aiAssistantBeautySuggestion2,
                          l10n.aiAssistantBeautySuggestion3,
                          l10n.aiAssistantBeautySuggestion4,
                        ]
                      : [
                          l10n.aiAssistantSuggestion1,
                          l10n.aiAssistantSuggestion2,
                          l10n.aiAssistantSuggestion3,
                          l10n.aiAssistantSuggestion4,
                        ],
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
                          child: Text(
                            l10n.aiAssistantToday,
                            style: const TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant, fontWeight: FontWeight.bold, letterSpacing: 1.5),
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
                                  decoration: InputDecoration(
                                    hintText: l10n.aiAssistantMessageHint,
                                    hintStyle: const TextStyle(color: AkeliColors.onSurfaceVariant),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
  final List<String> suggestions;

  const _WelcomeView({required this.onSuggestion, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    appLogger.d('WelcomeView build()');
    final l10n = AppLocalizations.of(context);
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
          Text(
            l10n.aiAssistantWelcomeTitle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AkeliColors.onSurface, letterSpacing: -0.5, height: 1.2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.aiAssistantWelcomeSubtitle,
            style: const TextStyle(fontSize: 16, color: AkeliColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.aiAssistantSuggestions,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AkeliColors.onSurfaceVariant, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          ...suggestions.map(
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
    final displayContent = message.content == '__error__'
        ? AppLocalizations.of(context).aiAssistantError
        : message.content;

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
                          displayContent,
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

