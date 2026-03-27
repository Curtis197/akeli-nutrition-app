// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// ============================================
// TYPING INDICATOR WIDGET - Style WhatsApp
// Pour FlutterFlow Custom Widget
// ============================================

class TypingIndicatorWidget extends StatefulWidget {
  const TypingIndicatorWidget({
    Key? key,
    this.width,
    this.height,
    this.dotColor = const Color(0xFF3BB78F), // Couleur Akeli par défaut
    this.dotSize = 8.0,
    this.spacing = 4.0,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  }) : super(key: key);

  // FlutterFlow parameters
  final double? width;
  final double? height;
  final Color dotColor;
  final double dotSize;
  final double spacing;
  final Color backgroundColor;
  final EdgeInsets padding;

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();

    // ────────────────────────────────────────
    // ANIMATION CONTROLLERS (effet vague)
    // ────────────────────────────────────────

    // Dot 1
    _controller1 = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _animation1 = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(
        parent: _controller1,
        curve: Curves.easeInOut,
      ),
    );

    // Dot 2 (décalé de 200ms)
    _controller2 = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _controller2.repeat(reverse: true);
      }
    });

    _animation2 = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(
        parent: _controller2,
        curve: Curves.easeInOut,
      ),
    );

    // Dot 3 (décalé de 400ms)
    _controller3 = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _controller3.repeat(reverse: true);
      }
    });

    _animation3 = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(
        parent: _controller3,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: widget.padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Dot 1
          AnimatedBuilder(
            animation: _animation1,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _animation1.value),
                child: _buildDot(),
              );
            },
          ),

          SizedBox(width: widget.spacing),

          // Dot 2
          AnimatedBuilder(
            animation: _animation2,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _animation2.value),
                child: _buildDot(),
              );
            },
          ),

          SizedBox(width: widget.spacing),

          // Dot 3
          AnimatedBuilder(
            animation: _animation3,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _animation3.value),
                child: _buildDot(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: widget.dotSize,
      height: widget.dotSize,
      decoration: BoxDecoration(
        color: widget.dotColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
