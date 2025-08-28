import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:savessa/core/theme/app_theme.dart';

/// Ultra-modern particle system background widget that creates dynamic particles
/// with gravitational effects, magnetic attraction, and sophisticated coalescence animations.
/// 
/// Features:
/// - Initial burst of 50-100 particles with custom shapes
/// - Gravity and wind effects for natural movement
/// - Magnetic attraction toward center during convergence phase
/// - Performance optimized with RepaintBoundary and efficient rendering
class ParticleSystemBackground extends StatefulWidget {
  final double width;
  final double height;
  final Alignment centerAlignment;
  final bool enableCoalescence;
  final AnimationController? parentController;
  final VoidCallback? onAnimationComplete;

  const ParticleSystemBackground({
    super.key,
    required this.width,
    required this.height,
    this.centerAlignment = Alignment.center,
    this.enableCoalescence = true,
    this.parentController,
    this.onAnimationComplete,
  });

  @override
  State<ParticleSystemBackground> createState() => _ParticleSystemBackgroundState();
}

class _ParticleSystemBackgroundState extends State<ParticleSystemBackground> 
    with TickerProviderStateMixin {
  
  late final ConfettiController _confettiController;
  late final AnimationController _internalController;
  late final AnimationController _coalescenceController;
  
  late final Animation<double> _dispersalAnimation;
  late final Animation<double> _coalescenceAnimation;
  late final Animation<double> _magneticForceAnimation;
  
  final List<_ManagedParticle> _managedParticles = [];
  final math.Random _random = math.Random();
  
  // Animation phases
  bool _isDispersalPhase = true;
  bool _isCoalescencePhase = false;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
    _startParticleAnimation();
  }
  
  void _initializeControllers() {
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 100),
    );
    
    _internalController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _coalescenceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }
  
  void _setupAnimations() {
    _dispersalAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _internalController,
      curve: Curves.easeOutQuart,
    ));
    
    _coalescenceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _coalescenceController,
      curve: Curves.easeInQuart,
    ));
    
    _magneticForceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _coalescenceController,
      curve: Curves.easeInOutCubic,
    ));
    
    // Setup listeners
    _internalController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isDispersalPhase) {
        _startCoalescencePhase();
      }
    });
    
    _coalescenceController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isCoalescencePhase) {
        _completeAnimation();
      }
    });
  }
  
  void _startParticleAnimation() {
    _generateManagedParticles();
    _confettiController.play();
    _internalController.forward();
  }
  
  void _startCoalescencePhase() {
    if (!widget.enableCoalescence) return;
    
    setState(() {
      _isDispersalPhase = false;
      _isCoalescencePhase = true;
    });
    
    _coalescenceController.forward();
  }
  
  void _completeAnimation() {
    widget.onAnimationComplete?.call();
  }
  
  void _generateManagedParticles() {
    final particleCount = _random.nextInt(51) + 50; // 50-100 particles
    final centerX = widget.width * (0.5 + widget.centerAlignment.x * 0.5);
    final centerY = widget.height * (0.5 + widget.centerAlignment.y * 0.5);
    
    for (int i = 0; i < particleCount; i++) {
      final angle = (_random.nextDouble() * 2 * math.pi);
      final distance = _random.nextDouble() * 100 + 50;
      
      _managedParticles.add(_ManagedParticle(
        initialX: centerX + math.cos(angle) * distance,
        initialY: centerY + math.sin(angle) * distance,
        targetX: centerX,
        targetY: centerY,
        velocity: Offset(
          (_random.nextDouble() - 0.5) * 4,
          (_random.nextDouble() - 0.5) * 4,
        ),
        shape: _ParticleShape.values[_random.nextInt(_ParticleShape.values.length)],
        color: _random.nextBool() ? AppTheme.gold : AppTheme.royalPurple,
        size: _random.nextDouble() * 8 + 4,
        rotationSpeed: (_random.nextDouble() - 0.5) * 4,
      ));
    }
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    _internalController.dispose();
    _coalescenceController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: [
            // Confetti particles for initial burst effect
            Positioned.fill(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AppTheme.gold,
                  AppTheme.royalPurple,
                  AppTheme.lightPurple,
                  AppTheme.lightGold,
                ],
                createParticlePath: _createCustomParticlePath,
                particleDrag: 0.05,
                emissionFrequency: 0.8,
                numberOfParticles: 30,
                gravity: 0.1,
                maxBlastForce: 15,
                minBlastForce: 8,
              ),
            ),
            
            // Managed particle system overlay
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _dispersalAnimation,
                  _coalescenceAnimation,
                  _magneticForceAnimation,
                ]),
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ManagedParticlesPainter(
                      particles: _managedParticles,
                      dispersalProgress: _dispersalAnimation.value,
                      coalescenceProgress: _coalescenceAnimation.value,
                      magneticForce: _magneticForceAnimation.value,
                      isCoalescencePhase: _isCoalescencePhase,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Custom particle path for confetti
  Path _createCustomParticlePath(Size size) {
    final path = Path();
    final shapeType = _random.nextInt(3);
    
    switch (shapeType) {
      case 0: // Circle
        path.addOval(Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2,
        ));
        break;
      case 1: // Star
        _createStarPath(path, size);
        break;
      case 2: // Diamond
        _createDiamondPath(path, size);
        break;
    }
    
    return path;
  }
  
  void _createStarPath(Path path, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.4;
    final spikes = 5;
    
    for (int i = 0; i < spikes * 2; i++) {
      final angle = (i * math.pi) / spikes;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + radius * math.cos(angle - math.pi / 2);
      final y = center.dy + radius * math.sin(angle - math.pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
  }
  
  void _createDiamondPath(Path path, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx + radius, center.dy);
    path.lineTo(center.dx, center.dy + radius);
    path.lineTo(center.dx - radius, center.dy);
    path.close();
  }
}

// Enum for particle shapes
enum _ParticleShape { circle, star, diamond, triangle }

// Managed particle class for custom animation control
class _ManagedParticle {
  final double initialX;
  final double initialY;
  final double targetX;
  final double targetY;
  final Offset velocity;
  final _ParticleShape shape;
  final Color color;
  final double size;
  final double rotationSpeed;
  
  double currentX;
  double currentY;
  double currentRotation = 0;
  double opacity = 1.0;
  
  _ManagedParticle({
    required this.initialX,
    required this.initialY,
    required this.targetX,
    required this.targetY,
    required this.velocity,
    required this.shape,
    required this.color,
    required this.size,
    required this.rotationSpeed,
  }) : currentX = initialX, currentY = initialY;
}

// Custom painter for managed particles
class _ManagedParticlesPainter extends CustomPainter {
  final List<_ManagedParticle> particles;
  final double dispersalProgress;
  final double coalescenceProgress;
  final double magneticForce;
  final bool isCoalescencePhase;
  
  _ManagedParticlesPainter({
    required this.particles,
    required this.dispersalProgress,
    required this.coalescenceProgress,
    required this.magneticForce,
    required this.isCoalescencePhase,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      _updateParticlePosition(particle);
      _drawParticle(canvas, particle);
    }
  }
  
  void _updateParticlePosition(_ManagedParticle particle) {
    if (isCoalescencePhase) {
      // Magnetic attraction phase
      final dx = particle.targetX - particle.currentX;
      final dy = particle.targetY - particle.currentY;
      final distance = math.sqrt(dx * dx + dy * dy);
      
      if (distance > 1) {
        final normalizedDx = dx / distance;
        final normalizedDy = dy / distance;
        final attractionForce = magneticForce * 8;
        
        particle.currentX += normalizedDx * attractionForce;
        particle.currentY += normalizedDy * attractionForce;
        particle.opacity = math.max(0.0, 1.0 - coalescenceProgress * 0.8);
      } else {
        particle.opacity = math.max(0.0, 1.0 - coalescenceProgress);
      }
    } else {
      // Dispersal phase
      final timeProgress = dispersalProgress;
      final dispersalDistance = timeProgress * 150;
      
      particle.currentX = particle.initialX + 
          particle.velocity.dx * dispersalDistance * (1 - timeProgress * 0.5);
      particle.currentY = particle.initialY + 
          particle.velocity.dy * dispersalDistance * (1 - timeProgress * 0.5);
          
      particle.opacity = math.max(0.3, 1.0 - timeProgress * 0.4);
    }
    
    particle.currentRotation += particle.rotationSpeed;
  }
  
  void _drawParticle(Canvas canvas, _ManagedParticle particle) {
    if (particle.opacity <= 0.0) return;
    
    final paint = Paint()
      ..color = particle.color.withValues(alpha: particle.opacity)
      ..style = PaintingStyle.fill;
    
    canvas.save();
    canvas.translate(particle.currentX, particle.currentY);
    canvas.rotate(particle.currentRotation);
    
    final halfSize = particle.size / 2;
    
    switch (particle.shape) {
      case _ParticleShape.circle:
        canvas.drawCircle(Offset.zero, halfSize, paint);
        break;
      case _ParticleShape.star:
        _drawStar(canvas, paint, halfSize);
        break;
      case _ParticleShape.diamond:
        _drawDiamond(canvas, paint, halfSize);
        break;
      case _ParticleShape.triangle:
        _drawTriangle(canvas, paint, halfSize);
        break;
    }
    
    canvas.restore();
  }
  
  void _drawStar(Canvas canvas, Paint paint, double radius) {
    final path = Path();
    final spikes = 5;
    final innerRadius = radius * 0.4;
    
    for (int i = 0; i < spikes * 2; i++) {
      final angle = (i * math.pi) / spikes;
      final currentRadius = i.isEven ? radius : innerRadius;
      final x = currentRadius * math.cos(angle - math.pi / 2);
      final y = currentRadius * math.sin(angle - math.pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
  
  void _drawDiamond(Canvas canvas, Paint paint, double radius) {
    final path = Path();
    path.moveTo(0, -radius);
    path.lineTo(radius, 0);
    path.lineTo(0, radius);
    path.lineTo(-radius, 0);
    path.close();
    canvas.drawPath(path, paint);
  }
  
  void _drawTriangle(Canvas canvas, Paint paint, double radius) {
    final path = Path();
    final height = radius * math.sqrt(3) / 2;
    path.moveTo(0, -height);
    path.lineTo(-radius / 2, height / 2);
    path.lineTo(radius / 2, height / 2);
    path.close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant _ManagedParticlesPainter oldDelegate) {
    return oldDelegate.dispersalProgress != dispersalProgress ||
           oldDelegate.coalescenceProgress != coalescenceProgress ||
           oldDelegate.magneticForce != magneticForce ||
           oldDelegate.isCoalescencePhase != isCoalescencePhase;
  }
}
