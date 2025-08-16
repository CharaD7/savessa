import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'package:savessa/core/theme/app_theme.dart';

class AppLogo extends StatefulWidget {
  final double size;
  final bool glow; // Soft glow on static screens
  final bool animate; // Enable splash animations (ripple, shimmer, sparkles)
  final bool repeat; // Whether to loop the animation
  final String assetPath;

  const AppLogo({
    super.key,
    this.size = 100,
    this.glow = false,
    this.animate = false,
    this.repeat = true,
    this.assetPath = 'assets/images/logo.png',
  });

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(widget.size / 5),
      child: Image.asset(
        widget.assetPath,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );

    Widget content = widget.animate
        ? _AnimatedEffects(logo: logo, controller: _controller, size: widget.size)
        : logo;

    if (widget.glow) {
      // Replace generic glow with an S-shaped vivid trace using a blurred gold-tinted logo
      content = Stack(
        alignment: Alignment.center,
        children: [
          // Glow layer: slightly scaled, gold-tinted, blurred copy of the logo
          Transform.scale(
            scale: 1.04,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(AppTheme.gold, BlendMode.srcATop),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: widget.size * 0.06, sigmaY: widget.size * 0.06),
                child: logo,
              ),
            ),
          ),
          content,
        ],
      );
    }

    return content;
  }
}

class _AnimatedEffects extends StatelessWidget {
  final Widget logo;
  final AnimationController controller;
  final double size;

  const _AnimatedEffects({
    required this.logo,
    required this.controller,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final tRaw = controller.value; // 0..1
        final t = Curves.easeInOutSine.transform(tRaw);
        final zoom = 1.0 + 0.05 * math.sin(2 * math.pi * t);
        return Transform.scale(
          scale: zoom,
          child: SizedBox(
            width: size * 2.4,
            height: size * 2.4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Sun rays along an S path
                CustomPaint(
                  size: Size(size * 2.0, size * 2.0),
                  painter: _SPathRaysPainter(t: t, size: size),
                ),

                // Sparkles
                ..._buildSparkles(t),

                // Shimmer over logo
                _Shimmer(logo: logo, t: t, size: size),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSparkles(double t) {
    const int count = 28; // slightly fewer for smoothness
    final widgets = <Widget>[];
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2;
      final rnd = math.Random(i + 7);
      final radius = size * 0.9 + (rnd.nextDouble() * size * 0.6);
      final phase = t * 0.6; // slower movement
      final x = math.cos(angle + phase * 2 * math.pi) * radius;
      final y = math.sin(angle + phase * 2 * math.pi) * radius;
      final scale = 0.8 + 0.65 * (0.5 + 0.5 * math.sin((phase + i / count) * 2 * math.pi));
      final opacity = (0.42 + 0.5 * (0.5 + 0.5 * math.cos((phase + i / count) * 2 * math.pi))).clamp(0.0, 1.0);
      final isLine = i.isEven; // alternate between line sparks and dots
      widgets.add(Transform.translate(
        offset: Offset(x, y),
        child: Opacity(
          opacity: opacity,
          child: Transform.rotate(
            angle: angle + t * 6.28318,
            child: isLine
                ? Container(
                    width: 18 * scale,
                    height: 2.6,
                    decoration: BoxDecoration(
                      color: AppTheme.gold,
                      boxShadow: [
                        BoxShadow(color: AppTheme.gold.withValues(alpha: 0.9), blurRadius: 7, spreadRadius: 1.2),
                        BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 2, spreadRadius: 0.6),
                      ],
                      borderRadius: BorderRadius.circular(1.3),
                    ),
                  )
                : Icon(
                    Icons.star_rounded,
                    color: AppTheme.gold.withValues(alpha: 0.97),
                    size: 8 + 3 * scale,
                    shadows: [
                      Shadow(color: AppTheme.gold.withValues(alpha: 0.8), blurRadius: 7),
                      Shadow(color: Colors.white.withValues(alpha: 0.45), blurRadius: 2.2),
                    ],
                  ),
          ),
        ),
      ));
    }
    return widgets;
  }
}

class _Shimmer extends StatelessWidget {
  final Widget logo;
  final double t;
  final double size;
  const _Shimmer({required this.logo, required this.t, required this.size});

  @override
  Widget build(BuildContext context) {
    // final shimmerWidth = size * 0.4; // reserved for future width-based tuning
    final dx = (t * (size * 2.0)) - size; // sweep across
    return Stack(
      alignment: Alignment.center,
      children: [
        logo,
        IgnorePointer(
          child: ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppTheme.gold.withValues(alpha: 0.0),
                  AppTheme.gold.withValues(alpha: 0.9),
                  AppTheme.gold.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
                transform: GradientTranslation(dx, 0),
              ).createShader(rect);
            },
            blendMode: BlendMode.srcATop,
            child: SizedBox(
              width: size,
              height: size,
            ),
          ),
        ),
      ],
    );
  }
}

class _SPathRaysPainter extends CustomPainter {
  final double t;
  final double size;
  _SPathRaysPainter({required this.t, required this.size});

  Path _buildSPath(Rect bounds) {
    // Build a cubic-bezier "S" shape within bounds
    final w = bounds.width;
    final h = bounds.height;
    final left = bounds.left + w * 0.25;
    final right = bounds.left + w * 0.75;
    final top = bounds.top + h * 0.2;
    final bottom = bounds.top + h * 0.8;
    final midY = bounds.top + h * 0.5;

    final path = Path();
    path.moveTo(right, top);
    path.cubicTo(left, top, right, midY, left, midY);
    path.cubicTo(right, midY, left, bottom, right, bottom);
    return path;
  }

  @override
  void paint(Canvas canvas, Size s) {
    final rect = Rect.fromCenter(center: Offset(s.width / 2, s.height / 2), width: size * 1.5, height: size * 1.5);

    final sPath = _buildSPath(rect);

    // Draw sun rays emanating along the S path
    final rayPaint = Paint()
      ..color = AppTheme.gold
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const int rayCount = 24;
    for (int i = 0; i < rayCount; i++) {
      final p = (i / rayCount + t * 0.6) % 1.0;
      final metric = sPath.computeMetrics().first;
      final pos = metric.length * p;
      final tangent = metric.getTangentForOffset(pos)!;
      final start = tangent.position;
      final dir = tangent.vector;
      final normal = Offset(-dir.dy, dir.dx).direction; // angle
      final len = 14.0 + 24.0 * (0.5 + 0.5 * math.sin(2 * math.pi * (t + i / rayCount)));
      final end = start + Offset.fromDirection(normal, len);
      canvas.drawLine(start, end, rayPaint);
    }

    // (Removed cog/machinery accents to keep only solid rays)
  }

  @override
  bool shouldRepaint(covariant _SPathRaysPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.size != size;
  }
}

class GradientTranslation extends GradientTransform {
  final double dx;
  final double dy;
  const GradientTranslation(this.dx, this.dy);
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.identity()..translate(dx, dy);
  }
}
