import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../config/app_config.dart';
import '../models/venue_config.dart';

export '../models/venue_config.dart';

class VenueConfigController extends ChangeNotifier {
  VenueConfigController({required this.config, this.venueId = 1});

  final AppConfig config;
  final int venueId;

  static const _cacheKeyPrefix = 'venue_config_cache_v1_';

  VenueConfig _venue = VenueConfig.fallback;
  bool _loaded = false;
  bool _fromCache = false;

  VenueConfig get venue => _venue;
  bool get isLoaded => _loaded;

  String get _cacheKey => '$_cacheKeyPrefix$venueId';

  Future<void> load() async {
    await _restoreCache();
    if (_fromCache) {
      notifyListeners();
    }

    try {
      final client = ApiClient(config: config);
      final fetched = await client.fetchVenueConfig(venueId: venueId);
      _venue = fetched.withResolvedLogoUrl(config.apiBaseUrl);
      await _persistCache(_venue);
      _fromCache = false;
    } catch (_) {
      // Keep cached branding after failed refresh (e.g. during app updates).
      if (!_fromCache && _venue.logoUrl == null) {
        _venue = VenueConfig.fallback;
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> refresh() => load();

  Future<void> _restoreCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      _venue = VenueConfig.fromJson(decoded).withResolvedLogoUrl(config.apiBaseUrl);
      _fromCache = true;
    } catch (_) {
      // Ignore corrupt cache.
    }
  }

  Future<void> _persistCache(VenueConfig venue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(venue.toJson()));
    } catch (_) {
      // Non-fatal.
    }
  }
}

class VenueScope extends InheritedNotifier<VenueConfigController> {
  const VenueScope({
    super.key,
    required VenueConfigController controller,
    required super.child,
  }) : super(notifier: controller);

  static VenueConfigController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<VenueScope>();
    assert(scope != null, 'VenueScope not found');
    return scope!.notifier!;
  }

  static VenueConfig? maybeConfigOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<VenueScope>()?.notifier?.venue;
  }
}

extension VenueContext on BuildContext {
  VenueConfig get venueConfig => VenueScope.of(this).venue;
}
