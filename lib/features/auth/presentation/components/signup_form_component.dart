import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/validated_text_field.dart';
import '../../../../shared/widgets/password_strength_indicator.dart';
import '../../../../core/constants/icon_mapping.dart';
import '../../../../services/validation/email_validator_service.dart';
import '../../../../services/validation/password_validator_service.dart';
import '../../../../services/validation/phone_validator_service.dart';

/// A reusable component that displays a signup form with fields for first name,
/// middle name, last name, email, phone number, password, and confirm password,
/// along with a signup button.
class SignUpFormComponent extends StatefulWidget {
  /// Form key for validation.
  final GlobalKey<FormState> formKey;
  
  /// Text controller for the first name field.
  final TextEditingController firstNameController;
  
  /// Text controller for the middle name field.
  final TextEditingController middleNameController;
  
  /// Text controller for the last name field.
  final TextEditingController lastNameController;
  
  /// Text controller for the email field.
  final TextEditingController emailController;
  
  /// Text controller for the phone field.
  final TextEditingController phoneController;
  
  /// Text controller for the password field.
  final TextEditingController passwordController;
  
  /// Text controller for the confirm password field.
  final TextEditingController confirmPasswordController;
  
  /// Focus node for the first name field.
  final FocusNode firstNameFocus;
  
  /// Focus node for the middle name field.
  final FocusNode middleNameFocus;
  
  /// Focus node for the last name field.
  final FocusNode lastNameFocus;
  
  /// Focus node for the email field.
  final FocusNode emailFocus;
  
  /// Focus node for the phone field.
  final FocusNode phoneFocus;
  
  /// Focus node for the password field.
  final FocusNode passwordFocus;
  
  /// Focus node for the confirm password field.
  final FocusNode confirmPasswordFocus;
  
  /// Callback function when the signup button is pressed.
  final VoidCallback onSignup;
  
  /// Callback function when a field is completed.
  final Function(String field, String value)? onFieldCompletion;
  
  /// Whether the form is in a loading state.
  final bool isLoading;
  
  /// The selected country for the phone field.
  final Country selectedCountry;
  
  /// Callback function when the country is changed.
  final Function(Country country)? onCountryChanged;
  
  /// Validation status for the email field.
  final ValidationStatus emailValidationStatus;
  
  /// Validation status for the phone field.
  final ValidationStatus phoneValidationStatus;
  
  /// Validation status for the password field.
  final ValidationStatus passwordValidationStatus;
  
  /// Validation status for the confirm password field.
  final ValidationStatus confirmPasswordValidationStatus;
  
  /// Callback function when the email validation is complete.
  final Function(ValidationStatus status)? onEmailValidationComplete;
  
  /// Callback function when the password validation is complete.
  final Function(ValidationStatus status)? onPasswordValidationComplete;
  
  /// Callback function when the confirm password validation is complete.
  final Function(ValidationStatus status)? onConfirmPasswordValidationComplete;
  
  /// Whether the first name field is completed.
  final bool firstNameCompleted;
  
  /// Whether the middle name field is completed.
  final bool middleNameCompleted;
  
  /// Whether the last name field is completed.
  final bool lastNameCompleted;
  
  /// Whether the phone field is completed.
  final bool phoneCompleted;
  
  /// Optional custom label for the signup button.
  final String? signupButtonLabel;
  
  /// Optional custom height for the signup button.
  final double? signupButtonHeight;
  
  /// Optional custom border radius for the signup button.
  final double? signupButtonBorderRadius;
  
  const SignUpFormComponent({
    super.key,
    required this.formKey,
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.firstNameFocus,
    required this.middleNameFocus,
    required this.lastNameFocus,
    required this.emailFocus,
    required this.phoneFocus,
    required this.passwordFocus,
    required this.confirmPasswordFocus,
    required this.onSignup,
    required this.selectedCountry,
    this.onFieldCompletion,
    this.onCountryChanged,
    this.isLoading = false,
    this.emailValidationStatus = ValidationStatus.none,
    this.phoneValidationStatus = ValidationStatus.none,
    this.passwordValidationStatus = ValidationStatus.none,
    this.confirmPasswordValidationStatus = ValidationStatus.none,
    this.onEmailValidationComplete,
    this.onPasswordValidationComplete,
    this.onConfirmPasswordValidationComplete,
    this.firstNameCompleted = false,
    this.middleNameCompleted = false,
    this.lastNameCompleted = false,
    this.phoneCompleted = false,
    this.signupButtonLabel,
    this.signupButtonHeight,
    this.signupButtonBorderRadius,
  });

  @override
  State<SignUpFormComponent> createState() => _SignUpFormComponentState();
}

class _SignUpFormComponentState extends State<SignUpFormComponent> {
  // Local variables to track state
  String _countryCode = '';
  String _completePhoneNumber = '';
  int _phoneDigits = 0;
  
  @override
  void initState() {
    super.initState();
    _countryCode = '+${widget.selectedCountry.dialCode}';
    // Rebuild when phone field focus changes to update placeholder text
    widget.phoneFocus.addListener(_onPhoneFocusChange);
  }
  
  void _onPhoneFocusChange() {
    if (mounted) setState(() {});
  }
  
  @override
  void didUpdateWidget(covariant SignUpFormComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phoneFocus != widget.phoneFocus) {
      oldWidget.phoneFocus.removeListener(_onPhoneFocusChange);
      widget.phoneFocus.addListener(_onPhoneFocusChange);
    }
  }
  
  @override
  void dispose() {
    // Remove listener; do not dispose as focus node is owned by parent
    widget.phoneFocus.removeListener(_onPhoneFocusChange);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          // First Name field
          AppTextField(
            controller: widget.firstNameController,
            focusNode: widget.firstNameFocus,
            label: 'First Name',
            hint: 'Enter First Name',
            prefixIcon: const Icon(IconMapping.person),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'errors.required_field'.tr();
              }
              return null;
            },
            onChanged: (value) {
              if (widget.onFieldCompletion != null) {
                widget.onFieldCompletion!('first_name', value);
              }
            },
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(widget.middleNameFocus);
            },
            suffixIcon: widget.firstNameCompleted ? const Icon(IconMapping.checkCircle, color: Colors.green) : null,
          ),
          const SizedBox(height: 16),
          
          // Middle Name field (optional)
          AppTextField(
            controller: widget.middleNameController,
            focusNode: widget.middleNameFocus,
            label: 'Middle Name',
            hint: 'Enter Middle Name',
            prefixIcon: const Icon(IconMapping.person),
            validator: (value) {
              // Middle name is optional, so no validation required
              return null;
            },
            onChanged: (value) {
              if (widget.onFieldCompletion != null) {
                widget.onFieldCompletion!('middle_name', value);
              }
            },
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(widget.lastNameFocus);
            },
            suffixIcon: widget.middleNameCompleted ? const Icon(IconMapping.checkCircle, color: Colors.green) : null,
          ),
          const SizedBox(height: 16),
          
          // Last Name field
          AppTextField(
            controller: widget.lastNameController,
            focusNode: widget.lastNameFocus,
            label: 'Last Name',
            hint: 'Enter Last Name',
            prefixIcon: const Icon(IconMapping.person),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'errors.required_field'.tr();
              }
              return null;
            },
            onChanged: (value) {
              if (widget.onFieldCompletion != null) {
                widget.onFieldCompletion!('last_name', value);
              }
            },
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(widget.emailFocus);
            },
            suffixIcon: widget.lastNameCompleted ? const Icon(IconMapping.checkCircle, color: Colors.green) : null,
          ),
          const SizedBox(height: 16),
          
          // Contact/Email field with validation
          ValidatedTextField(
            label: 'Email',
            hint: 'username@domain.extension',
            controller: widget.emailController,
            focusNode: widget.emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(IconMapping.email),
            required: true,
            showValidationStatus: true,
            preventNextIfInvalid: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'errors.required_field'.tr();
              }
              
              final emailValidator = EmailValidatorService();
              if (!emailValidator.isValidFormat(value)) {
                return 'errors.invalid_email'.tr();
              }
              
              return null;
            },
            asyncValidator: (value) async {
              final emailValidator = EmailValidatorService();
              
              // First check if email is already registered
              final isRegistered = await emailValidator.isEmailRegistered(value);
              if (isRegistered) {
                return (false, 'errors.email_already_registered'.tr());
              }
              
              // Then validate email existence and activity
              return await emailValidator.validateEmail(value);
            },
            onChanged: (value) {
              // Reset validation status when text changes
              if (widget.onFieldCompletion != null) {
                widget.onFieldCompletion!('contact', value);
              }
            },
            onValidationComplete: widget.onEmailValidationComplete,
          ),
          const SizedBox(height: 16),
          
          // Phone number field with country selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Removed explicit 'Phone Number' label per requirements
              IntlPhoneField(
                key: ValueKey(widget.selectedCountry.code),
                controller: widget.phoneController,
                focusNode: widget.phoneFocus,
                decoration: InputDecoration(
                  hintText: widget.phoneFocus.hasFocus ? 'Enter phone number' : 'Phone number',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                  ),
                  // Removed prefixIcon to avoid duplicate phone icons
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  errorStyle: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                initialCountryCode: widget.selectedCountry.code,
                countries: countries,
                showDropdownIcon: true,
                dropdownIconPosition: IconPosition.trailing,
                flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 8),
                disableLengthCheck: false,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                dropdownTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                dropdownIcon: const Icon(
                  IconMapping.arrowDownward,
                  color: Colors.white,
                  size: 18,
                ),
                validator: (phone) {
                  if (phone == null || phone.number.isEmpty) {
                    return 'errors.required_field'.tr();
                  }
                  
                  final errorMessage = PhoneValidatorService.validateIntlPhone(phone, widget.selectedCountry);
                  
                  if (errorMessage != null) {
                    return errorMessage;
                  }
                  
                  return null;
                },
                onChanged: (phone) {
                  setState(() {
                    _countryCode = phone.countryCode;
                    _completePhoneNumber = phone.completeNumber;
                    _phoneDigits = phone.number.length;
                  });
                  
                  if (widget.onFieldCompletion != null) {
                    widget.onFieldCompletion!('phone', phone.completeNumber);
                  }
                },
                onCountryChanged: (country) {
                  setState(() {
                    _countryCode = '+${country.dialCode}';
                    _phoneDigits = widget.phoneController.text.replaceAll(RegExp(r'\D'), '').length;
                  });
                  
                  if (widget.onCountryChanged != null) {
                    widget.onCountryChanged!(country);
                  }
                },
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(widget.passwordFocus);
                },
              ),
              // Custom animated count indicator
              Builder(
                builder: (context) {
                  final validLengths = PhoneValidatorService.getExpectedLength(widget.selectedCountry.code);
                  final minLen = PhoneValidatorService.getMinExpectedLength(widget.selectedCountry.code);
                  final maxLen = PhoneValidatorService.getMaxExpectedLength(widget.selectedCountry.code);
                  final isAcceptable = validLengths.contains(_phoneDigits);
                  final targetColor = isAcceptable
                      ? Color.lerp(Colors.red, Colors.green, ((maxLen - minLen) == 0)
                          ? (_phoneDigits >= minLen ? 1.0 : 0.0)
                          : ((_phoneDigits - minLen).clamp(0, maxLen - minLen) / (maxLen - minLen)))!
                      : Colors.red;
                  final rangeLabel = minLen == maxLen ? '$maxLen' : '$minLen-$maxLen';
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(begin: Colors.red, end: targetColor),
                      duration: const Duration(milliseconds: 200),
                      builder: (context, color, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '$_phoneDigits / $rangeLabel',
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
              if (widget.phoneValidationStatus == ValidationStatus.valid)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        IconMapping.checkCircle,
                        color: Colors.green,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Valid phone number',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.phoneValidationStatus == ValidationStatus.invalid)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        IconMapping.error,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Invalid phone number for ${widget.selectedCountry.name}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Password field with validation
          ValidatedTextField(
            label: 'auth.password'.tr(),
            controller: widget.passwordController,
            focusNode: widget.passwordFocus,
            obscureText: true,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(IconMapping.lock),
            required: true,
            showValidationStatus: true,
            preventNextIfInvalid: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'errors.required_field'.tr();
              }
              
              final passwordValidator = PasswordValidatorService();
              final (isPolicyValid, policyError) = passwordValidator.validatePolicy(value);
              if (!isPolicyValid) {
                return policyError;
              }
              
              return null;
            },
            asyncValidator: (value) async {
              final passwordValidator = PasswordValidatorService();
              return await passwordValidator.checkCompromised(value);
            },
            onChanged: (value) {
              // Force rebuild to update password strength indicator
              setState(() {});
              
              if (widget.onFieldCompletion != null) {
                widget.onFieldCompletion!('password', value);
              }
              
              // If confirm password field is not empty, update its validation status
              if (widget.confirmPasswordController.text.isNotEmpty) {
                // Trigger validation for confirm password field
                widget.formKey.currentState?.validate();
              }
            },
            onValidationComplete: widget.onPasswordValidationComplete,
          ),
          
          // Password strength indicator
          if (widget.passwordController.text.isNotEmpty)
            PasswordStrengthIndicator(
              password: widget.passwordController.text,
            ),
          const SizedBox(height: 16),
          
          // Confirm password field
          ValidatedTextField(
            label: 'auth.confirm_password'.tr(),
            controller: widget.confirmPasswordController,
            focusNode: widget.confirmPasswordFocus,
            obscureText: true,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(IconMapping.lockOutline),
            required: true,
            showValidationStatus: true,
            preventNextIfInvalid: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'errors.required_field'.tr();
              }
              if (value != widget.passwordController.text) {
                return 'errors.password_mismatch'.tr();
              }
              return null;
            },
            // Listen for changes to update validation status in real-time
            onChanged: (value) {
              // Update validation status based on whether passwords match
              setState(() {
                if (value.isEmpty) {
                  // Empty field - no validation status
                  if (widget.onConfirmPasswordValidationComplete != null) {
                    widget.onConfirmPasswordValidationComplete!(ValidationStatus.none);
                  }
                } else if (value == widget.passwordController.text) {
                  // Passwords match - valid
                  if (widget.onConfirmPasswordValidationComplete != null) {
                    widget.onConfirmPasswordValidationComplete!(ValidationStatus.valid);
                  }
                } else {
                  // Passwords don't match - invalid
                  if (widget.onConfirmPasswordValidationComplete != null) {
                    widget.onConfirmPasswordValidationComplete!(ValidationStatus.invalid);
                  }
                }
              });
              
              if (widget.onFieldCompletion != null) {
                widget.onFieldCompletion!('confirm_password', value);
              }
            },
            onValidationComplete: widget.onConfirmPasswordValidationComplete,
          ),
          const SizedBox(height: 24),
          
          // Signup button
          AppButton(
            label: widget.signupButtonLabel ?? 'auth.sign_up'.tr(),
            onPressed: widget.onSignup,
            type: ButtonType.primary,
            isFullWidth: true,
            height: widget.signupButtonHeight ?? 56,
            borderRadius: widget.signupButtonBorderRadius ?? 12,
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }
}