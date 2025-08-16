import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:savessa/features/auth/presentation/screens/register_screen.dart';
import 'package:savessa/shared/widgets/world_flag_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RegisterScreen overlay', () {
    testWidgets('shows world overlay while detecting, hides after resolution', (tester) async {
      // Fake detection that resolves after a short delay to simulate async geo
      Future<Country> fakeDetect() async {
        await Future.delayed(const Duration(milliseconds: 150));
        return countries.firstWhere((c) => c.code == 'GB');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegisterScreen(
              detectCountryFn: fakeDetect,
            ),
          ),
        ),
      );

      // Focus the phone field to trigger detection
      // Find the IntlPhoneField and tap it
      final phoneFieldFinder = find.byType(TextField).first;
      await tester.tap(phoneFieldFinder);
      await tester.pump();

      // While detection is pending, overlay should be visible
      expect(find.byType(WorldFlagOverlay), findsOneWidget);

      // After the detection future completes, overlay should disappear
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byType(WorldFlagOverlay), findsNothing);
    });
  });
}
