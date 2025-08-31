import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:savessa/core/theme/app_theme.dart';

/// A widget that displays password strength and requirements
class PasswordStrengthWidget extends StatelessWidget {
  final String password;
  final bool showRequirements;

  const PasswordStrengthWidget({
    super.key,
    required this.password,
    this.showRequirements = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strength = _calculatePasswordStrength(password);
    final requirements = _getPasswordRequirements(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Password strength indicator
        _buildStrengthIndicator(theme, strength),
        
        if (showRequirements && password.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'auth.password_requirements_title'.tr(),
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...requirements.map((requirement) => _buildRequirementItem(
            theme,
            requirement.text,
            requirement.isMet,
          )),
        ],
      ],
    );
  }

  Widget _buildStrengthIndicator(ThemeData theme, PasswordStrength strength) {
    final strengthText = _getStrengthText(strength);
    final strengthColor = _getStrengthColor(strength);
    final progress = _getStrengthProgress(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password Strength',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              strengthText,
              style: TextStyle(
                color: strengthColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          minHeight: 3,
        ),
      ],
    );
  }

  Widget _buildRequirementItem(ThemeData theme, String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? Colors.green : Colors.white.withValues(alpha: 0.6),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isMet ? Colors.green : Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                decoration: isMet ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    
    int score = 0;
    
    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // Character variety checks
    if (password.contains(RegExp(r'[a-z]'))) score++; // Lowercase
    if (password.contains(RegExp(r'[A-Z]'))) score++; // Uppercase
    if (password.contains(RegExp(r'[0-9]'))) score++; // Numbers
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++; // Special chars
    
    // Additional complexity checks
    if (password.length >= 16) score++;
    if (RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*])').hasMatch(password)) {
      score++; // All character types present
    }
    
    switch (score) {
      case 0:
      case 1:
      case 2:
        return PasswordStrength.weak;
      case 3:
      case 4:
        return PasswordStrength.fair;
      case 5:
      case 6:
        return PasswordStrength.good;
      default:
        return PasswordStrength.strong;
    }
  }

  List<PasswordRequirement> _getPasswordRequirements(String password) {
    return [
      PasswordRequirement(
        text: 'auth.password_requirement_length'.tr(),
        isMet: password.length >= 8,
      ),
      PasswordRequirement(
        text: 'auth.password_requirement_lowercase'.tr(),
        isMet: password.contains(RegExp(r'[a-z]')),
      ),
      PasswordRequirement(
        text: 'auth.password_requirement_uppercase'.tr(),
        isMet: password.contains(RegExp(r'[A-Z]')),
      ),
      PasswordRequirement(
        text: 'auth.password_requirement_number'.tr(),
        isMet: password.contains(RegExp(r'[0-9]')),
      ),
      PasswordRequirement(
        text: 'auth.password_requirement_special'.tr(),
        isMet: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      ),
    ];
  }

  String _getStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.none:
        return '';
      case PasswordStrength.weak:
        return 'auth.password_strength_weak'.tr();
      case PasswordStrength.fair:
        return 'auth.password_strength_fair'.tr();
      case PasswordStrength.good:
        return 'auth.password_strength_good'.tr();
      case PasswordStrength.strong:
        return 'auth.password_strength_strong'.tr();
    }
  }

  Color _getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.none:
        return Colors.transparent;
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.fair:
        return Colors.orange;
      case PasswordStrength.good:
        return AppTheme.gold;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  double _getStrengthProgress(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.none:
        return 0.0;
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.fair:
        return 0.5;
      case PasswordStrength.good:
        return 0.75;
      case PasswordStrength.strong:
        return 1.0;
    }
  }
}

/// Enum representing password strength levels
enum PasswordStrength {
  none,
  weak,
  fair,
  good,
  strong,
}

/// Class representing a password requirement
class PasswordRequirement {
  final String text;
  final bool isMet;

  const PasswordRequirement({
    required this.text,
    required this.isMet,
  });
}

/// Utility class for password validation
class PasswordValidator {
  /// Validates password strength and returns validation result
  static PasswordValidationResult validatePassword(String password, [String? confirmPassword]) {
    final List<String> errors = [];
    
    // Length check
    if (password.length < 8) {
      errors.add('errors.password_too_short'.tr());
    }
    
    // Character variety checks
    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('Password must contain at least one lowercase letter');
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Password must contain at least one uppercase letter');
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('Password must contain at least one number');
    }
    
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('Password must contain at least one special character');
    }
    
    // Confirmation check
    if (confirmPassword != null && password != confirmPassword) {
      errors.add('errors.password_mismatch'.tr());
    }
    
    return PasswordValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      strength: _calculateStrength(password),
    );
  }
  
  static PasswordStrength _calculateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    
    int score = 0;
    
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    switch (score) {
      case 0:
      case 1:
      case 2:
        return PasswordStrength.weak;
      case 3:
      case 4:
        return PasswordStrength.fair;
      case 5:
        return PasswordStrength.good;
      default:
        return PasswordStrength.strong;
    }
  }
}

/// Result class for password validation
class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;
  final PasswordStrength strength;

  const PasswordValidationResult({
    required this.isValid,
    required this.errors,
    required this.strength,
  });
}
