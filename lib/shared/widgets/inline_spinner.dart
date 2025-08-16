import 'package:flutter/material.dart';

class InlineSpinner extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const InlineSpinner({super.key, this.size = 16, this.strokeWidth = 2, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? theme.colorScheme.secondary),
      ),
    );
  }
}
