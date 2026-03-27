import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:akeli/core/theme.dart';

// ---------------------------------------------------------------------------
// AkeliModernMetric
// ---------------------------------------------------------------------------

class AkeliModernMetric extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final double progress;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;

  const AkeliModernMetric({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.progress,
    this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final colors = gradientColors ??
        [
          AkeliColors.primary.withValues(alpha: 0.3),
          AkeliColors.primary,
        ];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (rect) {
                    return SweepGradient(
                      startAngle: -math.pi / 2,
                      endAngle: (math.pi * 2) - (math.pi / 2),
                      colors: colors,
                      stops: const [0.0, 1.0],
                      transform: GradientRotation(-math.pi / 2),
                    ).createShader(rect);
                  },
                  child: CustomPaint(
                    size: const Size(80, 80),
                    painter: _ProgressPainter(
                      progress: clampedProgress,
                      strokeWidth: 8,
                      isActiveColor: true,
                    ),
                  ),
                ),
                // Background Track
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _ProgressPainter(
                    progress: 1.0,
                    strokeWidth: 8,
                    isActiveColor: false,
                    color: AkeliColors.surfaceContainerHigh,
                  ),
                ),
                // Inner Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                    if (unit != null)
                      Text(
                        unit!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AkeliColors.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AkeliSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AkeliColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final bool isActiveColor;
  final Color? color;

  _ProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.isActiveColor,
    this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (!isActiveColor) {
      paint.color = color ?? Colors.grey.withValues(alpha: 0.1);
      canvas.drawCircle(center, radius, paint);
    } else {
      paint.color = Colors.white; // Placeholder for ShaderMask
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
