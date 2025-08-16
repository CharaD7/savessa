import 'package:flutter/material.dart';

class WorldFlagOverlay extends StatelessWidget {
  final bool visible;

  const WorldFlagOverlay({super.key, required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Positioned(
      left: 10,
      top: 10,
      child: Opacity(
        opacity: 0.85,
        child: Container(
          width: 22,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: const Center(
            child: Icon(
              Icons.public, // world icon
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
      ),
    );
  }
}
