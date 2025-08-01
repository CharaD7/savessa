import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/constants/icon_mapping.dart';

/// A reusable role type indicator component that can be used across different screens.
class RoleTypeIndicator extends StatelessWidget {
  /// The role of the user (e.g., 'admin', 'member')
  final String role;
  
  /// The prefix text to display before the role (e.g., 'Setting up as:', 'Logging in as:')
  final String? prefix;
  
  /// The color scheme to use for the indicator
  final ColorScheme? colorScheme;
  
  /// The icon to display
  final IconData? icon;
  
  /// The background color of the container
  final Color? backgroundColor;
  
  /// The border color of the container
  final Color? borderColor;
  
  /// The text color
  final Color? textColor;
  
  /// The icon color
  final Color? iconColor;
  
  /// The font size of the text
  final double fontSize;
  
  /// The font weight of the text
  final FontWeight fontWeight;
  
  /// The padding of the container
  final EdgeInsetsGeometry padding;
  
  /// The border radius of the container
  final double borderRadius;

  const RoleTypeIndicator({
    super.key,
    required this.role,
    this.prefix,
    this.colorScheme,
    this.icon,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.iconColor,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w500,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColorScheme = colorScheme ?? theme.colorScheme;
    
    // Determine the role text based on the role
    String roleText;
    if (role == 'admin') {
      roleText = 'auth.role_savings_manager'.tr();
    } else {
      roleText = 'auth.role_savings_contributor'.tr();
    }
    
    // Add prefix if provided
    if (prefix != null && prefix!.isNotEmpty) {
      roleText = '$prefix $roleText';
    }
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? IconMapping.person,
            color: iconColor ?? effectiveColorScheme.secondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              roleText,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}