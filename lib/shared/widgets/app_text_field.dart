import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/icon_mapping.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();

    _controller.addListener(_onTextChanged);
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
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
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
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label + (widget.required ? ' *' : ''),
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: widget.errorText,
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

    // Add clear button if text is not empty and field is enabled
    if (widget.showClearButton && _controller.text.isNotEmpty && widget.enabled && !widget.readOnly) {
      suffixIcons.add(
        IconButton(
          icon: const Icon(IconMapping.clear, size: 20),
          onPressed: () {
            _controller.clear();
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

  String? _requiredValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'errors.required_field'.tr();
    }
    return null;
  }
}