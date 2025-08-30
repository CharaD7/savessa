import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Animation performance monitoring and optimization utilities for the Savessa app.
/// 
/// Features:
/// - FPS monitoring during development
/// - Device performance detection and auto-adjustment
/// - Animation quality settings (High/Medium/Low)
/// - Strategic RepaintBoundary usage
/// - Lifecycle management utilities
class AnimationPerformance {
  static AnimationPerformance? _instance;
  static AnimationPerformance get instance => _instance ??= AnimationPerformance._();
  
  AnimationPerformance._();
  
  // Performance tracking
  final List<double> _fpsHistory = [];
  double _averageFps = 60.0;
  AnimationQuality _currentQuality = AnimationQuality.high;
  DevicePerformance _detectedPerformance = DevicePerformance.unknown;
  
  // FPS monitoring
  int _frameCount = 0;
  Duration _lastFrameTime = Duration.zero;
  final Duration _fpsCheckInterval = const Duration(seconds: 1);
  
  /// Current animation quality setting
  AnimationQuality get currentQuality => _currentQuality;
  
  /// Detected device performance level
  DevicePerformance get detectedPerformance => _detectedPerformance;
  
  /// Current average FPS
  double get averageFps => _averageFps;
  
  /// Initialize performance monitoring
  void initialize() {
    if (kDebugMode) {
      _startFpsMonitoring();
    }
    _detectDevicePerformance();
  }
  
  /// Start FPS monitoring (debug mode only)
  void _startFpsMonitoring() {
    if (!kDebugMode) return;
    
    SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
      for (final timing in timings) {
        _recordFrameTime(timing);
      }
    });
  }
  
  void _recordFrameTime(FrameTiming timing) {
    _frameCount++;
    final currentTime = timing.buildDuration.inMicroseconds + timing.rasterDuration.inMicroseconds;
    
    if (_lastFrameTime == Duration.zero) {
      _lastFrameTime = Duration(microseconds: currentTime);
      return;
    }
    
    final deltaTime = Duration(microseconds: currentTime) - _lastFrameTime;
    
    if (deltaTime >= _fpsCheckInterval) {
      final fps = _frameCount / (deltaTime.inMilliseconds / 1000.0);
      _fpsHistory.add(fps);
      
      // Keep only the last 10 measurements
      if (_fpsHistory.length > 10) {
        _fpsHistory.removeAt(0);
      }
      
      _averageFps = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
      
      // Auto-adjust quality based on performance
      _autoAdjustQuality();
      
      // Log performance in debug mode
      if (kDebugMode) {
        developer.log('FPS: ${fps.toStringAsFixed(1)}, Avg: ${_averageFps.toStringAsFixed(1)}', name: 'AnimationPerformance');
      }
      
      _frameCount = 0;
      _lastFrameTime = Duration(microseconds: currentTime);
    }
  }
  
  /// Detect device performance level
  void _detectDevicePerformance() {
    // Use WidgetsBinding to get performance information
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final devicePixelRatio = view.devicePixelRatio;
      final screenSize = view.physicalSize;
      final screenArea = screenSize.width * screenSize.height;
      
      // Rough performance categorization based on screen specs
      if (devicePixelRatio >= 3.0 && screenArea > 2000000) {
        _detectedPerformance = DevicePerformance.high;
        _currentQuality = AnimationQuality.high;
      } else if (devicePixelRatio >= 2.0 && screenArea > 1000000) {
        _detectedPerformance = DevicePerformance.medium;
        _currentQuality = AnimationQuality.medium;
      } else {
        _detectedPerformance = DevicePerformance.low;
        _currentQuality = AnimationQuality.low;
      }
      
      if (kDebugMode) {
        developer.log('Device Performance: $_detectedPerformance, Quality: $_currentQuality', name: 'AnimationPerformance');
      }
    });
  }
  
  /// Auto-adjust animation quality based on performance
  void _autoAdjustQuality() {
    if (_averageFps < 30 && _currentQuality != AnimationQuality.low) {
      _currentQuality = AnimationQuality.low;
      if (kDebugMode) {
        developer.log('Auto-reduced quality to LOW due to low FPS', name: 'AnimationPerformance');
      }
    } else if (_averageFps < 45 && _currentQuality == AnimationQuality.high) {
      _currentQuality = AnimationQuality.medium;
      if (kDebugMode) {
        developer.log('Auto-reduced quality to MEDIUM due to moderate FPS', name: 'AnimationPerformance');
      }
    } else if (_averageFps > 55 && _detectedPerformance == DevicePerformance.high && _currentQuality != AnimationQuality.high) {
      _currentQuality = AnimationQuality.high;
      if (kDebugMode) {
        developer.log('Auto-increased quality to HIGH due to good FPS', name: 'AnimationPerformance');
      }
    }
  }
  
  /// Manually set animation quality
  void setQuality(AnimationQuality quality) {
    _currentQuality = quality;
    if (kDebugMode) {
      developer.log('Animation quality manually set to: $quality', name: 'AnimationPerformance');
    }
  }
  
  /// Get optimized particle count based on current quality
  int getOptimizedParticleCount(int baseCount) {
    switch (_currentQuality) {
      case AnimationQuality.high:
        return baseCount;
      case AnimationQuality.medium:
        return (baseCount * 0.6).round();
      case AnimationQuality.low:
        return (baseCount * 0.3).round();
    }
  }
  
  /// Get optimized frame rate based on current quality
  int getOptimizedFrameRate() {
    switch (_currentQuality) {
      case AnimationQuality.high:
        return 60;
      case AnimationQuality.medium:
        return 30;
      case AnimationQuality.low:
        return 24;
    }
  }
  
  /// Check if advanced effects should be enabled
  bool shouldEnableAdvancedEffects() {
    return _currentQuality == AnimationQuality.high;
  }
  
  /// Check if glow effects should be enabled
  bool shouldEnableGlowEffects() {
    return _currentQuality != AnimationQuality.low;
  }
  
  /// Check if particle trails should be enabled
  bool shouldEnableParticleTrails() {
    return _currentQuality != AnimationQuality.low;
  }
  
  /// Get animation duration multiplier for current quality
  double getAnimationDurationMultiplier() {
    switch (_currentQuality) {
      case AnimationQuality.high:
        return 1.0;
      case AnimationQuality.medium:
        return 0.8;
      case AnimationQuality.low:
        return 0.6;
    }
  }
  
  /// Check if we should use RepaintBoundary for a widget
  bool shouldUseRepaintBoundary() {
    return true; // Always use RepaintBoundary for performance
  }
  
  /// Get performance report for debugging
  Map<String, dynamic> getPerformanceReport() {
    return {
      'averageFps': _averageFps,
      'currentQuality': _currentQuality.toString(),
      'detectedPerformance': _detectedPerformance.toString(),
      'fpsHistory': _fpsHistory,
      'frameCount': _frameCount,
    };
  }
  
  /// Reset performance tracking
  void reset() {
    _fpsHistory.clear();
    _frameCount = 0;
    _lastFrameTime = Duration.zero;
    _averageFps = 60.0;
  }
}

/// Animation quality levels
enum AnimationQuality {
  high,   // Full effects, all particles, complex shaders
  medium, // Reduced particles, simplified effects
  low,    // Basic animations only, minimal effects
}

/// Device performance categories
enum DevicePerformance {
  unknown,
  low,    // Older/budget devices
  medium, // Mid-range devices  
  high,   // Flagship devices
}

/// Mixin for widgets that need performance-aware animations
mixin AnimationPerformanceMixin {
  AnimationPerformance get performance => AnimationPerformance.instance;
  
  /// Create a performance-optimized RepaintBoundary
  Widget buildOptimizedRepaintBoundary({
    required Widget child,
    String? debugLabel,
  }) {
    if (performance.shouldUseRepaintBoundary()) {
      return RepaintBoundary(
        child: child,
      );
    }
    return child;
  }
  
  /// Get optimized animation duration
  Duration getOptimizedDuration(Duration baseDuration) {
    final multiplier = performance.getAnimationDurationMultiplier();
    return Duration(
      milliseconds: (baseDuration.inMilliseconds * multiplier).round(),
    );
  }
  
  /// Check if this animation should be enabled based on current quality
  bool shouldEnableAnimation(AnimationComplexity complexity) {
    switch (complexity) {
      case AnimationComplexity.simple:
        return true; // Always enable simple animations
      case AnimationComplexity.moderate:
        return performance.currentQuality != AnimationQuality.low;
      case AnimationComplexity.complex:
        return performance.currentQuality == AnimationQuality.high;
    }
  }
}

/// Animation complexity levels
enum AnimationComplexity {
  simple,   // Basic fade/scale animations
  moderate, // Multiple concurrent animations
  complex,  // Particle systems, advanced effects
}

/// Lifecycle management utilities for animations
class AnimationLifecycleManager {
  final List<AnimationController> _controllers = [];
  final List<VoidCallback> _disposeCallbacks = [];
  
  /// Register an animation controller for automatic disposal
  void registerController(AnimationController controller) {
    _controllers.add(controller);
  }
  
  /// Register a dispose callback
  void registerDisposeCallback(VoidCallback callback) {
    _disposeCallbacks.add(callback);
  }
  
  /// Dispose all registered controllers and callbacks
  void disposeAll() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    
    for (final callback in _disposeCallbacks) {
      callback();
    }
    _disposeCallbacks.clear();
  }
  
  /// Pause all registered controllers
  void pauseAll() {
    for (final controller in _controllers) {
      controller.stop();
    }
  }
  
  /// Resume all registered controllers
  void resumeAll() {
    for (final controller in _controllers) {
      if (!controller.isCompleted) {
        controller.forward();
      }
    }
  }
}
