import 'package:flutter/material.dart';
import 'package:savessa/shared/widgets/screen_scaffold.dart';
import 'package:savessa/shared/widgets/app_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
return const ScreenScaffold(
      title: 'Analytics',
body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: EdgeInsets.all(16),
            child: Text('Analytics and insights will appear here.'),
          ),
        ],
      ),
    );
  }
}

