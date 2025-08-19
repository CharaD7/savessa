import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savessa/shared/widgets/screen_scaffold.dart';
import 'package:savessa/shared/widgets/stacked_back_home_fab.dart';

void main() {
  group('ScreenScaffold FAB visibility', () {
    testWidgets('shows stacked back/home FAB when showBackHomeFab is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScreenScaffold(
            title: 'Test',
            showBackHomeFab: true,
            body: SizedBox.shrink(),
          ),
        ),
      );

      // StackedBackHomeFab should be present
      expect(find.byType(StackedBackHomeFab), findsOneWidget);
    });

    testWidgets('does not show stacked back/home FAB when showBackHomeFab is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScreenScaffold(
            title: 'Test',
            showBackHomeFab: false,
            body: SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(StackedBackHomeFab), findsNothing);
    });
  });
}

