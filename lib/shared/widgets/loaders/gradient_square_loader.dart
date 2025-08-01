import 'package:flutter/material.dart';

/// A custom loading animation widget that mimics the CSS animation from the reference.
/// This loader uses radial gradients in a 2x2 grid layout with specific colors and animations.
class GradientSquareLoader extends StatefulWidget {
  /// The size of the loader (width and height will be equal).
  final double size;

  /// The duration of one complete animation cycle in milliseconds.
  final int animationDurationMs;

  /// Custom colors for the gradients. If null, default colors will be used.
  final Color? color1; // Default: #F10C49 (pink)
  final Color? color2; // Default: #f4dd51 (yellow)
  final Color? color3; // Default: #e3aad6 (light purple)

  const GradientSquareLoader({
    super.key,
    this.size = 64.0,
    this.animationDurationMs = 2000,
    this.color1,
    this.color2,
    this.color3,
  });

  @override
  State<GradientSquareLoader> createState() => _GradientSquareLoaderState();
}

class _GradientSquareLoaderState extends State<GradientSquareLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Define the default colors
  static const Color _defaultColor1 = Color(0xFFF10C49); // Pink
  static const Color _defaultColor2 = Color(0xFFf4dd51); // Yellow
  static const Color _defaultColor3 = Color(0xFFe3aad6); // Light purple

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
    // Use provided colors or defaults
    final color1 = widget.color1 ?? _defaultColor1;
    final color2 = widget.color2 ?? _defaultColor2;
    final color3 = widget.color3 ?? _defaultColor3;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Calculate the current animation phase (0.0 to 1.0)
          final animValue = _controller.value;
          
          // Determine which keyframe we're in (0 to 5)
          // The CSS animation has 6 keyframes at 0%, 16.67%, 33.33%, 50%, 66.67%, 83.33%, and 100%
          int keyframe;
          double localProgress;
          
          if (animValue < 1/6) {
            keyframe = 0;
            localProgress = animValue * 6;
          } else if (animValue < 2/6) {
            keyframe = 1;
            localProgress = (animValue - 1/6) * 6;
          } else if (animValue < 3/6) {
            keyframe = 2;
            localProgress = (animValue - 2/6) * 6;
          } else if (animValue < 4/6) {
            keyframe = 3;
            localProgress = (animValue - 3/6) * 6;
          } else if (animValue < 5/6) {
            keyframe = 4;
            localProgress = (animValue - 4/6) * 6;
          } else {
            keyframe = 5;
            localProgress = (animValue - 5/6) * 6;
          }
          
          // Get the positions for the current keyframe
          final positions = _getPositionsForKeyframe(keyframe, localProgress);
          
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _GradientSquarePainter(
              color1: color1,
              color2: color2,
              color3: color3,
              positions: positions,
            ),
          );
        },
      ),
    );
  }
  
  // Get the positions for each gradient based on the current keyframe and local progress
  List<List<Offset>> _getPositionsForKeyframe(int keyframe, double localProgress) {
    // Each position is a list of 4 offsets for the 4 gradients of each color
    // The positions are normalized (0.0 to 1.0) relative to the widget size
    
    // Define the positions for each keyframe
    // These match the CSS animation keyframes
    final keyframePositions = [
      // Keyframe 0 (0%) - Initial positions (centered)
      [
        [const Offset(1/3, 1/3), const Offset(2/3, 1/3), const Offset(1/3, 2/3), const Offset(2/3, 2/3)], // Color 1
        [const Offset(1/3, 1/3), const Offset(2/3, 1/3), const Offset(1/3, 2/3), const Offset(2/3, 2/3)], // Color 2
        [const Offset(1/3, 1/3), const Offset(2/3, 1/3), const Offset(1/3, 2/3), const Offset(2/3, 2/3)], // Color 3
      ],
      // Keyframe 1 (16.67%) - Color 1 moves to corners
      [
        [const Offset(0, 0), const Offset(1, 0), const Offset(0, 1), const Offset(1, 1)], // Color 1
        [const Offset(1/3, 1/3), const Offset(2/3, 1/3), const Offset(1/3, 2/3), const Offset(2/3, 2/3)], // Color 2
        [const Offset(1/3, 1/3), const Offset(2/3, 1/3), const Offset(1/3, 2/3), const Offset(2/3, 2/3)], // Color 3
      ],
      // Keyframe 2 (33.33%) - Color 2 moves to corners
      [
        [const Offset(0, 0), const Offset(1, 0), const Offset(0, 1), const Offset(1, 1)], // Color 1
        [const Offset(0, 0), const Offset(1, 0), const Offset(0, 1), const Offset(1, 1)], // Color 2
        [const Offset(1/3, 1/3), const Offset(2/3, 1/3), const Offset(1/3, 2/3), const Offset(2/3, 2/3)], // Color 3
      ],
      // Keyframe 3 (50%) - Color 3 moves to corners
      [
        [const Offset(0, 0), const Offset(1, 0), const Offset(0, 1), const Offset(1, 1)], // Color 1
        [const Offset(0, 0), const Offset(1, 0), const Offset(0, 1), const Offset(1, 1)], // Color 2
        [const Offset(0, 0), const Offset(1, 0), const Offset(0, 1), const Offset(1, 1)], // Color 3
      ],
      // Keyframe 4 (66.67%) - Color 1 moves back to center
      [
        [const Offset(1/3, 1/3), const Offset(2/3, 1/3), const Offset(1/3, 2/3), const Offset(2/3, 2/3)], // Color 1
        [const Offset(0, 0), const Offset(1, 0), const Offset(0, 1), const Offset(1, 1)], // Color 2
        [const Offset(0, 0), const Offset(1, 0), const Offset(0, 1), const Offset(1, 1)], // Color 3
      ],
      // Keyframe 5 (83.33%) - Color 2 moves back to center
      [
        [const Offset(1/3, 1/3), const Offset(2/3, 1/3), const Offset(1/3, 2/3), const Offset(2/3, 2/3)], // Color 1
        [const Offset(1/3, 1/3), const Offset(2/3, 1/3), const Offset(1/3, 2/3), const Offset(2/3, 2/3)], // Color 2
        [const Offset(0, 0), const Offset(1, 0), const Offset(0, 1), const Offset(1, 1)], // Color 3
      ],
      // Keyframe 6 (100%) - All back to center (same as keyframe 0)
      [
        [const Offset(1/3, 1/3), const Offset(2/3, 1/3), const Offset(1/3, 2/3), const Offset(2/3, 2/3)], // Color 1
        [const Offset(1/3, 1/3), const Offset(2/3, 1/3), const Offset(1/3, 2/3), const Offset(2/3, 2/3)], // Color 2
        [const Offset(1/3, 1/3), const Offset(2/3, 1/3), const Offset(1/3, 2/3), const Offset(2/3, 2/3)], // Color 3
      ],
    ];
    
    // Get the current and next keyframe positions
    final currentPositions = keyframePositions[keyframe];
    final nextPositions = keyframePositions[(keyframe + 1) % keyframePositions.length];
    
    // Interpolate between current and next keyframe positions based on local progress
    List<List<Offset>> interpolatedPositions = [];
    
    for (int colorIndex = 0; colorIndex < 3; colorIndex++) {
      List<Offset> colorPositions = [];
      
      for (int posIndex = 0; posIndex < 4; posIndex++) {
        final currentPos = currentPositions[colorIndex][posIndex];
        final nextPos = nextPositions[colorIndex][posIndex];
        
        // Linear interpolation between current and next position
        final interpolatedX = currentPos.dx + (nextPos.dx - currentPos.dx) * localProgress;
        final interpolatedY = currentPos.dy + (nextPos.dy - currentPos.dy) * localProgress;
        
        colorPositions.add(Offset(interpolatedX, interpolatedY));
      }
      
      interpolatedPositions.add(colorPositions);
    }
    
    return interpolatedPositions;
  }
}

class _GradientSquarePainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final Color color3;
  final List<List<Offset>> positions;

  _GradientSquarePainter({
    required this.color1,
    required this.color2,
    required this.color3,
    required this.positions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the cell size (25% of the total size)
    final cellSize = size.width / 4;
    
    // Draw background
    final bgPaint = Paint()
      ..color = Colors.transparent;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    
    // Draw each set of gradients
    _drawGradients(canvas, size, color1, positions[0]);
    _drawGradients(canvas, size, color2, positions[1]);
    _drawGradients(canvas, size, color3, positions[2]);
  }
  
  void _drawGradients(Canvas canvas, Size size, Color color, List<Offset> positions) {
    // For each position, draw a radial gradient
    for (int i = 0; i < positions.length; i++) {
      final position = positions[i];
      
      // Convert normalized position to actual pixels
      final centerX = position.dx * size.width;
      final centerY = position.dy * size.height;
      
      // Calculate radius (25% of the widget size)
      final radius = size.width * 0.25;
      
      // Create a radial gradient paint
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color,
            Colors.transparent,
          ],
          stops: const [0.9, 1.0], // Sharp edge at 90% to match CSS
        ).createShader(
          Rect.fromCircle(
            center: Offset(centerX, centerY),
            radius: radius,
          ),
        );
      
      // Draw the gradient
      canvas.drawCircle(
        Offset(centerX, centerY),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GradientSquarePainter oldDelegate) {
    return oldDelegate.color1 != color1 ||
        oldDelegate.color2 != color2 ||
        oldDelegate.color3 != color3 ||
        oldDelegate.positions != positions;
  }
}