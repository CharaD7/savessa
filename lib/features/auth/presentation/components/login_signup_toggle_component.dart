import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

/// A reusable component that provides a toggle between login and signup modes
/// or navigation links between login and register screens.
class LoginSignupToggleComponent extends StatelessWidget {
  /// The current mode, either 'login' or 'signup'.
  final String mode;
  
  /// Callback function when the mode is toggled.
  /// If null, the component will use navigation instead of toggling.
  final VoidCallback? onToggle;
  
  /// The selected role to pass to the navigation route.
  final String? selectedRole;
  
  /// Whether to use a tab-style toggle (true) or a text link (false).
  final bool useTabStyle;
  
  /// Optional custom text style for the active tab/link.
  final TextStyle? activeTextStyle;
  
  /// Optional custom text style for the inactive tab/link.
  final TextStyle? inactiveTextStyle;
  
  /// Optional custom background color for the active tab.
  final Color? activeBackgroundColor;
  
  /// Optional custom background color for the container.
  final Color? backgroundColor;
  
  const LoginSignupToggleComponent({
    super.key,
    required this.mode,
    this.onToggle,
    this.selectedRole,
    this.useTabStyle = true,
    this.activeTextStyle,
    this.inactiveTextStyle,
    this.activeBackgroundColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // If using tab style, build a container with two tabs
    if (useTabStyle) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Login tab
            GestureDetector(
              onTap: () {
                if (mode != 'login') {
                  if (onToggle != null) {
                    onToggle!();
                  } else {
                    context.go('/login', extra: selectedRole);
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: mode == 'login' 
                      ? (activeBackgroundColor ?? theme.colorScheme.secondary)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Login',
                  style: mode == 'login'
                      ? (activeTextStyle ?? TextStyle(
                          color: theme.colorScheme.onSecondary,
                          fontWeight: FontWeight.bold,
                        ))
                      : (inactiveTextStyle ?? TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        )),
                ),
              ),
            ),
            
            // Signup tab
            GestureDetector(
              onTap: () {
                if (mode != 'signup') {
                  if (onToggle != null) {
                    onToggle!();
                  } else {
                    context.go('/register', extra: selectedRole);
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: mode != 'login' 
                      ? (activeBackgroundColor ?? theme.colorScheme.secondary)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Sign Up',
                  style: mode != 'login'
                      ? (activeTextStyle ?? TextStyle(
                          color: theme.colorScheme.onSecondary,
                          fontWeight: FontWeight.bold,
                        ))
                      : (inactiveTextStyle ?? TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        )),
                ),
              ),
            ),
          ],
        ),
      );
    } 
    // Otherwise, build a simple text link
    else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mode == 'login' 
                  ? 'auth.no_account'.tr() 
                  : 'auth.have_account'.tr(),
              style: inactiveTextStyle ?? TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 14,
              ),
            ),
            TextButton(
              onPressed: () {
                if (onToggle != null) {
                  onToggle!();
                } else {
                  if (mode == 'login') {
                    context.go('/register', extra: selectedRole);
                  } else {
                    context.go('/login', extra: selectedRole);
                  }
                }
              },
              child: Text(
                mode == 'login' ? 'auth.sign_up'.tr() : 'auth.sign_in'.tr(),
                style: activeTextStyle ?? TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}