import 'package:flutter/material.dart';

/// A widget that displays the current digit count and required count for a phone number
/// with animated color transition from red to green based on progress.
class PhoneNumberCountIndicator extends StatefulWidget {
  /// The current number of digits in the phone number
  final int currentCount;
  
  /// The required number of digits for the selected country
  final int requiredCount;
  
  /// Whether the maximum count has been reached
  final bool isMaxReached;
  
  /// Constructor
  const PhoneNumberCountIndicator({
    super.key,
    required this.currentCount,
    required this.requiredCount,
    this.isMaxReached = false,
  });
  
  @override
  State<PhoneNumberCountIndicator> createState() => _PhoneNumberCountIndicatorState();
}

class _PhoneNumberCountIndicatorState extends State<PhoneNumberCountIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _progressAnimation;
  
  int _previousCount = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Initialize animations with 30% smaller scale as per requirements
    _scaleAnimation = Tween<double>(begin: 0.7, end: 0.84).animate(  // 0.7 is 30% smaller than 1.0, 0.84 is 30% smaller than 1.2
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Initial color animation (will be updated in didUpdateWidget)
    _colorAnimation = ColorTween(
      begin: _getColorForProgress(0),
      end: _getColorForProgress(0),
    ).animate(_animationController);
    
    // Initial progress animation (will be updated in didUpdateWidget)
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_animationController);
    
    // Store initial count
    _previousCount = widget.currentCount;
  }
  
  @override
  void didUpdateWidget(PhoneNumberCountIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If count changed, animate
    if (widget.currentCount != _previousCount) {
      // Calculate progress
      final progress = widget.requiredCount > 0 
          ? (widget.currentCount / widget.requiredCount).clamp(0.0, 1.0) 
          : 0.0;
      
      final oldProgress = widget.requiredCount > 0 
          ? (_previousCount / widget.requiredCount).clamp(0.0, 1.0) 
          : 0.0;
      
      // Update color animation
      _colorAnimation = ColorTween(
        begin: _getColorForProgress(oldProgress),
        end: _getColorForProgress(progress),
      ).animate(_animationController);
      
      // Update progress animation
      _progressAnimation = Tween<double>(
        begin: oldProgress,
        end: progress,
      ).animate(_animationController);
      
      // Reset and start animation
      _animationController.reset();
      _animationController.forward();
      
      // Update previous count
      _previousCount = widget.currentCount;
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Calculate progress for initial render
    final progress = widget.requiredCount > 0 
        ? (widget.currentCount / widget.requiredCount).clamp(0.0, 1.0) 
        : 0.0;
    
    // Get color for initial render
    final color = _getColorForProgress(progress);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Use animated values if animation is running, otherwise use calculated values
        final displayColor = _animationController.isAnimating 
            ? _colorAnimation.value ?? color
            : color;
        
        final scale = widget.isMaxReached 
            ? _scaleAnimation.value 
            : 0.7;  // 30% smaller than 1.0 as per requirements
        
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: displayColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: displayColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: displayColor.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Count text with animated color
                Text(
                  '${widget.currentCount}/${widget.requiredCount}',
                  style: TextStyle(
                    color: displayColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                
                // No icons as per requirements
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Returns a color based on the progress (0.0 to 1.0)
  /// - Red (0.0) -> Yellow (0.5) -> Green (1.0)
  Color _getColorForProgress(double progress) {
    if (progress >= 1.0) {
      // Max reached - green
      return Colors.green;
    } else if (progress >= 0.7) {
      // Almost there - yellow-green
      return Color.lerp(Colors.yellow, Colors.green, (progress - 0.7) / 0.3)!;
    } else if (progress >= 0.3) {
      // Making progress - yellow
      return Color.lerp(Colors.orange, Colors.yellow, (progress - 0.3) / 0.4)!;
    } else if (progress > 0.0) {
      // Just started - orange-red
      return Color.lerp(Colors.red, Colors.orange, progress / 0.3)!;
    } else {
      // No progress - red
      return Colors.red;
    }
  }
}