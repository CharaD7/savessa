import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:savessa/services/location_country_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocationCountryService', () {
    test('respects user selected ISO2 over detection/cache', () async {
      final svc = LocationCountryService.instance;

      await svc.setUserSelectedIso('GH');
      final iso = await svc.detectIso2();

      expect(iso, equals('GH'));
    });

    test('auto-detect preference persists and reads back correctly', () async {
      final svc = LocationCountryService.instance;

      await svc.setAutoDetectEnabled(false);
      expect(await svc.getAutoDetectEnabled(), isFalse);

      await svc.setAutoDetectEnabled(true);
      expect(await svc.getAutoDetectEnabled(), isTrue);
    });

    test('uses persisted detected ISO2 when available and fresh', () async {
      final svc = LocationCountryService.instance;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone_region_detected_iso2', 'GB');
      await prefs.setInt('phone_region_detected_at', DateTime.now().millisecondsSinceEpoch);

      final iso = await svc.detectIso2(forceRefresh: false);
      expect(iso, equals('GB'));
    });
  });
}
