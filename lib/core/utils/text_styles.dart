import 'package:flutter/material.dart';

/// Utility class for text styling
class TextStyles {
  /// Creates a TextStyle with white text and bold orange outline for notification messages
  /// 
  /// The [baseStyle] parameter is the base TextStyle to apply the styling to.
  /// If null, a default TextStyle will be used.
  static TextStyle withGlow({
    TextStyle? baseStyle,
  }) {
    // Use a bright orange color for the outline to match notification SnackBars
    const Color notificationOutlineColor = Color(0xFFFF9800); // Bright orange
    
    // Default base style if none provided
    final style = baseStyle ?? const TextStyle();
    
    // Create shadows in multiple directions to form an outline
    final List<Shadow> outlineShadows = [
      Shadow(color: notificationOutlineColor, blurRadius: 0, offset: const Offset(-1, -1)),
      Shadow(color: notificationOutlineColor, blurRadius: 0, offset: const Offset(1, -1)),
      Shadow(color: notificationOutlineColor, blurRadius: 0, offset: const Offset(-1, 1)),
      Shadow(color: notificationOutlineColor, blurRadius: 0, offset: const Offset(1, 1)),
      Shadow(color: notificationOutlineColor, blurRadius: 0, offset: const Offset(0, -1)),
      Shadow(color: notificationOutlineColor, blurRadius: 0, offset: const Offset(-1, 0)),
      Shadow(color: notificationOutlineColor, blurRadius: 0, offset: const Offset(1, 0)),
      Shadow(color: notificationOutlineColor, blurRadius: 0, offset: const Offset(0, 1)),
    ];
    
    // Return the style with white color, bold font weight, increased font size, and outline shadows
    return style.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: (style.fontSize ?? 14) + 1, // Increase font size by 1 point
      shadows: outlineShadows,
    );
  }
  
  /// Creates a TextStyle specifically for phone number error messages
  /// with red text color, bold font, and reduced font size
  static TextStyle phoneErrorStyle({TextStyle? baseStyle}) {
    // Default base style if none provided
    final style = baseStyle ?? const TextStyle();
    
    // Return the style with red color, bold font weight, and reduced font size
    return style.copyWith(
      color: Colors.red,
      fontWeight: FontWeight.bold,
      fontSize: (style.fontSize ?? 14) - 1, // Reduce font size by 1 point
    );
  }
  
  /// Creates a TextStyle specifically for error messages with white text and bold red outline
  static TextStyle errorWithGlow({TextStyle? baseStyle}) {
    // Use a bright red color for the outline
    const Color errorOutlineColor = Color(0xFFFF0000); // Bright red
    
    // Default base style if none provided
    final style = baseStyle ?? const TextStyle();
    
    // Create shadows in multiple directions to form an outline
    final List<Shadow> outlineShadows = [
      Shadow(color: errorOutlineColor, blurRadius: 0, offset: const Offset(-1, -1)),
      Shadow(color: errorOutlineColor, blurRadius: 0, offset: const Offset(1, -1)),
      Shadow(color: errorOutlineColor, blurRadius: 0, offset: const Offset(-1, 1)),
      Shadow(color: errorOutlineColor, blurRadius: 0, offset: const Offset(1, 1)),
      Shadow(color: errorOutlineColor, blurRadius: 0, offset: const Offset(0, -1)),
      Shadow(color: errorOutlineColor, blurRadius: 0, offset: const Offset(-1, 0)),
      Shadow(color: errorOutlineColor, blurRadius: 0, offset: const Offset(1, 0)),
      Shadow(color: errorOutlineColor, blurRadius: 0, offset: const Offset(0, 1)),
    ];
    
    // Return the style with white color, bold font weight, increased font size, and outline shadows
    return style.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: (style.fontSize ?? 14) + 1, // Increase font size by 1 point
      shadows: outlineShadows,
    );
  }
  
  /// Creates a TextStyle specifically for success messages with white text and bold green outline
  static TextStyle successWithGlow({TextStyle? baseStyle}) {
    // Use a bright green color for the outline
    const Color successOutlineColor = Color(0xFF00AA00); // Bright green
    
    // Default base style if none provided
    final style = baseStyle ?? const TextStyle();
    
    // Create shadows in multiple directions to form an outline
    final List<Shadow> outlineShadows = [
      Shadow(color: successOutlineColor, blurRadius: 0, offset: const Offset(-1, -1)),
      Shadow(color: successOutlineColor, blurRadius: 0, offset: const Offset(1, -1)),
      Shadow(color: successOutlineColor, blurRadius: 0, offset: const Offset(-1, 1)),
      Shadow(color: successOutlineColor, blurRadius: 0, offset: const Offset(1, 1)),
      Shadow(color: successOutlineColor, blurRadius: 0, offset: const Offset(0, -1)),
      Shadow(color: successOutlineColor, blurRadius: 0, offset: const Offset(-1, 0)),
      Shadow(color: successOutlineColor, blurRadius: 0, offset: const Offset(1, 0)),
      Shadow(color: successOutlineColor, blurRadius: 0, offset: const Offset(0, 1)),
    ];
    
    // Return the style with white color, bold font weight, increased font size, and outline shadows
    return style.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: (style.fontSize ?? 14) + 1, // Increase font size by 1 point
      shadows: outlineShadows,
    );
  }
}