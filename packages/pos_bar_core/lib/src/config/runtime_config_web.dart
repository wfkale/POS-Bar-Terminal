import 'dart:html' as html;

class PosRuntimeApiConfig {
  const PosRuntimeApiConfig({
    this.onlineApiBaseUrl,
    this.apiBaseUrl,
  });

  final String? onlineApiBaseUrl;
  final String? apiBaseUrl;
}

String? _readMeta(String name) {
  final value = html.document
      .querySelector('meta[name="$name"]')
      ?.getAttribute('content')
      ?.trim();
  if (value == null || value.isEmpty || value.contains('__POS_')) {
    return null;
  }
  return value;
}

PosRuntimeApiConfig? readRuntimeApiConfig() {
  final online = _readMeta('pos-online-api-base-url');
  final api = _readMeta('pos-api-base-url');
  if (online == null && api == null) {
    return null;
  }
  return PosRuntimeApiConfig(onlineApiBaseUrl: online, apiBaseUrl: api);
}
