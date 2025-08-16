import 'dart:async';
import 'dart:ui' as ui;

import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides country detection for phone input defaults without hardcoding.
///
/// Strategy:
/// - Try device location (with short timeout), then reverse geocode to ISO2.
/// - Fall back to device locale country code if location is unavailable/denied.
/// - Finally fall back to 'US' as a last resort.
/// - Caches last successful ISO2 in-memory and persists to SharedPreferences with TTL.
/// - Respects last user-selected ISO2 if available.
class LocationCountryService {
  LocationCountryService._();
  static final LocationCountryService instance = LocationCountryService._();

  static const Duration _positionTimeout = Duration(seconds: 5);
  static const LocationAccuracy _accuracy = LocationAccuracy.low; // sufficient for country-level

  static const String _prefsKeyDetectedIso = 'phone_region_detected_iso2';
  static const String _prefsKeyDetectedAt = 'phone_region_detected_at';
  static const String _prefsKeyUserSelectedIso = 'phone_region_user_selected_iso2';
  static const String _prefsKeyAutoDetectEnabled = 'phone_region_autodetect_enabled';

  String? _cachedIso2;
  DateTime? _cacheTime;

  /// TTL for persisted detection cache. Default: 24 hours.
  Duration persistedCacheTtl = const Duration(hours: 24);

  /// Optional TTL for in-memory cache. If null, never expires during session.
  Duration? cacheTtl;

  /// Returns the best ISO2 considering user selection, cache, then detection.
  Future<String> detectIso2({bool forceRefresh = false}) async {
    // 1) Respect last user-selected ISO2
    final userIso = await _getUserSelectedIso();
    if (userIso != null && userIso.isNotEmpty && !forceRefresh) {
      _setCache(userIso);
      return userIso.toUpperCase();
    }

    // 2) In-memory cache
    if (!forceRefresh && _cachedIso2 != null) {
      if (cacheTtl == null || (_cacheTime != null && DateTime.now().difference(_cacheTime!) <= cacheTtl!)) {
        return _cachedIso2!;
      }
    }

    // 3) SharedPreferences cache
    if (!forceRefresh) {
      final cached = await _getPersistedDetectedIso();
      if (cached != null) {
        _setCache(cached);
        return cached;
      }
    }

    // 4) Try geolocation first (if auto-detect is enabled)
    final autoEnabled = await getAutoDetectEnabled();
    if (autoEnabled) {
    final isoFromGeo = await _isoFromGeolocation();
    if (isoFromGeo != null) {
      await _persistDetectedIso(isoFromGeo);
      _setCache(isoFromGeo);
      return isoFromGeo;
    }
    } // end if autoEnabled

    // 5) Fallback: device locale
    final isoFromLocale = _isoFromLocale();
    if (isoFromLocale != null) {
      await _persistDetectedIso(isoFromLocale);
      _setCache(isoFromLocale);
      return isoFromLocale;
    }

    // 6) Final fallback
    const fallback = 'US';
    await _persistDetectedIso(fallback);
    _setCache(fallback);
    return fallback;
  }

  /// Convenience: returns the intl_phone_field Country corresponding to detected ISO2.
  Future<Country> detectCountry({bool forceRefresh = false}) async {
    final iso2 = await detectIso2(forceRefresh: forceRefresh);
    return _countryFromIso(iso2);
  }

  /// Persist user-selected region (e.g., when user changes the country in UI).
  Future<void> setUserSelectedIso(String iso2) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyUserSelectedIso, iso2.toUpperCase());
      _setCache(iso2);
    } catch (_) {
      // ignore persistence errors
    }
  }

  Future<String?> _getUserSelectedIso() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefsKeyUserSelectedIso);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistDetectedIso(String iso2) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyDetectedIso, iso2.toUpperCase());
      await prefs.setInt(_prefsKeyDetectedAt, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // ignore persistence errors
    }
  }

  Future<String?> _getPersistedDetectedIso() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final iso = prefs.getString(_prefsKeyDetectedIso);
      final tsMs = prefs.getInt(_prefsKeyDetectedAt);
      if (iso == null || tsMs == null) return null;
      final ts = DateTime.fromMillisecondsSinceEpoch(tsMs);
      if (DateTime.now().difference(ts) <= persistedCacheTtl) {
        return iso.toUpperCase();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _setCache(String iso2) {
    _cachedIso2 = iso2.toUpperCase();
    _cacheTime = DateTime.now();
  }

  Future<String?> _isoFromGeolocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final Position position = await Geolocator
          .getCurrentPosition(desiredAccuracy: _accuracy)
          .timeout(_positionTimeout);

      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        final iso = placemarks.first.isoCountryCode;
        if (iso != null && iso.isNotEmpty) {
          return iso.toUpperCase();
        }
      }
    } catch (_) {
      // Swallow and fall back
    }
    return null;
  }

  String? _isoFromLocale() {
    try {
      final ui.Locale locale = ui.PlatformDispatcher.instance.locale;
      final countryCode = locale.countryCode;
      if (countryCode != null && countryCode.isNotEmpty) {
        return countryCode.toUpperCase();
      }
    } catch (_) {
      // ignore
    }
    return null;
  }

  Country _countryFromIso(String iso2) {
    try {
      return countries.firstWhere(
        (c) => c.code.toUpperCase() == iso2.toUpperCase(),
        orElse: () => countries.firstWhere((c) => c.code == 'US'),
      );
    } catch (_) {
      return countries.firstWhere((c) => c.code == 'US');
    }
  }

  // Auto-detect preference
  Future<bool> getAutoDetectEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Default to true if not set
      return prefs.getBool(_prefsKeyAutoDetectEnabled) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setAutoDetectEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyAutoDetectEnabled, enabled);
    } catch (_) {
      // ignore persistence errors
    }
  }
}

