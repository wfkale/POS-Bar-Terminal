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
    this.taxRate = 18,
    this.address,
    this.phone,
    this.tin,
    this.vrn,
  });

  final int id;
  final String name;
  final String? logoUrl;
  final String currency;
  final List<PaymentMethodOption> paymentMethods;
  final double taxRate;
  final String? address;
  final String? phone;
  final String? tin;
  final String? vrn;

  factory VenueConfig.fromJson(Map<String, dynamic> json) => VenueConfig(
        id: json['id'] as int,
        name: json['name'] as String,
        logoUrl: json['logo_url'] as String?,
        currency: json['currency'] as String? ?? 'TZS',
        taxRate: json['tax_rate'] == null ? 18 : double.tryParse(json['tax_rate'].toString()) ?? 18,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        tin: json['tin'] as String?,
        vrn: json['vrn'] as String?,
        paymentMethods: (json['payment_methods'] as List<dynamic>? ?? [])
            .map((e) => PaymentMethodOption.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  VenueConfig copyWith({
    String? name,
    String? logoUrl,
    String? currency,
    List<PaymentMethodOption>? paymentMethods,
    double? taxRate,
    String? address,
    String? phone,
    String? tin,
    String? vrn,
  }) =>
      VenueConfig(
        id: id,
        name: name ?? this.name,
        logoUrl: logoUrl ?? this.logoUrl,
        currency: currency ?? this.currency,
        paymentMethods: paymentMethods ?? this.paymentMethods,
        taxRate: taxRate ?? this.taxRate,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        tin: tin ?? this.tin,
        vrn: vrn ?? this.vrn,
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
    taxRate: 18,
    paymentMethods: [
      PaymentMethodOption(code: 'cash', label: 'Cash', labelSw: 'Taslimu'),
      PaymentMethodOption(code: 'card', label: 'Card', labelSw: 'Kadi'),
      PaymentMethodOption(code: 'mobile_money', label: 'M-Pesa', labelSw: 'M-Pesa'),
    ],
  );
}
