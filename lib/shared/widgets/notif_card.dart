import 'package:flutter/material.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/shared/widgets/avatar.dart';

enum NotifType { chat, meal, request }

class AkeliNotifCard extends StatelessWidget {
  final NotifType type;
  final String title;
  final String subtitle;
  final String time;
  final String? avatarUrl;
  final String? emoji;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const AkeliNotifCard({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    this.avatarUrl,
    this.emoji,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AkeliColors.surface,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildContent(context),
          const Divider(height: 1, thickness: 1),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (type) {
      case NotifType.chat:
        return _ChatVariant(card: this);
      case NotifType.meal:
        return _MealVariant(card: this);
      case NotifType.request:
        return _RequestVariant(card: this);
    }
  }
}

class _ChatVariant extends StatelessWidget {
  final AkeliNotifCard card;
  const _ChatVariant({required this.card});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AkeliAvatar(imageUrl: card.avatarUrl, size: AvatarSize.sm),
        const SizedBox(width: AkeliSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.primary,
                    ),
              ),
              Text(
                card.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AkeliColors.textSecondary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          card.time,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AkeliColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _MealVariant extends StatelessWidget {
  final AkeliNotifCard card;
  const _MealVariant({required this.card});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AkeliColors.background,
            borderRadius: BorderRadius.circular(AkeliRadius.md),
          ),
          child: Center(
            child: Text(
              card.emoji ?? '',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(width: AkeliSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.textPrimary,
                    ),
              ),
              Text(
                card.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AkeliColors.textSecondary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          card.time,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AkeliColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _RequestVariant extends StatelessWidget {
  final AkeliNotifCard card;
  const _RequestVariant({required this.card});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AkeliAvatar(imageUrl: card.avatarUrl, size: AvatarSize.md),
        const SizedBox(width: AkeliSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                card.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AkeliColors.textSecondary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AkeliSpacing.xs),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: card.onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AkeliColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AkeliSpacing.sm,
                          vertical: AkeliSpacing.xs),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AkeliRadius.pill)),
                    ),
                    child: const Text('Accept'),
                  ),
                  const SizedBox(width: AkeliSpacing.sm),
                  OutlinedButton(
                    onPressed: card.onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AkeliColors.textSecondary,
                      side: const BorderSide(color: AkeliColors.textSecondary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AkeliSpacing.sm,
                          vertical: AkeliSpacing.xs),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AkeliRadius.pill)),
                    ),
                    child: const Text('Decline'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
