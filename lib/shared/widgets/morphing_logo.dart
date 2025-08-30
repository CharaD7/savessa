import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:savessa/core/theme/app_theme.dart';

/// Ultra-modern morphing logo widget that combines Lottie animations with
/// sophisticated particle trails and glow effects for maximum visual impact.
/// 
/// Features:
/// - Lottie animation for morphing geometric shapes into logo
/// - Custom particle trails following logo edges
/// - Dynamic glow effects with ImageFilter.blur
/// - Responsive sizing based on screen dimensions
/// - Performance optimized with RepaintBoundary
class MorphingLogo extends StatefulWidget {
  final double size;
  final Duration animationDelay;
  final Duration animationDuration;
  final VoidCallback? onAnimationComplete;
  final bool enableParticleTrails;
  final bool enableGlowEffect;
  final String? fallbackAssetPath;

  const MorphingLogo({
    super.key,
    this.size = 180.0,
    this.animationDelay = const Duration(milliseconds: 500),
    this.animationDuration = const Duration(milliseconds: 3000),
    this.onAnimationComplete,
    this.enableParticleTrails = true,
    this.enableGlowEffect = true,
    this.fallbackAssetPath = 'assets/images/logo.png',
  });

  @override
  State<MorphingLogo> createState() => _MorphingLogoState();
}

class _MorphingLogoState extends State<MorphingLogo> 
    with TickerProviderStateMixin {
  
  late final AnimationController _logoController;
  late final AnimationController _glowController;
  late final AnimationController _particleTrailController;
  
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _particleTrailAnimation;
  
  bool _animationStarted = false;
  bool _showFallback = false;
  
  final List<_ParticleTrail> _particleTrails = [];
  final math.Random _random = math.Random();
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
    _startDelayedAnimation();
  }
  
  void _initializeControllers() {
    _logoController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _particleTrailController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
  }
  
  void _setupAnimations() {
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOutCubic,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOutSine,
    ));
    
    _particleTrailAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleTrailController,
      curve: Curves.easeOutQuart,
    ));
    
    // Setup listeners
    _logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onMorphingComplete();
      }
    });
    
    _particleTrailController.addListener(() {
      if (_particleTrailController.value > 0.2) {
        _generateParticleTrails();
      }
    });
  }
  
  void _startDelayedAnimation() {
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        setState(() {
          _animationStarted = true;
        });
        _logoController.forward();
        if (widget.enableGlowEffect) {
          _glowController.repeat(reverse: true);
        }
        if (widget.enableParticleTrails) {
          _particleTrailController.forward();
        }
      }
    });
  }
  
  void _onMorphingComplete() {
    widget.onAnimationComplete?.call();
  }
  
  void _generateParticleTrails() {
    if (_particleTrails.length >= 20) return; // Limit particle count
    
    final centerX = widget.size / 2;
    final centerY = widget.size / 2;
    final radius = widget.size * 0.3;
    
    for (int i = 0; i < 3; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final distance = radius + _random.nextDouble() * 20;
      
      _particleTrails.add(_ParticleTrail(
        startX: centerX + math.cos(angle) * distance,
        startY: centerY + math.sin(angle) * distance,
        velocityX: math.cos(angle) * (_random.nextDouble() * 2 + 1),
        velocityY: math.sin(angle) * (_random.nextDouble() * 2 + 1),
        color: _random.nextBool() ? AppTheme.gold : AppTheme.royalPurple,
        size: _random.nextDouble() * 4 + 2,
        life: 1.0,
      ));
    }
    
    // Remove old particles
    _particleTrails.removeWhere((particle) => particle.life <= 0);
  }
  
  void _onLottieLoaded() {
    // Callback for when Lottie animation is loaded
  }
  
  void _onLottieError() {
    if (mounted) {
      setState(() {
        _showFallback = true;
      });
    }
  }
  
  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _particleTrailController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size * 2.4,
        height: widget.size * 2.4,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect layer
            if (widget.enableGlowEffect && _animationStarted)
              _buildGlowEffect(),
            
            // Main logo content
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: _showFallback ? _buildFallbackLogo() : _buildLottieLogo(),
                  ),
                );
              },
            ),
            
            // Particle trails overlay
            if (widget.enableParticleTrails && _animationStarted)
              _buildParticleTrails(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLottieLogo() {
    return Lottie.asset(
      'assets/animations/splash_morph_sequence.json',
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      animate: _animationStarted,
      repeat: false,
      onLoaded: (composition) {
        _onLottieLoaded();
        // Ensure the animation duration matches the Lottie composition
        if (mounted) {
          _logoController.duration = composition.duration;
        }
      },
      errorBuilder: (context, error, stackTrace) {
        _onLottieError();
        return _buildFallbackLogo();
      },
    );
  }
  
  Widget _buildFallbackLogo() {
    if (widget.fallbackAssetPath == null) {
      return _buildPlaceholderLogo();
    }
    
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Opacity(
          opacity: _logoController.value,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.size / 5),
            child: Image.asset(
              widget.fallbackAssetPath!,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderLogo();
              },
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPlaceholderLogo() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppTheme.royalPurple,
        borderRadius: BorderRadius.circular(widget.size / 5),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.lightPurple, AppTheme.royalPurple],
        ),
      ),
      child: Center(
        child: Text(
          'S',
          style: TextStyle(
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.bold,
            color: AppTheme.gold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildGlowEffect() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowIntensity = _glowAnimation.value;
        final glowRadius = widget.size * (0.8 + 0.4 * glowIntensity);
        
        return Container(
          width: glowRadius * 2,
          height: glowRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.gold.withValues(alpha: 0.3 * glowIntensity),
                AppTheme.royalPurple.withValues(alpha: 0.1 * glowIntensity),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: widget.size * 0.1 * glowIntensity,
                sigmaY: widget.size * 0.1 * glowIntensity,
              ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildParticleTrails() {
    return AnimatedBuilder(
      animation: _particleTrailAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size * 2.4, widget.size * 2.4),
          painter: _ParticleTrailsPainter(
            particles: _particleTrails,
            animationProgress: _particleTrailAnimation.value,
            centerOffset: Offset(widget.size * 1.2, widget.size * 1.2),
          ),
        );
      },
    );
  }
}

// Particle trail data class
class _ParticleTrail {
  double startX;
  double startY;
  double velocityX;
  double velocityY;
  Color color;
  double size;
  double life;
  
  double get currentX => startX + velocityX * (1 - life) * 100;
  double get currentY => startY + velocityY * (1 - life) * 100;
  
  _ParticleTrail({
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.color,
    required this.size,
    required this.life,
  });
  
  void update(double deltaTime) {
    life -= deltaTime * 0.8;
    if (life < 0) life = 0;
  }
}

// Custom painter for particle trails
class _ParticleTrailsPainter extends CustomPainter {
  final List<_ParticleTrail> particles;
  final double animationProgress;
  final Offset centerOffset;
  
  _ParticleTrailsPainter({
    required this.particles,
    required this.animationProgress,
    required this.centerOffset,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    const deltaTime = 1.0 / 60.0; // Assume 60 FPS
    
    for (final particle in particles) {
      particle.update(deltaTime);
      
      if (particle.life > 0) {
        final paint = Paint()
          ..color = particle.color.withValues(alpha: particle.life * 0.8)
          ..style = PaintingStyle.fill;
        
        // Draw particle with trail effect
        final currentPos = Offset(particle.currentX, particle.currentY);
        final previousPos = Offset(
          particle.currentX - particle.velocityX * 10,
          particle.currentY - particle.velocityY * 10,
        );
        
        // Draw trail
        final gradient = ui.Gradient.linear(
          previousPos,
          currentPos,
          [
            particle.color.withValues(alpha: 0.0),
            particle.color.withValues(alpha: particle.life * 0.6),
          ],
        );
        
        final trailPaint = Paint()
          ..shader = gradient
          ..strokeWidth = particle.size * 0.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        
        canvas.drawLine(previousPos, currentPos, trailPaint);
        
        // Draw particle
        canvas.drawCircle(
          currentPos,
          particle.size * particle.life,
          paint,
        );
        
        // Draw sparkle effect
        if (particle.life > 0.5) {
          _drawSparkle(canvas, currentPos, particle.size, particle.color, particle.life);
        }
      }
    }
  }
  
  void _drawSparkle(Canvas canvas, Offset center, double size, Color color, double life) {
    final sparklePaint = Paint()
      ..color = color.withValues(alpha: life * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    
    final sparkleSize = size * 1.5;
    
    // Draw cross sparkle
    canvas.drawLine(
      Offset(center.dx - sparkleSize, center.dy),
      Offset(center.dx + sparkleSize, center.dy),
      sparklePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - sparkleSize),
      Offset(center.dx, center.dy + sparkleSize),
      sparklePaint,
    );
    
    // Draw diagonal sparkle
    final diagonalSize = sparkleSize * 0.7;
    canvas.drawLine(
      Offset(center.dx - diagonalSize, center.dy - diagonalSize),
      Offset(center.dx + diagonalSize, center.dy + diagonalSize),
      sparklePaint,
    );
    canvas.drawLine(
      Offset(center.dx - diagonalSize, center.dy + diagonalSize),
      Offset(center.dx + diagonalSize, center.dy - diagonalSize),
      sparklePaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant _ParticleTrailsPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
           oldDelegate.particles.length != particles.length;
  }
}
