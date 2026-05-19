import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class AkeliGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final Widget? trailing;

  const AkeliGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 56,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isGhostMode = onPressed == null && !isLoading;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AkeliRadius.xl),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(AkeliRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isGhostMode
                ? null
                : const LinearGradient(
                    colors: [AkeliColors.primary, AkeliColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: isGhostMode ? AkeliColors.surfaceContainerHighest : null,
            borderRadius: BorderRadius.circular(AkeliRadius.xl),
            boxShadow: isGhostMode
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x3300504A),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
          ),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Center(
              child: isLoading
                  ? Semantics(
                      label: 'Chargement en cours',
                      child: const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isGhostMode
                                ? AkeliColors.outline
                                : Colors.white,
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 8),
                          trailing!,
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
