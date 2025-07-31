import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/icon_mapping.dart';
import '../../core/theme/app_theme.dart';

enum ValidationStatus {
  none,
  validating,
  valid,
  invalid
}

class ValidatedTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final Future<(bool, String?)> Function(String)? asyncValidator;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefix;
  final Widget? suffix;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsets? contentPadding;
  final FocusNode? focusNode;
  final AutovalidateMode autovalidateMode;
  final String? initialValue;
  final bool showClearButton;
  final bool showPasswordToggle;
  final bool showCounter;
  final bool required;
  final bool showValidationStatus;
  final bool preventNextIfInvalid;
  final void Function(ValidationStatus)? onValidationComplete;

  const ValidatedTextField({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onTap,
    this.asyncValidator,
    this.validator,
    this.inputFormatters,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.contentPadding,
    this.focusNode,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.initialValue,
    this.showClearButton = true,
    this.showPasswordToggle = true,
    this.showCounter = true,
    this.required = false,
    this.showValidationStatus = false,
    this.preventNextIfInvalid = false,
    this.onValidationComplete,
  }) : assert(
          controller == null || initialValue == null,
          'Cannot provide both a controller and an initialValue',
        );

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  late TextEditingController _controller;
  late bool _obscureText;
  late FocusNode _focusNode;
  ValidationStatus _validationStatus = ValidationStatus.none;
  String? _errorMessage;
  bool _isValidating = false;
  
  // Debounce timer for async validation
  DateTime? _lastChangeTime;
  static const _debounceTime = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _controller.removeListener(_onTextChanged);
    
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _focusNode.removeListener(_onFocusChanged);
    
    super.dispose();
  }

  void _onTextChanged() {
    if (_controller.text.isEmpty) {
      setState(() {
        _validationStatus = ValidationStatus.none;
        _errorMessage = null;
      });
      return;
    }
    
    // Perform sync validation first
    if (widget.validator != null) {
      final error = widget.validator!(_controller.text);
      if (error != null) {
        setState(() {
          _validationStatus = ValidationStatus.invalid;
          _errorMessage = error;
        });
        return;
      }
    }
    
    // If async validation is available, perform it after debounce
    if (widget.asyncValidator != null) {
      setState(() {
        _validationStatus = ValidationStatus.validating;
        _isValidating = true;
      });
      
      _lastChangeTime = DateTime.now();
      
      // Debounce to avoid too many API calls
      Future.delayed(_debounceTime, () async {
        // Only proceed if this is still the most recent change
        if (_lastChangeTime != null && 
            DateTime.now().difference(_lastChangeTime!) >= _debounceTime) {
          try {
            final (isValid, errorMsg) = await widget.asyncValidator!(_controller.text);
            
            // Check if the widget is still mounted before updating state
            if (mounted) {
              setState(() {
                _validationStatus = isValid ? ValidationStatus.valid : ValidationStatus.invalid;
                _errorMessage = errorMsg;
                _isValidating = false;
              });
              
              if (widget.onValidationComplete != null) {
                widget.onValidationComplete!(_validationStatus);
              }
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _validationStatus = ValidationStatus.invalid;
                _errorMessage = 'Validation error: ${e.toString()}';
                _isValidating = false;
              });
            }
          }
        }
      });
    } else if (_controller.text.isNotEmpty) {
      // If no async validator but text is not empty and passed sync validation
      setState(() {
        _validationStatus = ValidationStatus.valid;
      });
      
      if (widget.onValidationComplete != null) {
        widget.onValidationComplete!(_validationStatus);
      }
    }
  }

  void _onFocusChanged() {
    // When focus is lost, trigger validation
    if (!_focusNode.hasFocus && _controller.text.isNotEmpty) {
      _onTextChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.preventNextIfInvalid && _validationStatus == ValidationStatus.invalid 
          ? TextInputAction.done 
          : widget.textInputAction,
      obscureText: _obscureText,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      maxLines: _obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      onChanged: (value) {
        if (widget.onChanged != null) {
          widget.onChanged!(value);
        }
      },
      onTap: widget.onTap,
      validator: (value) {
        // Use the cached error message if available
        if (_validationStatus == ValidationStatus.invalid && _errorMessage != null) {
          return _errorMessage;
        }
        
        // Otherwise use the provided validator
        if (widget.validator != null) {
          return widget.validator!(value);
        }
        
        // Or the default required validator
        if (widget.required && (value == null || value.isEmpty)) {
          return 'errors.required_field'.tr();
        }
        
        return null;
      },
      inputFormatters: widget.inputFormatters,
      autovalidateMode: widget.autovalidateMode,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label + (widget.required ? ' *' : ''),
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: _errorMessage,
        prefixIcon: widget.prefixIcon,
        suffixIcon: _buildSuffixIcon(),
        prefix: widget.prefix,
        suffix: widget.suffix,
        contentPadding: widget.contentPadding,
        counterText: widget.showCounter ? null : '',
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    final List<Widget> suffixIcons = [];

    // Add validation status icon if enabled
    if (widget.showValidationStatus) {
      switch (_validationStatus) {
        case ValidationStatus.valid:
          suffixIcons.add(
            Container(
              margin: const EdgeInsets.all(12),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.success,
                size: 20,
              ),
            ),
          );
          break;
        case ValidationStatus.invalid:
          suffixIcons.add(
            Container(
              margin: const EdgeInsets.all(12),
              child: const Icon(
                Icons.cancel,
                color: AppTheme.error,
                size: 20,
              ),
            ),
          );
          break;
        case ValidationStatus.validating:
          suffixIcons.add(
            Container(
              margin: const EdgeInsets.all(12),
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.lightPurple),
              ),
            ),
          );
          break;
        case ValidationStatus.none:
          // No icon for none status
          break;
      }
    }

    // Add clear button if text is not empty and field is enabled
    if (widget.showClearButton && _controller.text.isNotEmpty && widget.enabled && !widget.readOnly) {
      suffixIcons.add(
        IconButton(
          icon: const Icon(IconMapping.clear, size: 20),
          onPressed: () {
            _controller.clear();
            setState(() {
              _validationStatus = ValidationStatus.none;
              _errorMessage = null;
            });
            if (widget.onChanged != null) {
              widget.onChanged!('');
            }
          },
          splashRadius: 20,
        ),
      );
    }

    // Add password toggle if obscureText is true
    if (widget.showPasswordToggle && widget.obscureText) {
      suffixIcons.add(
        IconButton(
          icon: Icon(
            _obscureText ? IconMapping.visibilityOff : IconMapping.visibility,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          splashRadius: 20,
        ),
      );
    }

    if (suffixIcons.isEmpty) {
      return null;
    }

    if (suffixIcons.length == 1) {
      return suffixIcons.first;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: suffixIcons,
    );
  }
}