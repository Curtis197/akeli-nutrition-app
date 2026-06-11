import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../shared/models/creator.dart';

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
      onTap: onTap,
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
            _avatar(),
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

  Widget _avatar() {
    if (creator.avatarUrl != null && creator.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: CachedNetworkImageProvider(creator.avatarUrl!),
      );
    }
    final initial = creator.displayName.isNotEmpty
        ? creator.displayName[0].toUpperCase()
        : '?';
    return CircleAvatar(
      radius: 28,
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
