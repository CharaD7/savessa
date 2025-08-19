import 'package:flutter/material.dart';

class HomeFab extends StatelessWidget {
  final String heroTag;
  final VoidCallback? onPressed;
  const HomeFab({super.key, this.heroTag = 'fab_home', this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      tooltip: 'Home',
      onPressed: onPressed,
      child: const Icon(Icons.home),
    );
  }
}

