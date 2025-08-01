import 'package:flutter/material.dart';

/// A custom page route that creates a ripple fold animation from right to left,
/// resembling waves of the sea revealing the new page.
class RippleFoldPageRoute<T> extends PageRoute<T> {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Color? waveColor;
  final Color? gradientColor;

  RippleFoldPageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 2500),
    this.curve = Curves.easeInOutSine,
    this.waveColor,
    this.gradientColor,
    super.settings,
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Create a curved animation for smoother wave movement
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );
    
    return RippleFoldTransition(
      animation: curvedAnimation,
      waveColor: waveColor ?? Theme.of(context).primaryColor,
      gradientColor: gradientColor,
      child: child,
    );
  }
}

/// A custom transition widget that creates a ripple fold animation from right to left,
/// resembling waves of the sea revealing the new page.
class RippleFoldTransition extends StatefulWidget {
  final Animation<double> animation;
  final Widget child;
  final Color waveColor;
  final Color? gradientColor;

  const RippleFoldTransition({
    super.key,
    required this.animation,
    required this.child,
    required this.waveColor,
    this.gradientColor,
  });

  @override
  State<RippleFoldTransition> createState() => _RippleFoldTransitionState();
}

class _RippleFoldTransitionState extends State<RippleFoldTransition> {
  // Use a simpler approach without additional animation controllers
  // This reduces the animation complexity and resource usage

  @override
  void initState() {
    super.initState();
    // No additional animation controllers to initialize
  }

  @override
  void dispose() {
    // No additional animation controllers to dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Instead of using the same widget instance in multiple places,
    // we'll use a simpler approach that doesn't require creating new instances
    
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        return Stack(
          children: [
            // Background with fade-in effect
            // Use an empty container instead of the actual widget
            // This avoids GlobalKey conflicts while still showing the background color
            Positioned.fill(
              child: Opacity(
                opacity: widget.animation.value,
                child: Container(
                  color: widget.waveColor.withOpacity(0.3),
                ),
              ),
            ),
            
            // Clipped foreground with simplified wave effect
            ClipPath(
              clipper: RippleFoldClipper(
                progress: widget.animation.value,
                waveCount: 4, // Reduced number of waves
                waveAmplitude: 20.0, // Static wave amplitude
              ),
              child: Stack(
                children: [
                  // The actual page content - use the original widget instance
                  widget.child,
                  
                  // Simple overlay that fades out as the animation progresses
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.3 - (0.3 * widget.animation.value),
                      child: Container(
                        color: widget.waveColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A custom clipper that creates a simplified ripple fold effect from right to left.
/// This version uses simpler path calculations to improve performance.
class RippleFoldClipper extends CustomClipper<Path> {
  final double progress;
  final int waveCount;
  final double waveAmplitude;

  RippleFoldClipper({
    required this.progress,
    required this.waveCount,
    required this.waveAmplitude,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    
    if (progress <= 0.0) {
      // At the start of the animation, don't show anything
      return path;
    }
    
    if (progress >= 1.0) {
      // At the end of the animation, show everything
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }

    // Calculate the base x position for the wave
    final baseX = size.width * (1.0 - progress);
    
    // Start at the top-left corner
    path.moveTo(0, 0);
    
    // Draw the left side
    path.lineTo(baseX - waveAmplitude * 0.5, 0);
    
    // Draw the wavy edge from top to bottom using simpler calculations
    final waveHeight = size.height / waveCount;
    
    for (int i = 0; i < waveCount; i++) {
      final waveStart = i * waveHeight;
      final waveMiddle = waveStart + waveHeight / 2;
      final waveEnd = waveStart + waveHeight;
      
      // Use simple quadratic bezier curves instead of cubic beziers
      // This is less computationally intensive
      path.quadraticBezierTo(
        baseX + (i.isEven ? 1 : -1) * waveAmplitude,
        waveMiddle,
        baseX - (i.isEven ? 1 : -1) * waveAmplitude * 0.5,
        waveEnd,
      );
    }
    
    // Complete the path by drawing the remaining rectangle
    path.lineTo(0, size.height);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(RippleFoldClipper oldClipper) {
    return oldClipper.progress != progress ||
        oldClipper.waveCount != waveCount ||
        oldClipper.waveAmplitude != waveAmplitude;
  }
}

/// Extension method to add the ripple fold transition to the Navigator
extension RippleFoldNavigatorExtension on BuildContext {
  Future<T?> pushRippleFold<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 1200),
    Curve curve = Curves.easeInOutSine,
    Color? waveColor,
    Color? gradientColor,
  }) {
    return Navigator.of(this).push(
      RippleFoldPageRoute<T>(
        child: page,
        duration: duration,
        curve: curve,
        waveColor: waveColor,
        gradientColor: gradientColor,
      ),
    );
  }
}