import 'package:flutter/material.dart';
import '../../services/validation/password_validator_service.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  
  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    final passwordValidator = PasswordValidatorService();
    final strength = passwordValidator.checkStrength(password);
    final strengthColor = passwordValidator.getStrengthColor(strength);
    final strengthLabel = passwordValidator.getStrengthLabel(strength);
    
    // Calculate progress based on strength
    double progress = 0.0;
    
    // If password length exceeds 12, fill to 100%
    if (password.length > 12) {
      progress = 1.0;
    } else {
      switch (strength) {
        case PasswordStrength.weak:
          progress = 0.25;
          break;
        case PasswordStrength.medium:
          progress = 0.5;
          break;
        case PasswordStrength.strong:
          progress = 0.75;
          break;
        case PasswordStrength.veryStrong:
          progress = 1.0;
          break;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              strengthLabel,
              style: TextStyle(
                color: strengthColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildPasswordRequirements(),
      ],
    );
  }
  
  Widget _buildPasswordRequirements() {
    final passwordValidator = PasswordValidatorService();
    
    // Check individual requirements
    final hasMinLength = password.length >= 8;
    final hasUppercase = passwordValidator.hasUppercase(password);
    final hasLowercase = passwordValidator.hasLowercase(password);
    final hasDigit = passwordValidator.hasDigit(password);
    final hasSpecialChar = passwordValidator.hasSpecialChar(password);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password must:',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        _buildRequirementRow(
          hasMinLength, 
          'Be at least 8 characters long',
        ),
        _buildRequirementRow(
          hasUppercase, 
          'Contain at least 1 uppercase letter',
        ),
        _buildRequirementRow(
          hasLowercase, 
          'Contain at least 1 lowercase letter',
        ),
        _buildRequirementRow(
          hasDigit, 
          'Contain at least 1 number',
        ),
        _buildRequirementRow(
          hasSpecialChar, 
          'Contain at least 1 special character',
        ),
      ],
    );
  }
  
  Widget _buildRequirementRow(bool isMet, String text) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.cancel,
          color: isMet ? Colors.green : Colors.red,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}