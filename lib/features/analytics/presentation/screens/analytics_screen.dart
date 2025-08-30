import 'package:flutter/material.dart';
import 'package:savessa/shared/widgets/screen_scaffold.dart';
import 'package:savessa/shared/widgets/app_card.dart';
import 'package:savessa/shared/widgets/profile_app_bar.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
return Scaffold(
      appBar: ProfileAppBar(),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              padding: EdgeInsets.all(16),
              child: Text('Analytics and insights will appear here.'),
            ),
          ],
        ),
      ),
    );
  }
}

