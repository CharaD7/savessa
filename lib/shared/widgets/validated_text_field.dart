import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:async/async.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/core/theme/app_theme.dart';
import 'package:savessa/shared/widgets/loaders/gradient_square_loader.dart';

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
  final ValueChanged<String>? onFieldSubmitted;
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
    this.onFieldSubmitted,
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
  Timer? _debounceTimer;
  static const _debounceTime = Duration(milliseconds: 500);
  static const _validationTimeout = Duration(seconds: 5);
  
  // Cancellable future for validation
  CancelableOperation<(bool, String?)>? _validationOperation;

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
    // Cancel any pending operations
    _debounceTimer?.cancel();
    _validationOperation?.cancel();
    
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
      
      // Cancel any previous debounce timer
      _debounceTimer?.cancel();
      
      // Cancel any previous validation operation
      _validationOperation?.cancel();
      
      // Create a new debounce timer
      _debounceTimer = Timer(_debounceTime, () {
        // Capture the current text to validate
        final textToValidate = _controller.text;
        
        // Create a cancellable operation for the validation
        _validationOperation = CancelableOperation.fromFuture(
          // Add timeout to prevent indefinite validation
          widget.asyncValidator!(textToValidate)
            .timeout(
              _validationTimeout,
              onTimeout: () => (false, 'Validation timed out. Please try again.'),
            ),
        );
        
        // Handle the validation result
        _validationOperation?.value.then(
          (result) {
            // Check if the widget is still mounted before updating state
            if (mounted) {
              final (isValid, errorMsg) = result;
              setState(() {
                _validationStatus = isValid ? ValidationStatus.valid : ValidationStatus.invalid;
                // Only set error message if validation failed, otherwise clear it
                _errorMessage = isValid ? null : errorMsg;
                _isValidating = false;
              });
              
              if (widget.onValidationComplete != null) {
                widget.onValidationComplete!(_validationStatus);
              }
            }
          },
          onError: (e, stackTrace) {
            // Handle errors gracefully
            if (mounted) {
              setState(() {
                _validationStatus = ValidationStatus.invalid;
                _errorMessage = 'Validation error: ${e.toString()}';
                _isValidating = false;
              });
              
              // Log the error for debugging
              debugPrint('Validation error: $e');
              debugPrint('Stack trace: $stackTrace');
              
              if (widget.onValidationComplete != null) {
                widget.onValidationComplete!(_validationStatus);
              }
            }
          },
        );
      });
    } else if (_controller.text.isNotEmpty) {
      // If no async validator but text is not empty and passed sync validation
      setState(() {
        _validationStatus = ValidationStatus.valid;
        _errorMessage = null; // Clear any previous error message when validation is valid
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
      onFieldSubmitted: widget.onFieldSubmitted,
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
      style: theme.textTheme.bodyLarge?.copyWith(
        color: Colors.white, // Changed to white for better visibility on dark background
        fontWeight: FontWeight.w500, // Slightly bolder for better visibility
      ),
      decoration: InputDecoration(
        labelText: widget.label + (widget.required ? ' *' : ''),
        labelStyle: TextStyle(
          color: _focusNode.hasFocus ? AppTheme.gold : Colors.white.withValues(alpha: 0.9),
          fontWeight: _focusNode.hasFocus ? FontWeight.bold : FontWeight.normal,
        ),
        hintText: widget.hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.7), // Light hint text for better visibility on dark background
        ),
        helperText: widget.helperText,
        errorText: _errorMessage,
        errorStyle: const TextStyle(
          color: Colors.red, // Standard red for errors
          fontWeight: FontWeight.bold, // Make error messages more noticeable
        ),
        prefixIcon: widget.prefixIcon != null 
            ? IconTheme(
                data: IconThemeData(
                  color: _focusNode.hasFocus ? AppTheme.gold : Colors.white.withValues(alpha: 0.9),
                ),
                child: widget.prefixIcon!,
              )
            : null,
        suffixIcon: _buildSuffixIcon(),
        prefix: widget.prefix,
        suffix: widget.suffix,
        contentPadding: widget.contentPadding,
        counterText: widget.showCounter ? null : '',
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1), // More transparent background for dark theme
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: _validationStatus == ValidationStatus.valid
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              )
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.gold, width: 2),
              ),
        enabledBorder: _validationStatus == ValidationStatus.valid
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 1),
              )
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        // Remove extra built-in padding around suffix icons for password fields
        suffixIconConstraints: widget.obscureText
            ? const BoxConstraints(minWidth: 0, minHeight: 0)
            : null,
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    final List<Widget> suffixIcons = [];
    // Keep references to special icons to control spacing
    Widget? clearRef;
    Widget? validationRef;
    Widget? eyeRef;

    // Prepare validation status widget (do not add yet)
    Widget? validationWidget;
    if (widget.showValidationStatus && _controller.text.isNotEmpty) {
      if (_isValidating) {
        validationWidget = const GradientSquareLoader(
          size: 20,
          color1: AppTheme.gold,
          animationDurationMs: 1200,
        );
      } else {
        switch (_validationStatus) {
          case ValidationStatus.valid:
            validationWidget = const Icon(
              IconMapping.checkCircle,
              color: Colors.green,
              size: 20,
            );
            break;
          case ValidationStatus.invalid:
            validationWidget = const Icon(
              IconMapping.error,
              color: Colors.red,
              size: 20,
            );
            break;
          default:
            validationWidget = null;
            break;
        }
      }
    }

    // Add custom suffix icon if provided
    if (widget.suffixIcon != null) {
      suffixIcons.add(widget.suffixIcon!);
    } else {
      // For non-password fields (e.g., Email): clear first, then validation
      if (!widget.obscureText) {
        if (widget.showClearButton && _controller.text.isNotEmpty && widget.enabled && !widget.readOnly) {
          final clearBtn = IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            visualDensity: VisualDensity.compact,
            icon: Icon(IconMapping.clear, size: 20, color: Colors.white.withValues(alpha: 0.9)),
            onPressed: () {
              _controller.clear();
              if (widget.onChanged != null) {
                widget.onChanged!('');
              }
            },
            splashRadius: 18,
          );
          clearRef = clearBtn;
          suffixIcons.add(clearBtn);
        }
        if (validationWidget != null) {
          final validationContainer = Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.only(right: 5),
            child: validationWidget,
          );
          validationRef = validationContainer;
          suffixIcons.add(validationContainer);
        }
      } else {
        // For password fields: validation first (if any), then clear, then eye toggle
        if (validationWidget != null) {
          suffixIcons.add(validationWidget);
        }
        if (widget.showClearButton && _controller.text.isNotEmpty && widget.enabled && !widget.readOnly) {
          final clearBtn = IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            visualDensity: VisualDensity.compact,
            icon: Icon(IconMapping.clear, size: 20, color: Colors.white.withValues(alpha: 0.9)),
            onPressed: () {
              _controller.clear();
              if (widget.onChanged != null) {
                widget.onChanged!('');
              }
            },
            splashRadius: 18,
          );
          clearRef = clearBtn;
          suffixIcons.add(clearBtn);
        }
        if (widget.showPasswordToggle) {
          final eyeWidget = Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Transform.translate(
              offset: const Offset(-2, 0),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  _obscureText ? IconMapping.visibilityOff : IconMapping.visibility,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                splashRadius: 18,
              ),
            ),
          );
          eyeRef = eyeWidget;
          suffixIcons.add(eyeWidget);
        }
      }
    }

    if (suffixIcons.isEmpty) {
      return null;
    }
    
    if (suffixIcons.length == 1) {
      return suffixIcons.first;
    }

    // Build with conditional spacing:
    // - Email (non-password): remove left gap before validation icon when following clear
    // - Password fields: remove both left and right gaps around the clear icon
    final List<Widget> children = [];
    for (int i = 0; i < suffixIcons.length; i++) {
      final current = suffixIcons[i];
      if (i > 0) {
        final prev = suffixIcons[i - 1];
        double gap = 2;
        final isPassword = widget.obscureText;
        final prevIsClear = identical(prev, clearRef);
        final currIsClear = identical(current, clearRef);
        final currIsEye = identical(current, eyeRef);
        final prevIsClearCurrIsValidation = identical(prev, clearRef) && identical(current, validationRef);

        if (isPassword) {
          // Password fields: make validation/clear closer to the eye by removing the gap before the eye
          if (currIsEye) {
            gap = 0; // no space before the eye icon
          } else if (prevIsClear) {
            gap = 0; // no space after clear
          } else if (currIsClear) {
            gap = 0; // no space before clear
          }
        } else if (prevIsClearCurrIsValidation) {
          // Email field: remove gap between clear and validation to bring them closer
          gap = 0;
        }
        if (gap > 0) {
          children.add(SizedBox(width: gap));
        }
      }
      children.add(current);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

}
