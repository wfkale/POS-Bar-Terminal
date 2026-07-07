import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../config/app_config.dart';
import '../models/venue_config.dart';

export '../models/venue_config.dart';

class VenueConfigController extends ChangeNotifier {
  VenueConfigController({required this.config, this.venueId = 1});

  final AppConfig config;
  final int venueId;

  VenueConfig _venue = VenueConfig.fallback;
  bool _loaded = false;

  VenueConfig get venue => _venue;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    try {
      final client = ApiClient(config: config);
      final fetched = await client.fetchVenueConfig(venueId: venueId);
      _venue = fetched.withResolvedLogoUrl(config.apiBaseUrl);
    } catch (_) {
      _venue = VenueConfig.fallback;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> refresh() => load();
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
