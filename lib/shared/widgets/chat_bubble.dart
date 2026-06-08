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

  const AkeliChatBubble({
    super.key,
    required this.message,
    required this.time,
    required this.isSent,
    this.senderName,
    this.isRead = false,
    this.messageType = 'text',
    this.recipeId,
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
            if (senderName != null) ...[
              Text(
                senderName!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.primary,
                    ),
              ),
              const SizedBox(height: 2),
            ],
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
      'image'        => _ImageBubble(url: message, isSent: isSent),
      'recipe_share' => _RecipeBubble(recipeId: recipeId ?? message, isSent: isSent, ref: ref, context: context),
      _              => _TextBubble(text: message, isSent: isSent),
    };
  }
}

// ── Text ─────────────────────────────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  final String text;
  final bool isSent;

  const _TextBubble({required this.text, required this.isSent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: _bubbleDecoration(isSent),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AkeliColors.textPrimary,
            ),
      ),
    );
  }
}

// ── Image ─────────────────────────────────────────────────────────────────────

class _ImageBubble extends StatelessWidget {
  final String url;
  final bool isSent;

  const _ImageBubble({required this.url, required this.isSent});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _bubbleBorderRadius(isSent),
      child: CachedNetworkImage(
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
    );
  }
}

// ── Recipe share ─────────────────────────────────────────────────────────────

class _RecipeBubble extends StatelessWidget {
  final String recipeId;
  final bool isSent;
  final WidgetRef ref;
  final BuildContext context;

  const _RecipeBubble({
    required this.recipeId,
    required this.isSent,
    required this.ref,
    required this.context,
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
                    style: TextStyle(color: AkeliColors.textSecondary, fontSize: 13)),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (recipe.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: recipe.thumbnailUrl!,
                    height: 110,
                    width: double.infinity,
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
                      if (recipe.calories != null) ...[
                        const Icon(Icons.local_fire_department_rounded,
                            size: 13, color: AkeliColors.secondary),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.calories!.round()} kcal',
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
              ],
            );
          },
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
