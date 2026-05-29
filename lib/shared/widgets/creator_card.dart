// lib/shared/widgets/creator_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/shared/models/creator.dart';

class CreatorCard extends StatelessWidget {
  final Creator creator;
  final String? regionName;
  final VoidCallback? onTap;

  const CreatorCard({
    super.key,
    required this.creator,
    this.regionName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        appLogger.userAction('CreatorCard tapped', screen: 'CreatorCard',
            metadata: {'creatorId': creator.id});
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AkeliSpacing.md, vertical: AkeliSpacing.xs),
        padding: const EdgeInsets.all(AkeliSpacing.md),
        decoration: BoxDecoration(
          color: AkeliColors.surface,
          borderRadius: BorderRadius.circular(AkeliRadius.xl),
          border:
              Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: const [AkeliShadows.sm],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(avatarUrl: creator.avatarUrl, displayName: creator.displayName),
            const SizedBox(width: AkeliSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          creator.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (regionName != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AkeliColors.primaryContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            regionName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AkeliColors.onPrimaryContainer),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (creator.bio != null && creator.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      creator.bio!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AkeliColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${creator.recipeCount} recette${creator.recipeCount != 1 ? 's' : ''}',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: AkeliColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AkeliColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;

  const _Avatar({required this.avatarUrl, required this.displayName});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: CachedNetworkImageProvider(avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: AkeliColors.primaryContainer,
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(color: AkeliColors.onPrimaryContainer),
      ),
    );
  }
}
