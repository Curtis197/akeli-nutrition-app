import 'package:flutter/material.dart';
import 'package:akeli/core/theme.dart';

// ---------------------------------------------------------------------------
// AvatarSize
// ---------------------------------------------------------------------------

enum AvatarSize { sm, md, lg }

extension AvatarSizeValue on AvatarSize {
  double get pixels {
    switch (this) {
      case AvatarSize.sm:
        return 32;
      case AvatarSize.md:
        return 48;
      case AvatarSize.lg:
        return 80;
    }
  }
}

// ---------------------------------------------------------------------------
// AkeliAvatar
// ---------------------------------------------------------------------------

class AkeliAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final AvatarSize size;
  final Color? borderColor;

  const AkeliAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = AvatarSize.md,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final diameter = size.pixels;
    final fontSize = diameter * 0.35;

    Widget avatar = CircleAvatar(
      radius: diameter / 2,
      backgroundColor: AkeliColors.primary,
      backgroundImage:
          imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null && initials != null
          ? Text(
              initials!,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            )
          : null,
    );

    if (borderColor != null) {
      avatar = Container(
        width: diameter + 4,
        height: diameter + 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor!, width: 2),
        ),
        child: ClipOval(child: avatar),
      );
    }

    return avatar;
  }
}
