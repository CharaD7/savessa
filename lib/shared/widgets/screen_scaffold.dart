import 'package:flutter/material.dart';
import 'package:savessa/shared/widgets/stacked_back_home_fab.dart';

/// Reusable Scaffold wrapper that standardizes app bars, padding and optional
/// stacked Back/Home FABs for screens without bottom navigation.
class ScreenScaffold extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floating;
  final bool showBackHomeFab;
  final String homeRoute;
  final EdgeInsetsGeometry padding;

  const ScreenScaffold({
    super.key,
    this.title,
    this.actions,
    required this.body,
    this.floating,
    this.showBackHomeFab = false,
    this.homeRoute = '/home',
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        actions: actions,
      ),
      floatingActionButton: _buildFab(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: padding,
          child: body,
        ),
      ),
    );
  }

  Widget? _buildFab() {
    if (showBackHomeFab && floating == null) {
      return StackedBackHomeFab(homeRoute: homeRoute);
    }
    if (showBackHomeFab && floating != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          floating!,
          const SizedBox(height: 12),
          StackedBackHomeFab(homeRoute: homeRoute),
        ],
      );
    }
    return floating;
  }
}
