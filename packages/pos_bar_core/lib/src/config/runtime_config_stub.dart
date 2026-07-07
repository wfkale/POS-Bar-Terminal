class PosRuntimeApiConfig {
  const PosRuntimeApiConfig({
    this.onlineApiBaseUrl,
    this.apiBaseUrl,
  });

  final String? onlineApiBaseUrl;
  final String? apiBaseUrl;
}

PosRuntimeApiConfig? readRuntimeApiConfig() => null;
