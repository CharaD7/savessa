import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:savessa/core/theme/app_theme.dart';
import 'package:savessa/shared/widgets/particle_system_background.dart';
import 'package:savessa/shared/widgets/morphing_logo.dart';
import 'package:savessa/shared/widgets/kinetic_text.dart';

/// Ultra-modern splash screen with sophisticated morphing animations,
/// particle systems, and kinetic text effects.
/// 
/// Animation Timeline (Event-Driven):
/// - 0-500ms: Initialize, fade in background gradient
/// - 500ms+: Particle burst and dispersion (5 seconds at 60fps)
/// - Particles complete + 500ms: Morphing logo animation starts (3 seconds at 60fps)
/// - Logo complete + 500ms: Text animations trigger sequentially (2+ seconds)
/// - Text complete + 500ms: Final glow pulse (500ms)
/// - Final pulse complete + 300ms: Navigate to language screen
/// - Fallback: Maximum 12 seconds total before forced navigation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with TickerProviderStateMixin {
  
  late final AnimationController _backgroundController;
  late final AnimationController _finalPulseController;
  
  late final Animation<double> _backgroundAnimation;
  late final Animation<double> _finalPulseAnimation;
  
  // Animation phase states
  bool _particlesStarted = false;
  bool _logoStarted = false;
  bool _textStarted = false;
  bool _finalPulseStarted = false;
  bool _navigationCompleted = false;
  
  // Animation completion tracking
  bool _particlesCompleted = false;
  bool _logoCompleted = false;
  bool _textCompleted = false;
  bool _finalPulseCompleted = false;
  
  // Performance tracking
  final Stopwatch _animationStopwatch = Stopwatch();
  
  // Fallback timeout to ensure navigation always happens
  Timer? _fallbackTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
    _startAnimationSequence();
    _setupFallbackTimer();
  }
  
  void _initializeControllers() {
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _finalPulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }
  
  void _setupAnimations() {
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOutQuart,
    ));
    
    _finalPulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _finalPulseController,
      curve: Curves.easeInOutSine,
    ));
  }
  
  void _startAnimationSequence() {
    _animationStopwatch.start();
    
    // Phase 1: Background fade-in (0-500ms)
    _backgroundController.forward();
    
    // Phase 2: Start particles (500ms) - then wait for particles to complete
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _particlesStarted = true;
        });
      }
    });
  }
  
  void _navigateToNextScreen() {
    if (_navigationCompleted || !mounted) return;
    
    _navigationCompleted = true;
    _animationStopwatch.stop();
    _fallbackTimer?.cancel();
    
    // Log performance metrics and completion status in debug mode
    debugPrint('Splash animation completed in ${_animationStopwatch.elapsedMilliseconds}ms');
    debugPrint('Animation completion status: particles=$_particlesCompleted, logo=$_logoCompleted, text=$_textCompleted, pulse=$_finalPulseCompleted');
    
    context.go('/language');
  }
  
  void _onParticleAnimationComplete() {
    final elapsed = _animationStopwatch.elapsedMilliseconds;
    debugPrint('Particle animation phase completed at ${elapsed}ms');
    _particlesCompleted = true;
    _checkAndStartNextPhase();
  }
  
  void _onLogoAnimationComplete() {
    final elapsed = _animationStopwatch.elapsedMilliseconds;
    debugPrint('Logo morphing phase completed at ${elapsed}ms');
    _logoCompleted = true;
    _checkAndStartNextPhase();
  }
  
  void _onTextAnimationComplete() {
    final elapsed = _animationStopwatch.elapsedMilliseconds;
    debugPrint('Text animation phase completed at ${elapsed}ms');
    _textCompleted = true;
    _checkAndStartNextPhase();
  }
  
  void _checkAndStartNextPhase() {
    if (!mounted) return;
    
    final elapsed = _animationStopwatch.elapsedMilliseconds;
    
    // Phase 3: Start logo morphing after particles complete
    if (_particlesCompleted && !_logoStarted) {
      debugPrint('Starting logo phase at ${elapsed}ms (after particles)');
      // Add a small delay for visual flow (0.5s)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _logoStarted = true;
          });
          debugPrint('Logo phase started at ${_animationStopwatch.elapsedMilliseconds}ms');
        }
      });
    }
    
    // Phase 4: Start text animations after logo completes
    else if (_logoCompleted && !_textStarted) {
      debugPrint('Starting text phase at ${elapsed}ms (after logo)');
      // Add a small delay for visual flow (0.5s)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _textStarted = true;
          });
          debugPrint('Text phase started at ${_animationStopwatch.elapsedMilliseconds}ms');
        }
      });
    }
    
    // Phase 5: Start final pulse after text completes
    else if (_textCompleted && !_finalPulseStarted) {
      debugPrint('Starting final pulse at ${elapsed}ms (after text)');
      // Add a small delay before final pulse (0.5s)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _finalPulseStarted = true;
          });
          _finalPulseController.forward();
          debugPrint('Final pulse started at ${_animationStopwatch.elapsedMilliseconds}ms');
          
          // Set up listener for final pulse completion
          _finalPulseController.addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _finalPulseCompleted = true;
              final finalElapsed = _animationStopwatch.elapsedMilliseconds;
              debugPrint('Final pulse completed at ${finalElapsed}ms');
              // Add a longer hold to let users appreciate the full animation (2s)
              Future.delayed(const Duration(milliseconds: 2000), () {
                _navigateToNextScreen();
              });
            }
          });
        }
      });
    }
  }
  
  void _setupFallbackTimer() {
    // Fallback timer to ensure navigation happens even if animations fail
    // Set to 20 seconds maximum (generous allowance for slow devices and complex animations)
    _fallbackTimer = Timer(const Duration(seconds: 20), () {
      if (!_navigationCompleted && mounted) {
        debugPrint('Fallback timer triggered - forcing navigation after 20 seconds');
        debugPrint('Final animation states: particles=$_particlesCompleted, logo=$_logoCompleted, text=$_textCompleted, pulse=$_finalPulseCompleted');
        _navigateToNextScreen();
      }
    });
  }
  
  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _backgroundController.dispose();
    _finalPulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    
    // Check for reduced motion accessibility setting
    final reduceMotion = mediaQuery.disableAnimations;
    
    if (reduceMotion) {
      return _buildReducedMotionSplash(context);
    }
    
    return PopScope(
      canPop: false, // Prevent back navigation during splash
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _backgroundAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.royalPurple.withValues(alpha: _backgroundAnimation.value),
                    AppTheme.lightPurple.withValues(alpha: _backgroundAnimation.value * 0.8),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Particle system background
                  if (_particlesStarted)
                    Positioned.fill(
                      child: ParticleSystemBackground(
                        width: screenSize.width,
                        height: screenSize.height,
                        centerAlignment: Alignment.center,
                        enableCoalescence: true,
                        onAnimationComplete: _onParticleAnimationComplete,
                      ),
                    ),
                  
                  // Main content
                  Positioned.fill(
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),
                          
                          // Morphing logo
                          if (_logoStarted)
                            MorphingLogo(
                              size: _getResponsiveLogoSize(screenSize),
                              animationDelay: Duration.zero, // Already delayed in sequence
                              animationDuration: const Duration(milliseconds: 2000),
                              enableParticleTrails: true,
                              enableGlowEffect: true,
                              onAnimationComplete: _onLogoAnimationComplete,
                            ),
                          
                          if (_logoStarted)
                            const SizedBox(height: 32),
                          
                          // Kinetic text
                          if (_textStarted)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32.0),
                              child: KineticText(
                                text: 'Savessa',
                                tagline: 'Welcome to Savessa – Your Community Savings Companion.',
                                animationDelay: Duration.zero, // Already delayed in sequence
                                letterDelay: const Duration(milliseconds: 100),
                                shimmerDelay: const Duration(milliseconds: 600),
                                enableShimmer: true,
                                enableGlow: true,
                                enableLottie: true,
                                onAnimationComplete: _onTextAnimationComplete,
                                textStyle: TextStyle(
                                  fontSize: _getResponsiveTextSize(screenSize),
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.gold,
                                ),
                                taglineStyle: TextStyle(
                                  fontSize: _getResponsiveTaglineSize(screenSize),
                                  color: AppTheme.white.withValues(alpha: 0.92),
                                ),
                              ),
                            ),
                          
                          const Spacer(flex: 3),
                        ],
                      ),
                    ),
                  ),
                  
                  // Final pulse overlay
                  if (_finalPulseStarted)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _finalPulseAnimation,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 1.5,
                                colors: [
                                  AppTheme.gold.withValues(alpha: 0.1 * _finalPulseAnimation.value),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  
                  // Skip button (hidden, for testing)
                  if (kDebugMode)
                    Positioned(
                      top: 50,
                      right: 20,
                      child: GestureDetector(
                        onTap: _navigateToNextScreen,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildReducedMotionSplash(BuildContext context) {
    // Simple, accessible splash screen for users with motion sensitivity
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.royalPurple, AppTheme.lightPurple],
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Static logo
                SizedBox(
                  width: 180,
                  height: 180,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.royalPurple,
                      borderRadius: BorderRadius.all(Radius.circular(36)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32),
                
                // App name
                Text(
                  'Savessa',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gold,
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Tagline
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Welcome to Savessa – Your Community Savings Companion.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  double _getResponsiveLogoSize(Size screenSize) {
    if (screenSize.width < 375) return 140; // Small phones
    if (screenSize.width < 414) return 160; // Medium phones
    return 180; // Large phones and tablets
  }
  
  double _getResponsiveTextSize(Size screenSize) {
    if (screenSize.width < 375) return 28;
    if (screenSize.width < 414) return 30;
    return 32;
  }
  
  double _getResponsiveTaglineSize(Size screenSize) {
    if (screenSize.width < 375) return 14;
    if (screenSize.width < 414) return 15;
    return 16;
  }
}
