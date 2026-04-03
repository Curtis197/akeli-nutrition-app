import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// A premium glassmorphic AppBar following the "Organic Editorial" system.
/// Uses [BackdropFilter] for a 20px blur with a 70% opacity surface background.
class AkeliGlassHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final double height;

  const AkeliGlassHeader({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.showBackButton = true,
    this.height = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height + MediaQuery.paddingOf(context).top,
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top,
            left: AkeliSpacing.lg,
            right: AkeliSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AkeliColors.surface.withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(
                color: AkeliColors.onSurface.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              if (leading != null)
                leading!
              else if (showBackButton && Navigator.canPop(context))
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: AkeliColors.onSurface,
                ),
              if (title != null) ...[
                const SizedBox(width: AkeliSpacing.md),
                Expanded(
                  child: Text(
                    title!,
                    style: AkeliTypography.titleLarge.copyWith(
                      color: AkeliColors.onSurface,
                    ),
                  ),
                ),
              ],
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}

/// Typography helper for internal use if not globally defined
abstract class AkeliTypography {
  static TextStyle get titleLarge => const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01,
      );
}
