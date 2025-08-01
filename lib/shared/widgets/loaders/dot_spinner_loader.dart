import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom loading animation widget that mimics the style of item #16 from CSS Loaders.
/// This is a spinner with multiple dots that rotate and pulse.
class DotSpinnerLoader extends StatefulWidget {
  /// The size of the loader.
  final double size;

  /// The color of the dots. If null, the secondary color from the theme will be used.
  final Color? color;

  /// The number of dots in the spinner.
  final int dotCount;

  /// The size of each dot.
  final double dotSize;

  /// The animation duration in milliseconds.
  final int animationDurationMs;

  const DotSpinnerLoader({
    super.key,
    this.size = 48.0,
    this.color,
    this.dotCount = 8,
    this.dotSize = 8.0,
    this.animationDurationMs = 1600,
  });

  @override
  State<DotSpinnerLoader> createState() => _DotSpinnerLoaderState();
}

class _DotSpinnerLoaderState extends State<DotSpinnerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animationDurationMs),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.secondary;
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _DotSpinnerPainter(
              animation: _controller,
              dotCount: widget.dotCount,
              dotSize: widget.dotSize,
              color: color,
            ),
            size: Size(widget.size, widget.size),
          );
        },
      ),
    );
  }
}

class _DotSpinnerPainter extends CustomPainter {
  final Animation<double> animation;
  final int dotCount;
  final double dotSize;
  final Color color;

  _DotSpinnerPainter({
    required this.animation,
    required this.dotCount,
    required this.dotSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - dotSize) / 2;
    
    // Draw each dot
    for (int i = 0; i < dotCount; i++) {
      final double angle = (i / dotCount) * 2 * math.pi;
      
      // Calculate the position of the dot
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);
      
      // Calculate the opacity based on the animation and dot position
      // This creates a wave effect where each dot fades in and out in sequence
      final double dotPhase = (i / dotCount);
      final double opacity = math.sin(
        (animation.value * 2 * math.pi) + (dotPhase * 2 * math.pi)
      ) * 0.5 + 0.5;
      
      // Calculate the dot size based on the animation and dot position
      // This creates a pulsing effect
      final double scale = 0.5 + (0.5 * opacity);
      final double currentDotSize = dotSize * scale;
      
      // Draw the dot
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x, y),
        currentDotSize / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DotSpinnerPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value ||
        dotCount != oldDelegate.dotCount ||
        dotSize != oldDelegate.dotSize ||
        color != oldDelegate.color;
  }
}