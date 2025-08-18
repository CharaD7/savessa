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
                // Faint pulsing glow behind the logo
                _LogoGlow(t: t, size: size),
                // Shimmer over logo for a gentle sweep
                _Shimmer(logo: logo, t: t, size: size),
              ],
            ),
          ),
        );
      },
    );
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

class _LogoGlow extends StatelessWidget {
  final double t;
  final double size;
  const _LogoGlow({required this.t, required this.size});

  @override
  Widget build(BuildContext context) {
    final pulse = 0.5 + 0.5 * math.sin(2 * math.pi * (t * 0.9));
    final glowAlpha = 0.10 + 0.16 * pulse; // faint
    final radius = size * (1.4 + 0.25 * pulse);
    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.gold.withValues(alpha: glowAlpha),
                  AppTheme.royalPurple.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: size * 0.08, sigmaY: size * 0.08),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
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
