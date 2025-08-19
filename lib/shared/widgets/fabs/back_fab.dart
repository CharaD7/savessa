import 'package:flutter/material.dart';

class BackFab extends StatelessWidget {
  final String heroTag;
  final VoidCallback? onPressed;
  const BackFab({super.key, this.heroTag = 'fab_back', this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      tooltip: 'Back',
      onPressed: onPressed,
      child: const Icon(Icons.arrow_back),
    );
  }
}

