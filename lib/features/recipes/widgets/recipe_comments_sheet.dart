import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;


import '../../../core/theme.dart';
import '../../../providers/recipe_comment_provider.dart';
import '../../../shared/models/recipe_comment.dart';
import '../../../shared/widgets/avatar.dart';

class RecipeCommentsSheet extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeCommentsSheet({
    super.key,
    required this.recipeId,
  });

  @override
  ConsumerState<RecipeCommentsSheet> createState() => _RecipeCommentsSheetState();
}

class _RecipeCommentsSheetState extends ConsumerState<RecipeCommentsSheet> {
  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(recipeCommentNotifierProvider(widget.recipeId));
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AkeliColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: bottomPadding > 0 ? bottomPadding + 16 : 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Commentaires',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AkeliColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
                color: AkeliColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Aucun commentaire pour le moment.\nSoyez le premier à donner votre avis !',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AkeliColors.onSurfaceVariant),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: comments.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: AkeliColors.outlineVariant,
                    height: 24,
                  ),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _CommentTile(comment: comment);
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('Erreur: $e', style: const TextStyle(color: AkeliColors.error)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final RecipeComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AkeliAvatar(
          imageUrl: comment.authorAvatarUrl,
          initials: comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : 'U',
          size: AvatarSize.sm,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    comment.authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.onSurface,
                    ),
                  ),
                  Text(
                    timeago.format(comment.createdAt, locale: 'fr'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AkeliColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (comment.rating != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < comment.rating! ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
              if (comment.content != null && comment.content!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  comment.content!,
                  style: const TextStyle(
                    color: AkeliColors.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
