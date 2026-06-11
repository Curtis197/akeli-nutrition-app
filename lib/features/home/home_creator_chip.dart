import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/shared/models/creator.dart';

class HomeCreatorChip extends StatelessWidget {
  final Creator creator;
  final VoidCallback? onTap;

  const HomeCreatorChip({
    super.key,
    required this.creator,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              appLogger.userAction(
                'HomeCreatorChip tapped',
                screen: 'HomeCreatorChip',
                metadata: {'creatorId': creator.id},
              );
              onTap!();
            },
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AkeliColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AkeliRadius.lg),
          boxShadow: const [AkeliShadows.sm],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ChipAvatar(avatarUrl: creator.avatarUrl, displayName: creator.displayName),
            const SizedBox(height: 6),
            Text(
              creator.displayName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AkeliColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;

  const _ChipAvatar({required this.avatarUrl, required this.displayName});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 32,
        backgroundImage: CachedNetworkImageProvider(avatarUrl!),
      );
    }
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 32,
      backgroundColor: AkeliColors.primaryContainer,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AkeliColors.onPrimaryContainer,
        ),
      ),
    );
  }
}
