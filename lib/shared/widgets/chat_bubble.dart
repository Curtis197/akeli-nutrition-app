import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/router.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/recipe_provider.dart';

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

// ── Text ─────────────────────────────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  final String text;
  final bool isSent;
  final String? senderName;

  const _TextBubble({required this.text, required this.isSent, this.senderName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: _bubbleDecoration(isSent),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (senderName != null) ...[
            Text(
              senderName!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AkeliColors.primary,
                  ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AkeliColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Image ─────────────────────────────────────────────────────────────────────

class _ImageBubble extends StatelessWidget {
  final String url;
  final bool isSent;
  final String? senderName;
  final String? caption;

  const _ImageBubble({required this.url, required this.isSent, this.senderName, this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _bubbleDecoration(isSent),
      clipBehavior: Clip.hardEdge,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260, minWidth: 150),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (senderName != null)
                Container(
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
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 200,
                  color: AkeliColors.surfaceContainer,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 100,
                  color: AkeliColors.surfaceContainer,
                  child: const Icon(Icons.broken_image_outlined, color: AkeliColors.outline),
                ),
              ),
              if (caption != null && caption!.isNotEmpty)
                Container(
                  color: AkeliColors.surfaceContainer,
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
        ),
      ),
    );
  }
}

// ── Recipe share ─────────────────────────────────────────────────────────────

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
        appLogger.userAction('Recipe share tapped', screen: 'ChatBubble', metadata: {'recipeId': recipeId});
        context.push(AkeliRoutes.recipeDetailPath(recipeId));
      },
      child: Container(
        decoration: _bubbleDecoration(isSent),
        clipBehavior: Clip.hardEdge,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260, minWidth: 180),
          child: IntrinsicWidth(
            child: recipeAsync.when(
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Recette introuvable',
                  style: TextStyle(color: AkeliColors.textSecondary, fontSize: 13),
                ),
              ),
              data: (recipe) {
                if (recipe == null) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Recette supprimée',
                        style: TextStyle(color: AkeliColors.textSecondary, fontSize: 13)),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          height: 110,
                          color: AkeliColors.surfaceContainer,
                          child: const Icon(Icons.restaurant, color: AkeliColors.outline),
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
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: Row(
                        children: [
                          if (recipe.calories100g != null) ...[
                            const Icon(Icons.local_fire_department_rounded,
                                size: 13, color: AkeliColors.secondary),
                            const SizedBox(width: 3),
                            Text(
                              '${recipe.calories100g!.round()} kcal/100g',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AkeliColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Spacer(),
                          Text(
                            'Voir →',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AkeliColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (caption != null && caption!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
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
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

BoxDecoration _bubbleDecoration(bool isSent) => BoxDecoration(
      color: isSent ? AkeliColors.info.withValues(alpha: 0.15) : AkeliColors.surface,
      boxShadow: isSent ? null : const [AkeliShadows.sm],
      borderRadius: _bubbleBorderRadius(isSent),
    );

BorderRadius _bubbleBorderRadius(bool isSent) => isSent
    ? const BorderRadius.only(
        topLeft: Radius.circular(AkeliRadius.md),
        topRight: Radius.circular(AkeliRadius.md),
        bottomLeft: Radius.circular(AkeliRadius.md),
        bottomRight: Radius.circular(0),
      )
    : const BorderRadius.only(
        topLeft: Radius.circular(AkeliRadius.md),
        topRight: Radius.circular(AkeliRadius.md),
        bottomLeft: Radius.circular(0),
        bottomRight: Radius.circular(AkeliRadius.md),
      );
