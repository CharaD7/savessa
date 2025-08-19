import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'fabs/back_fab.dart';
import 'fabs/home_fab.dart';

/// Two floating buttons stacked vertically at bottom-right: Back (top), Home (bottom).
/// Use on screens that don't have bottom navigation to enable quick navigation.
class StackedBackHomeFab extends StatelessWidget {
  final String homeRoute;
  final String heroTagBack;
  final String heroTagHome;
  final bool showBack;
  final bool showHome;

  const StackedBackHomeFab({
    super.key,
    this.homeRoute = '/home',
    this.heroTagBack = 'fab_back',
    this.heroTagHome = 'fab_home',
    this.showBack = true,
    this.showHome = true,
  });

  @override
  Widget build(BuildContext context) {
    final go = GoRouter.of(context);
    final canPopGo = go.canPop();
    final canPopNav = Navigator.of(context).canPop();

    final List<Widget> fabs = [];

    if (showBack) {
      fabs.add(
        BackFab(
          heroTag: heroTagBack,
          onPressed: () {
            if (canPopGo) {
              context.pop();
            } else if (canPopNav) {
              Navigator.of(context).maybePop();
            } else {
              context.go(homeRoute);
            }
          },
        ),
      );
    }
    if (showHome) {
      fabs.add(
        HomeFab(
          heroTag: heroTagHome,
          onPressed: () {
            context.go(homeRoute);
          },
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < fabs.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          fabs[i],
        ],
      ],
    );
  }
}

