class LipaNumber {
  const LipaNumber({
    required this.provider,
    required this.number,
  });

  final String provider;
  final String number;

  factory LipaNumber.fromJson(Map<String, dynamic> json) => LipaNumber(
        provider: json['provider'] as String? ?? '',
        number: json['number'] as String? ?? '',
      );
}

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
    this.lipaNumbers = const [],
    this.taxRate = 18,
    this.allowOversell = true,
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
  final List<LipaNumber> lipaNumbers;
  final double taxRate;
  final bool allowOversell;
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
        allowOversell: json['allow_oversell'] != false,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        tin: json['tin'] as String?,
        vrn: json['vrn'] as String?,
        paymentMethods: (json['payment_methods'] as List<dynamic>? ?? [])
            .map((e) => PaymentMethodOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        lipaNumbers: (json['lipa_numbers'] as List<dynamic>? ?? [])
            .map((e) => LipaNumber.fromJson(e as Map<String, dynamic>))
            .where((l) => l.provider.isNotEmpty && l.number.isNotEmpty)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logo_url': logoUrl,
        'currency': currency,
        'tax_rate': taxRate,
        'allow_oversell': allowOversell,
        'address': address,
        'phone': phone,
        'tin': tin,
        'vrn': vrn,
        'payment_methods': paymentMethods
            .map((m) => {
                  'code': m.code,
                  'label': m.label,
                  if (m.labelSw != null) 'label_sw': m.labelSw,
                })
            .toList(),
        'lipa_numbers': lipaNumbers
            .map((l) => {
                  'provider': l.provider,
                  'number': l.number,
                })
            .toList(),
      };

  VenueConfig copyWith({
    String? name,
    String? logoUrl,
    String? currency,
    List<PaymentMethodOption>? paymentMethods,
    List<LipaNumber>? lipaNumbers,
    double? taxRate,
    bool? allowOversell,
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
        lipaNumbers: lipaNumbers ?? this.lipaNumbers,
        taxRate: taxRate ?? this.taxRate,
        allowOversell: allowOversell ?? this.allowOversell,
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
    allowOversell: true,
    paymentMethods: [
      PaymentMethodOption(code: 'cash', label: 'Cash', labelSw: 'Taslimu'),
      PaymentMethodOption(code: 'card', label: 'Card', labelSw: 'Kadi'),
      PaymentMethodOption(code: 'mobile_money', label: 'M-Pesa', labelSw: 'M-Pesa'),
    ],
  );
}
