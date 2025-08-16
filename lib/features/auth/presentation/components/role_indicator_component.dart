import 'package:flutter/material.dart';
import 'package:savessa/core/constants/icon_mapping.dart';

/// A reusable component that displays the selected role (Savings Manager or Savings Contributor)
/// with an icon and text.
class RoleIndicatorComponent extends StatelessWidget {
  /// The selected role, either 'admin' for Savings Manager or any other value for Savings Contributor.
  final String selectedRole;
  
  /// Optional prefix text to display before the role name.
  /// For example, "Setting up as:" or "Logging in as:".
  final String? prefix;
  
  /// Optional custom text style for the role text.
  final TextStyle? textStyle;
  
  /// Optional custom icon color.
  final Color? iconColor;
  
  /// Optional custom background color.
  final Color? backgroundColor;
  
  /// Optional custom border color.
  final Color? borderColor;
  
  const RoleIndicatorComponent({
    super.key,
    required this.selectedRole,
    this.prefix,
    this.textStyle,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            IconMapping.person,
            color: iconColor ?? theme.colorScheme.secondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getRoleText(),
              style: textStyle ?? const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Returns the appropriate role text based on the selected role and prefix.
  String _getRoleText() {
    final roleText = selectedRole == 'admin'
        ? 'Savings Manager'
        : 'Savings Contributor';
    
    if (prefix != null && prefix!.isNotEmpty) {
      return '$prefix $roleText';
    }
    
    return 'Setting up as: $roleText';
  }
}