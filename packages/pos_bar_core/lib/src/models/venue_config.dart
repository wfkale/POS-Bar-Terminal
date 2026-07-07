class PaymentMethodOption {
  const PaymentMethodOption({
    required this.code,
    required this.label,
    this.labelSw,
  });

  final String code;
  final String label;
  final String? labelSw;

  String labelForLocale(String languageCode) {
    if (languageCode == 'sw' && labelSw != null && labelSw!.isNotEmpty) {
      return labelSw!;
    }
    return label;
  }

  factory PaymentMethodOption.fromJson(Map<String, dynamic> json) => PaymentMethodOption(
        code: json['code'] as String,
        label: json['label'] as String,
        labelSw: json['label_sw'] as String?,
      );
}

class VenueConfig {
  const VenueConfig({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.currency,
    required this.paymentMethods,
  });

  final int id;
  final String name;
  final String? logoUrl;
  final String currency;
  final List<PaymentMethodOption> paymentMethods;

  factory VenueConfig.fromJson(Map<String, dynamic> json) => VenueConfig(
        id: json['id'] as int,
        name: json['name'] as String,
        logoUrl: json['logo_url'] as String?,
        currency: json['currency'] as String? ?? 'TZS',
        paymentMethods: (json['payment_methods'] as List<dynamic>? ?? [])
            .map((e) => PaymentMethodOption.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  VenueConfig copyWith({
    String? name,
    String? logoUrl,
    String? currency,
    List<PaymentMethodOption>? paymentMethods,
  }) =>
      VenueConfig(
        id: id,
        name: name ?? this.name,
        logoUrl: logoUrl ?? this.logoUrl,
        currency: currency ?? this.currency,
        paymentMethods: paymentMethods ?? this.paymentMethods,
      );

  /// Ensure logo URL is absolute (API may return a path-only URL in some setups).
  VenueConfig withResolvedLogoUrl(String apiBaseUrl) {
    final url = logoUrl;
    if (url == null || url.isEmpty) {
      return this;
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return this;
    }
    final origin = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final path = url.startsWith('/') ? url : '/$url';
    return copyWith(logoUrl: '$origin$path');
  }

  static const fallback = VenueConfig(
    id: 1,
    name: 'POS Bar',
    currency: 'TZS',
    paymentMethods: [
      PaymentMethodOption(code: 'cash', label: 'Cash', labelSw: 'Taslimu'),
      PaymentMethodOption(code: 'card', label: 'Card', labelSw: 'Kadi'),
      PaymentMethodOption(code: 'mobile_money', label: 'M-Pesa', labelSw: 'M-Pesa'),
    ],
  );
}
