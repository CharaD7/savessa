import 'package:flutter/material.dart';

/// Utility class for text styling
class TextStyles {
  /// Creates a TextStyle with a standard style for general messages
  /// 
  /// The [baseStyle] parameter is the base TextStyle to apply the styling to.
  /// If null, a default TextStyle will be used.
  static TextStyle withGlow({
    TextStyle? baseStyle,
  }) {
    // Default base style if none provided
    final style = baseStyle ?? const TextStyle();
    
    // Return the base style with bold font weight
    return style.copyWith(
      fontWeight: FontWeight.bold,
    );
  }
  
  /// Creates a TextStyle specifically for error messages with a lighter shade of red and bold font
  static TextStyle errorWithGlow({TextStyle? baseStyle}) {
    // Use a lighter shade of red that's more visible
    const Color lightRed = Color(0xFFFF6B6B); // Lighter shade of red
    
    // Default base style if none provided
    final style = baseStyle ?? const TextStyle();
    
    // Return the style with color and bold font weight
    return style.copyWith(
      color: lightRed,
      fontWeight: FontWeight.bold,
    );
  }
  
  /// Creates a TextStyle specifically for success messages with a lighter shade of green and bold font
  static TextStyle successWithGlow({TextStyle? baseStyle}) {
    // Use a lighter shade of green that's more visible
    const Color lightGreen = Color(0xFF7CFC00); // Lighter shade of green (LawnGreen)
    
    // Default base style if none provided
    final style = baseStyle ?? const TextStyle();
    
    // Return the style with color and bold font weight
    return style.copyWith(
      color: lightGreen,
      fontWeight: FontWeight.bold,
    );
  }
}