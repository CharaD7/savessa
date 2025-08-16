import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl_phone_field/countries.dart';

import 'package:savessa/features/auth/presentation/components/signup_form_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phone field world overlay', () {
    testWidgets('shows world overlay when detecting', (tester) async {
      final formKey = GlobalKey<FormState>();
      final first = TextEditingController();
      final middle = TextEditingController();
      final last = TextEditingController();
      final email = TextEditingController();
      final phone = TextEditingController();
      final pass = TextEditingController();
      final confirmPass = TextEditingController();

      final f1 = FocusNode();
      final f2 = FocusNode();
      final f3 = FocusNode();
      final f4 = FocusNode();
      final f5 = FocusNode();
      final f6 = FocusNode();
      final f7 = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignUpFormComponent(
              formKey: formKey,
              firstNameController: first,
              middleNameController: middle,
              lastNameController: last,
              emailController: email,
              phoneController: phone,
              passwordController: pass,
              confirmPasswordController: confirmPass,
              firstNameFocus: f1,
              middleNameFocus: f2,
              lastNameFocus: f3,
              emailFocus: f4,
              phoneFocus: f5,
              passwordFocus: f6,
              confirmPasswordFocus: f7,
              onSignup: () {},
              selectedCountry: countries.firstWhere((c) => c.code == 'US'),
              showPhoneDetecting: true,
            ),
          ),
        ),
      );

      // World overlay icon present
      expect(find.byIcon(Icons.public), findsOneWidget);
    });

    testWidgets('hides world overlay when not detecting', (tester) async {
      final formKey = GlobalKey<FormState>();
      final first = TextEditingController();
      final middle = TextEditingController();
      final last = TextEditingController();
      final email = TextEditingController();
      final phone = TextEditingController();
      final pass = TextEditingController();
      final confirmPass = TextEditingController();

      final f1 = FocusNode();
      final f2 = FocusNode();
      final f3 = FocusNode();
      final f4 = FocusNode();
      final f5 = FocusNode();
      final f6 = FocusNode();
      final f7 = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignUpFormComponent(
              formKey: formKey,
              firstNameController: first,
              middleNameController: middle,
              lastNameController: last,
              emailController: email,
              phoneController: phone,
              passwordController: pass,
              confirmPasswordController: confirmPass,
              firstNameFocus: f1,
              middleNameFocus: f2,
              lastNameFocus: f3,
              emailFocus: f4,
              phoneFocus: f5,
              passwordFocus: f6,
              confirmPasswordFocus: f7,
              onSignup: () {},
              selectedCountry: countries.firstWhere((c) => c.code == 'US'),
              showPhoneDetecting: false,
            ),
          ),
        ),
      );

      // World overlay icon absent
      expect(find.byIcon(Icons.public), findsNothing);
    });
  });
}
