import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:savessa/core/theme/app_theme.dart';

/// Ultra-modern kinetic text animation widget that creates sophisticated
/// text reveals with shimmer effects and typewriter animations.
/// 
/// Features:
/// - Staggered character animation with bounce effects
/// - Letter-by-letter fade-in with position animation
/// - Dynamic shimmer overlay using ShaderMask
/// - Typewriter effect for taglines
/// - Text shadows and glow effects matching brand colors
/// - Support for both app name and tagline with different timing
class KineticText extends StatefulWidget {
  final String text;
  final String? tagline;
  final Duration animationDelay;
  final Duration letterDelay;
  final Duration shimmerDelay;
  final TextStyle? textStyle;
  final TextStyle? taglineStyle;
  final bool enableShimmer;
  final bool enableGlow;
  final bool enableLottie;
  final VoidCallback? onAnimationComplete;

  const KineticText({
    super.key,
    required this.text,
    this.tagline,
    this.animationDelay = const Duration(milliseconds: 3000),
    this.letterDelay = const Duration(milliseconds: 120),
    this.shimmerDelay = const Duration(milliseconds: 800),
    this.textStyle,
    this.taglineStyle,
    this.enableShimmer = true,
    this.enableGlow = true,
    this.enableLottie = true,
    this.onAnimationComplete,
  });

  @override
  State<KineticText> createState() => _KineticTextState();
}

class _KineticTextState extends State<KineticText> 
    with TickerProviderStateMixin {
  
  late final AnimationController _mainController;
  late final AnimationController _shimmerController;
  late final AnimationController _glowController;
  late final AnimationController _taglineController;
  
  late final Animation<double> _shimmerAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _taglineAnimation;
  
  final List<AnimationController> _letterControllers = [];
  final List<Animation<double>> _letterAnimations = [];
  final List<Animation<Offset>> _letterPositionAnimations = [];
  final List<Animation<double>> _letterScaleAnimations = [];
  
  bool _animationStarted = false;
  bool _showLottieText = false;
  bool _taglineStarted = false;
  bool _isCompleted = false;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
    _startDelayedAnimation();
  }
  
  void _initializeControllers() {
    _mainController = AnimationController(
      duration: Duration(milliseconds: widget.text.length * widget.letterDelay.inMilliseconds + 1000),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _taglineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Create individual controllers for each letter
    for (int i = 0; i < widget.text.length; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      _letterControllers.add(controller);
    }
  }
  
  void _setupAnimations() {
    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOutSine,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOutSine,
    ));
    
    _taglineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeInOutQuart,
    ));
    
    // Setup individual letter animations
    for (int i = 0; i < _letterControllers.length; i++) {
      final controller = _letterControllers[i];
      
      _letterAnimations.add(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.elasticOut,
        )),
      );
      
      _letterPositionAnimations.add(
        Tween<Offset>(
          begin: const Offset(0, 0.8),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutBack,
        )),
      );
      
      _letterScaleAnimations.add(
        Tween<double>(
          begin: 0.3,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.elasticOut,
        )),
      );
    }
    
    // Setup listeners
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _startShimmerAndGlow();
      }
    });
    
    _shimmerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _startTaglineAnimation();
      }
    });
    
    _taglineController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _completeAnimation();
      }
    });
  }
  
  void _startDelayedAnimation() {
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        debugPrint('KineticText: Starting animation (enableLottie: ${widget.enableLottie})');
        setState(() {
          _animationStarted = true;
          _showLottieText = widget.enableLottie;
        });
        _animateLettersSequentially();
        _mainController.forward();
      }
    });
  }
  
  void _animateLettersSequentially() {
    for (int i = 0; i < _letterControllers.length; i++) {
      Future.delayed(
        Duration(milliseconds: i * widget.letterDelay.inMilliseconds),
        () {
          if (mounted) {
            _letterControllers[i].forward();
          }
        },
      );
    }
  }
  
  void _startShimmerAndGlow() {
    debugPrint('KineticText: Main text animation completed, starting shimmer and glow');
    if (widget.enableShimmer) {
      Future.delayed(widget.shimmerDelay, () {
        if (mounted) {
          debugPrint('KineticText: Starting shimmer');
          _shimmerController.forward();
        }
      });
    } else {
      _startTaglineAnimation();
    }
    
    if (widget.enableGlow) {
      _glowController.repeat(reverse: true);
    }
  }
  
  void _startTaglineAnimation() {
    debugPrint('KineticText: Shimmer completed, starting tagline');
    if (widget.tagline != null) {
      setState(() {
        _taglineStarted = true;
      });
      _taglineController.forward();
    } else {
      _completeAnimation();
    }
  }
  
  void _completeAnimation() {
    if (_isCompleted) return; // Prevent multiple calls
    _isCompleted = true;
    debugPrint('KineticText: All animations completed, calling callback');
    widget.onAnimationComplete?.call();
  }
  
  @override
  void dispose() {
    _mainController.dispose();
    _shimmerController.dispose();
    _glowController.dispose();
    _taglineController.dispose();
    for (final controller in _letterControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Main app name
        RepaintBoundary(
          child: _buildMainText(theme),
        ),
        
        if (widget.tagline != null) ...[
          const SizedBox(height: 16),
          // Tagline
          RepaintBoundary(
            child: _buildTagline(theme),
          ),
        ],
      ],
    );
  }
  
  Widget _buildMainText(ThemeData theme) {
    final defaultStyle = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppTheme.gold,
      shadows: widget.enableGlow ? [
        const Shadow(
          color: Colors.black26,
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ] : null,
    );
    
    final textStyle = widget.textStyle ?? defaultStyle;
    
    Widget textWidget;
    
    if (_showLottieText && widget.enableLottie) {
      // Use Lottie text animation if available
      textWidget = _buildLottieText(textStyle);
    } else {
      // Use custom kinetic text animation
      textWidget = _buildKineticText(textStyle);
    }
    
    if (widget.enableShimmer && _animationStarted) {
      textWidget = _buildShimmerEffect(textWidget);
    }
    
    if (widget.enableGlow && _animationStarted) {
      textWidget = _buildGlowEffect(textWidget);
    }
    
    return textWidget;
  }
  
  Widget _buildLottieText(TextStyle textStyle) {
    return SizedBox(
      height: textStyle.fontSize! * 1.5,
      child: Lottie.asset(
        'assets/animations/splash_text_reveal.json',
        fit: BoxFit.contain,
        animate: _animationStarted,
        repeat: false,
        onLoaded: (composition) {
          debugPrint('KineticText: Lottie animation loaded with duration: ${composition.duration.inMilliseconds}ms');
          // Don't call completion here - let the animation controllers handle the sequence
          // The Lottie animation is just for visual display
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('KineticText: Lottie failed to load, falling back to kinetic text');
          return _buildKineticText(textStyle);
        },
      ),
    );
  }
  
  Widget _buildKineticText(TextStyle textStyle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.text.split('').asMap().entries.map((entry) {
        final index = entry.key;
        final letter = entry.value;
        
        if (index < _letterAnimations.length) {
          return AnimatedBuilder(
            animation: Listenable.merge([
              _letterAnimations[index],
              _letterPositionAnimations[index],
              _letterScaleAnimations[index],
            ]),
            builder: (context, child) {
              return Transform.translate(
                offset: _letterPositionAnimations[index].value * 50,
                child: Transform.scale(
                  scale: _letterScaleAnimations[index].value,
                  child: Opacity(
                    opacity: _letterAnimations[index].value,
                    child: Text(
                      letter,
                      style: textStyle,
                    ),
                  ),
                ),
              );
            },
          );
        } else {
          return Text(letter, style: textStyle);
        }
      }).toList(),
    );
  }
  
  Widget _buildShimmerEffect(Widget child) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                AppTheme.lightGold,
                AppTheme.gold,
                AppTheme.lightGold,
                Colors.transparent,
              ],
              stops: [
                0.0,
                math.max(0.0, _shimmerAnimation.value - 0.3),
                _shimmerAnimation.value,
                math.min(1.0, _shimmerAnimation.value + 0.3),
                1.0,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
  
  Widget _buildGlowEffect(Widget child) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        final glowIntensity = _glowAnimation.value;
        
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withValues(alpha: 0.3 * glowIntensity),
                blurRadius: 20 * glowIntensity,
                spreadRadius: 5 * glowIntensity,
              ),
              BoxShadow(
                color: AppTheme.royalPurple.withValues(alpha: 0.2 * glowIntensity),
                blurRadius: 30 * glowIntensity,
                spreadRadius: 10 * glowIntensity,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
  
  Widget _buildTagline(ThemeData theme) {
    if (!_taglineStarted) return const SizedBox.shrink();
    
    final defaultTaglineStyle = TextStyle(
      fontSize: 16,
      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
      shadows: const [
        Shadow(
          color: Colors.black26,
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ],
    );
    
    final taglineStyle = widget.taglineStyle ?? defaultTaglineStyle;
    
    return AnimatedBuilder(
      animation: _taglineAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _taglineAnimation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _taglineAnimation.value) * 20),
            child: _buildTypewriterText(
              widget.tagline!,
              taglineStyle,
              _taglineAnimation.value,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTypewriterText(String text, TextStyle style, double progress) {
    final visibleLength = (text.length * progress).round();
    final visibleText = text.substring(0, visibleLength);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            visibleText,
            style: style,
            textAlign: TextAlign.center,
          ),
        ),
        // Blinking cursor
        if (progress < 1.0 && visibleLength < text.length)
          AnimatedBuilder(
            animation: _taglineController,
            builder: (context, child) {
              final blinkProgress = (_taglineController.value * 10) % 1;
              return Opacity(
                opacity: blinkProgress < 0.5 ? 1.0 : 0.0,
                child: Text(
                  '|',
                  style: style,
                ),
              );
            },
          ),
      ],
    );
  }
}
