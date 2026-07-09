/// Data model for proforma bills and final till receipts (80mm thermal).
class BarReceipt {
  const BarReceipt({
    required this.kind,
    required this.venueName,
    required this.documentNumber,
    required this.currency,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.taxRate,
    required this.total,
    required this.printedAt,
    this.location,
    this.phone,
    this.tin,
    this.vrn,
    this.serialNumber,
    this.uin,
    this.zno,
    this.customerVrn,
    this.verificationCode,
    this.discount = 0,
    this.staffName,
    this.customerName,
    this.tableLabel,
    this.orderNumber,
    this.paymentMethod,
    this.tillLabel,
    this.notes,
    this.lipaNumbers = const [],
  });

  /// `proforma` (bill) or `final` (paid receipt).
  final String kind;
  final String venueName;
  final String documentNumber;
  final String currency;
  final List<BarReceiptItem> items;
  final double subtotal;
  final double taxAmount;
  final double taxRate;
  final double total;
  final DateTime printedAt;
  final String? location;
  final String? phone;
  final String? tin;
  final String? vrn;
  final String? serialNumber;
  final String? uin;
  final String? zno;
  final String? customerVrn;
  final String? verificationCode;
  final double discount;
  final String? staffName;
  final String? customerName;
  final String? tableLabel;
  final String? orderNumber;
  final String? paymentMethod;
  final String? tillLabel;
  final String? notes;
  final List<BarReceiptLipa> lipaNumbers;

  bool get isProforma => kind == 'proforma';
}

class BarReceiptLipa {
  const BarReceiptLipa({
    required this.provider,
    required this.number,
  });

  final String provider;
  final String number;
}

class BarReceiptItem {
  const BarReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String name;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
}
