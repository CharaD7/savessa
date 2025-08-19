import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:savessa/core/theme/app_theme.dart';

/// A lightweight, procedural background animation that draws petal-like
/// ripple shapes across the screen using CustomPainter. Designed for low
/// memory usage and smooth performance.
class PetalRippleBackground extends StatefulWidget {
  final Alignment centerAlignment; // origin of ripples relative to the canvas
  const PetalRippleBackground({super.key, this.centerAlignment = Alignment.center});

  @override
  State<PetalRippleBackground> createState() => _PetalRippleBackgroundState();
}

class _PetalRippleBackgroundState extends State<PetalRippleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations || media.accessibleNavigation;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = reduceMotion ? 0.35 : _controller.value;
        return RepaintBoundary(
          child: CustomPaint(
            painter: _PetalRipplePainter(time: t, centerAlignment: widget.centerAlignment),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _PetalRipplePainter extends CustomPainter {
  final double time; // 0..1
  final Alignment centerAlignment;

  _PetalRipplePainter({required this.time, required this.centerAlignment}) {
    _initOnce();
  }

  // Cached tables for performance
  static const int _samples = 180; // theta samples for path smoothness (2 degrees step)
  static List<double>? _theta;

  // Paints reused
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  void _initOnce() {
    if (_theta != null) return;
    _theta = List<double>.generate(_samples, (i) => (i / _samples) * 2 * math.pi);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient to keep the original purple feel
    const bg = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppTheme.royalPurple, AppTheme.lightPurple],
    );
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = bg.createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Parameters
    // Map alignment (-1..1) to pixel coordinates
    final cx = size.width * (0.5 * (centerAlignment.x + 1.0));
    final cy = size.height * (0.5 * (centerAlignment.y + 1.0));
    final baseRadius = math.min(size.width, size.height) * 0.22;

    // Two or three ripple rings with subtle phase offsets
    final rings = <_RingSpec>[
      _RingSpec(lobes: 10, amp: 0.12, radius: baseRadius * (1.00 + 0.10 * _sine(time * 0.9)), hueShift: 0.0, rotation: _sine(time) * 0.10),
      _RingSpec(lobes: 8, amp: 0.10, radius: baseRadius * (1.40 + 0.12 * _sine(time * 1.1 + 0.33)), hueShift: 0.08, rotation: _sine(time * 0.8 + 0.2) * -0.12),
      _RingSpec(lobes: 12, amp: 0.08, radius: baseRadius * (1.85 + 0.10 * _sine(time * 1.3 + 0.6)), hueShift: -0.06, rotation: _sine(time * 0.7 + 0.4) * 0.08),
    ];

    for (int i = 0; i < rings.length; i++) {
      _drawPetalRing(canvas, cx, cy, rings[i], size, i);
    }
  }

  void _drawPetalRing(Canvas canvas, double cx, double cy, _RingSpec spec, Size size, int index) {
    final path = Path();
    final rot = spec.rotation;

    // Petal radius function: r = R * (1 + amp * sin(lobes * theta + phase))
    for (int i = 0; i < _samples; i++) {
      final th = _theta![i] + rot;
      final s = math.sin(spec.lobes * th);
      final r = spec.radius * (1.0 + spec.amp * s);
      final x = cx + r * math.cos(th);
      final y = cy + r * math.sin(th);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Color: soft brand tint with low alpha
    final inner = AppTheme.gold.withValues(alpha: 0.10 + 0.05 * (index + 1));
    final outer = Colors.white.withValues(alpha: 0.0);

    _fillPaint.shader = RadialGradient(
      colors: [inner, outer],
      stops: const [0.0, 1.0],
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: spec.radius * (1.2 + spec.amp)));

    canvas.save();
    // Slight global rotation for subtle motion
    canvas.translate(cx, cy);
    canvas.rotate(rot * 0.35);
    canvas.translate(-cx, -cy);

    canvas.drawPath(path, _fillPaint);

    canvas.restore();
  }

  double _sine(double x) => math.sin(2 * math.pi * x);

  @override
  bool shouldRepaint(covariant _PetalRipplePainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

class _RingSpec {
  final int lobes;
  final double amp; // 0..1 fraction of base radius
  final double radius;
  final double hueShift; // reserved for future color tweaks
  final double rotation; // radians
  const _RingSpec({
    required this.lobes,
    required this.amp,
    required this.radius,
    required this.hueShift,
    required this.rotation,
  });
}

