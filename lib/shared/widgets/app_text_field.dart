import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/core/theme/app_theme.dart';

class AppTextField extends StatefulWidget {
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
  final bool useAuthFormStyling;

  const AppTextField({
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
    this.useAuthFormStyling = false,
  }) : assert(
          controller == null || initialValue == null,
          'Cannot provide both a controller and an initialValue',
        );

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late TextEditingController _controller;
  late bool _obscureText;
  late FocusNode _focusNode;
  bool _hasFocusListener = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();

    _controller.addListener(_onTextChanged);
    
    // Always add focus listener to handle dynamic color changes
    _focusNode.addListener(_onFocusChanged);
    _hasFocusListener = true;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _controller.removeListener(_onTextChanged);
    
    if (_hasFocusListener) {
      _focusNode.removeListener(_onFocusChanged);
    }
    
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }
  
  void _onFocusChanged() {
    setState(() {
      // Trigger rebuild when focus changes to update label colors
    });
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'errors.required_field'.tr();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Determine colors based on auth form styling flag
    late final Color textColor;
    late final Color hintColor;
    late final Color labelColor;
    late final Color iconColor;
    late final Color fillColor;
    late final Color borderColor;
    late final Color focusedBorderColor;
    
    if (widget.useAuthFormStyling) {
      // Auth form styling: white/gold theme matching ValidatedTextField
      textColor = Colors.white;
      hintColor = Colors.white.withValues(alpha: 0.7);
      labelColor = _focusNode.hasFocus 
          ? AppTheme.gold 
          : Colors.white.withValues(alpha: 0.9);
      iconColor = _focusNode.hasFocus 
          ? AppTheme.gold 
          : Colors.white.withValues(alpha: 0.9);
      fillColor = Colors.white.withValues(alpha: 0.1);
      borderColor = Colors.white.withValues(alpha: 0.3);
      focusedBorderColor = AppTheme.gold;
    } else {
      // Default styling: theme-based colors
      textColor = theme.colorScheme.onSurface;
      hintColor = AppTheme.grey.withValues(alpha: 0.7); // Always grey for placeholders
      labelColor = _focusNode.hasFocus 
          ? (isDarkMode ? AppTheme.gold : AppTheme.royalPurple)
          : (isDarkMode ? AppTheme.gold.withValues(alpha: 0.9) : AppTheme.royalPurple.withValues(alpha: 0.8));
      iconColor = _focusNode.hasFocus 
          ? (isDarkMode ? AppTheme.gold : AppTheme.royalPurple) 
          : theme.colorScheme.onSurface.withValues(alpha: 0.7);
      fillColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.5);
      focusedBorderColor = theme.colorScheme.primary;
    }
    
    final errorColor = theme.colorScheme.error;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        obscureText: _obscureText,
        readOnly: widget.readOnly,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        maxLines: _obscureText ? 1 : widget.maxLines,
        minLines: widget.minLines,
        maxLength: widget.maxLength,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onFieldSubmitted,
        onTap: widget.onTap,
        validator: widget.validator ?? (widget.required ? _requiredValidator : null),
        inputFormatters: widget.inputFormatters,
        autovalidateMode: widget.autovalidateMode,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: widget.useAuthFormStyling ? 16 : null,
        ),
        decoration: InputDecoration(
          labelText: widget.label + (widget.required ? ' *' : ''),
          labelStyle: TextStyle(
            color: labelColor,
            fontWeight: widget.useAuthFormStyling 
                ? (_focusNode.hasFocus ? FontWeight.bold : FontWeight.normal)
                : (_focusNode.hasFocus ? FontWeight.w600 : FontWeight.w500),
            fontSize: 16,
          ),
          floatingLabelStyle: TextStyle(
            color: widget.useAuthFormStyling 
                ? (_focusNode.hasFocus ? AppTheme.gold : Colors.white.withValues(alpha: 0.9))
                : (_focusNode.hasFocus 
                    ? (theme.brightness == Brightness.dark ? AppTheme.gold : AppTheme.royalPurple)
                    : (theme.brightness == Brightness.dark ? AppTheme.gold.withValues(alpha: 0.9) : AppTheme.royalPurple.withValues(alpha: 0.8))),
            fontWeight: widget.useAuthFormStyling 
                ? FontWeight.bold 
                : FontWeight.w600,
            fontSize: 16,
          ),
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: hintColor,
            fontWeight: FontWeight.w400,
          ),
          helperText: widget.helperText,
          helperStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
          errorText: widget.errorText,
          errorStyle: TextStyle(
            color: widget.useAuthFormStyling ? Colors.red : errorColor,
            fontWeight: widget.useAuthFormStyling ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
          prefixIcon: widget.prefixIcon != null 
              ? IconTheme(
                  data: IconThemeData(
                    color: iconColor,
                    size: 20,
                  ),
                  child: widget.prefixIcon!,
                )
              : null,
          suffixIcon: _buildSuffixIcon(),
          prefix: widget.prefix,
          suffix: widget.suffix,
          contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(
            horizontal: 16, 
            vertical: 18,
          ),
          counterText: widget.showCounter ? null : '',
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: widget.useAuthFormStyling 
                ? BorderSide.none 
                : BorderSide(color: borderColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: widget.useAuthFormStyling
                ? BorderSide(color: borderColor)
                : BorderSide(color: borderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: focusedBorderColor,
              width: widget.useAuthFormStyling ? 2 : 2.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: widget.useAuthFormStyling ? Colors.red : errorColor,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: widget.useAuthFormStyling ? Colors.red : errorColor,
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: widget.useAuthFormStyling 
                  ? Colors.white.withValues(alpha: 0.2)
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          // Remove extra built-in padding around suffix icons for password fields
          suffixIconConstraints: widget.obscureText
              ? const BoxConstraints(minWidth: 0, minHeight: 0)
              : null,
        ),
      ),
    );
  }
  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    final theme = Theme.of(context);
    final suffixIconColor = widget.useAuthFormStyling
        ? (_focusNode.hasFocus ? AppTheme.gold : Colors.white.withValues(alpha: 0.9))
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final List<Widget> suffixIcons = [];
    Widget? clearRef;
    Widget? eyeRef;

    // Add clear button if text is not empty and field is enabled
    if (widget.showClearButton && _controller.text.isNotEmpty && widget.enabled && !widget.readOnly) {
      final clearBtn = IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minHeight: 28),
        visualDensity: VisualDensity.compact,
        icon: Icon(
          IconMapping.clear, 
          size: 20, 
          color: suffixIconColor,
        ),
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

    // Add password toggle if field is password
    if (widget.obscureText && widget.showPasswordToggle) {
      final eyeIcon = Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Transform.translate(
          offset: const Offset(-2, 0),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minHeight: 28),
            visualDensity: VisualDensity.compact,
            icon: Icon(
              _obscureText ? IconMapping.visibilityOff : IconMapping.visibility,
              size: 20,
              color: suffixIconColor,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
            splashRadius: 20,
          ),
        ),
      );
      eyeRef = eyeIcon;
      suffixIcons.add(eyeIcon);
    }

    if (suffixIcons.isEmpty) {
      return null;
    }

    // Add conditional spacing with 5px gaps, but remove gaps around clear icon in password fields
    final List<Widget> children = [];
    for (int i = 0; i < suffixIcons.length; i++) {
      final current = suffixIcons[i];
      if (i > 0) {
        final prev = suffixIcons[i - 1];
        double gap = 2;
        if (widget.obscureText) {
          // Make validation/clear closer to the eye by removing the gap before the eye
          if (identical(current, eyeRef)) {
            gap = 0; // no space before eye
          } else if (identical(prev, clearRef)) {
            gap = 0; // no space after clear
          } else if (identical(current, clearRef)) {
            gap = 0; // before clear
          }
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
