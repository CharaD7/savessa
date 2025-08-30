import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

/// An expandable floating action button that reveals additional actions
class ExpandableFab extends StatefulWidget {
  final double distance;
  final List<ActionButton> children;
  final Duration animationDuration;
  final IconData? icon;
  final IconData? closeIcon;

  const ExpandableFab({
    super.key,
    required this.children,
    this.distance = 112,
    this.animationDuration = const Duration(milliseconds: 250),
    this.icon = Icons.add,
    this.closeIcon = Icons.close,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: widget.animationDuration,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // Background overlay
          if (_open)
            GestureDetector(
              onTap: _toggle,
              child: AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withOpacity(_expandAnimation.value * 0.3),
                  );
                },
              ),
            ),
          
          // Action buttons
          ...widget.children.map((child) {
            final index = widget.children.indexOf(child);
            return _buildExpandingActionButton(
              child,
              _calculateOffset(index),
            );
          }),
          
          // Main FAB
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _expandAnimation.value * math.pi / 4,
                child: FloatingActionButton(
                  heroTag: "main_fab",
                  onPressed: _toggle,
                  child: Icon(
                    _open ? widget.closeIcon : widget.icon,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpandingActionButton(ActionButton actionButton, Offset offset) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final progress = _expandAnimation.value;
        final currentOffset = Offset.lerp(
          Offset.zero,
          offset,
          progress,
        )!;
        
        return Positioned(
          right: 4.0 + currentOffset.dx,
          bottom: 4.0 + currentOffset.dy,
          child: Transform.scale(
            scale: progress,
            child: Opacity(
              opacity: progress,
              child: FloatingActionButton.small(
                heroTag: actionButton.heroTag,
                onPressed: () {
                  _toggle();
                  actionButton.onPressed();
                },
                tooltip: actionButton.tooltip,
                backgroundColor: actionButton.backgroundColor,
                foregroundColor: actionButton.foregroundColor,
                child: Icon(actionButton.icon),
              ),
            ),
          ),
        );
      },
    );
  }

  Offset _calculateOffset(int index) {
    final step = math.pi / 2 / (widget.children.length - 1);
    final angle = math.pi / 2 - (step * index);
    return Offset(
      math.cos(angle) * widget.distance,
      math.sin(angle) * widget.distance,
    );
  }
}

/// Action button configuration for the expandable FAB
class ActionButton {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final String heroTag;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ActionButton({
    required this.icon,
    required this.onPressed,
    required this.heroTag,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });
}

/// Home-specific expandable FAB with settings access
class HomeExpandableFab extends StatelessWidget {
  const HomeExpandableFab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ExpandableFab(
      distance: 80,
      children: [
        ActionButton(
          heroTag: "settings_fab",
          icon: Icons.settings,
          tooltip: 'Settings',
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
          onPressed: () => context.go('/settings'),
        ),
      ],
    );
  }
}

/// More complex expandable FAB with multiple actions
class MultiActionFab extends StatelessWidget {
  const MultiActionFab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ExpandableFab(
      distance: 90,
      children: [
        ActionButton(
          heroTag: "add_savings_fab",
          icon: Icons.add,
          tooltip: 'Add Savings',
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          onPressed: () => context.go('/savings/add'),
        ),
        ActionButton(
          heroTag: "create_group_fab",
          icon: Icons.group_add,
          tooltip: 'Create Group',
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
          onPressed: () => context.go('/groups/create'),
        ),
        ActionButton(
          heroTag: "settings_fab_multi",
          icon: Icons.settings,
          tooltip: 'Settings',
          backgroundColor: theme.colorScheme.tertiary,
          foregroundColor: theme.colorScheme.onTertiary,
          onPressed: () => context.go('/settings'),
        ),
      ],
    );
  }
}

/// Simple expandable FAB for settings only (as requested)
class SettingsExpandableFab extends StatefulWidget {
  const SettingsExpandableFab({super.key});

  @override
  State<SettingsExpandableFab> createState() => _SettingsExpandableFabState();
}

class _SettingsExpandableFabState extends State<SettingsExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Settings button (appears when expanded)
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Opacity(
                opacity: _animation.value,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: FloatingActionButton.small(
                    heroTag: "settings_mini_fab",
                    onPressed: () {
                      _toggle();
                      context.go('/settings');
                    },
                    tooltip: 'Settings',
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: const Icon(Icons.settings),
                  ),
                ),
              ),
            );
          },
        ),
        
        // Main FAB
        FloatingActionButton(
          heroTag: "main_settings_fab",
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(_isExpanded ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
  }
}
