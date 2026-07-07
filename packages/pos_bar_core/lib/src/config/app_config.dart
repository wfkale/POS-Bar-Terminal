import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'runtime_config.dart';

/// API base URL with runtime loading from Railway (`app-config.json` / meta tags).
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final String apiBaseUrl;

  static const defaultApiUrl = 'http://localhost:8000/api';
  static const defaultProductionApiUrl =
      'https://pos-bar-api-production.up.railway.app/api';

  static String? _resolvedApiBaseUrl;

  /// Load config from meta tags, `/app-config.json`, then compile-time override.
  static Future<AppConfig> load() async {
    if (_resolvedApiBaseUrl != null) {
      return AppConfig(apiBaseUrl: _resolvedApiBaseUrl!);
    }

    _applyRuntimeConfig(readRuntimeApiConfig());
    if (_resolvedApiBaseUrl == null) {
      await _loadRuntimeConfigFromJson();
    }

    const compileTime = String.fromEnvironment('API_URL');
    if (compileTime.isNotEmpty) {
      _resolvedApiBaseUrl = _normalizeUrl(compileTime);
    }

    _resolvedApiBaseUrl ??= _normalizeUrl(
      kReleaseMode ? defaultProductionApiUrl : defaultApiUrl,
    );

    if (kDebugMode) {
      debugPrint('AppConfig: apiBaseUrl=$_resolvedApiBaseUrl');
    }

    return AppConfig(apiBaseUrl: _resolvedApiBaseUrl!);
  }

  static void _applyRuntimeConfig(PosRuntimeApiConfig? config) {
    if (config == null) {
      return;
    }

    final url = config.apiBaseUrl ?? config.onlineApiBaseUrl;
    if (url != null && url.isNotEmpty) {
      _resolvedApiBaseUrl = _normalizeUrl(url);
    }
  }

  static Future<void> _loadRuntimeConfigFromJson() async {
    if (!kIsWeb) {
      return;
    }

    try {
      final uri = Uri.parse(
        '${Uri.base.origin}/app-config.json?v=${DateTime.now().millisecondsSinceEpoch}',
      );
      final response = await http
          .get(uri, headers: {'Cache-Control': 'no-cache'})
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        return;
      }

      final body = jsonDecode(response.body);
      if (body is! Map) {
        return;
      }

      final online = body['online_api_base_url']?.toString().trim();
      final offline = body['api_base_url']?.toString().trim();
      final url = (offline != null && offline.isNotEmpty) ? offline : online;

      if (url != null && url.isNotEmpty) {
        _resolvedApiBaseUrl = _normalizeUrl(url);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppConfig: app-config.json failed ($e)');
      }
    }
  }

  static String _normalizeUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) {
      return defaultApiUrl;
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.endsWith('/api')) {
      url = '$url/api';
    }
    return url;
  }
}
