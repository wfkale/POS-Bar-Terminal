class BarOrder {
  const BarOrder({
    required this.id,
    required this.orderNumber,
    required this.type,
    required this.status,
    required this.total,
    required this.lines,
    this.subtotal,
    this.taxAmount,
    this.staffId,
    this.staffName,
    this.tabCustomer,
    this.paymentMethod,
  });

  final int id;
  final String orderNumber;
  final String type;
  final String status;
  final double total;
  final double? subtotal;
  final double? taxAmount;
  final List<OrderLine> lines;
  final int? staffId;
  final String? staffName;
  final String? tabCustomer;
  final String? paymentMethod;

  factory BarOrder.fromJson(Map<String, dynamic> json) {
    final payments = json['payments'] as List<dynamic>? ?? [];
    String? method;
    if (payments.isNotEmpty) {
      final first = payments.first;
      if (first is Map<String, dynamic>) {
        method = first['method'] as String?;
      }
    }

    final staff = json['staff'] as Map<String, dynamic>?;

    return BarOrder(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      total: double.parse(json['total'].toString()),
      subtotal: json['subtotal'] == null ? null : double.tryParse(json['subtotal'].toString()),
      taxAmount: json['tax_amount'] == null ? null : double.tryParse(json['tax_amount'].toString()),
      lines: (json['lines'] as List<dynamic>? ?? [])
          .map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      staffId: staff?['id'] as int?,
      staffName: staff?['name'] as String?,
      tabCustomer: (json['tab'] as Map<String, dynamic>?)?['customer_name'] as String?,
      paymentMethod: method,
    );
  }
}

class OrderLine {
  const OrderLine({
    required this.itemName,
    required this.quantity,
    required this.lineTotal,
    this.unitPrice,
  });

  final String itemName;
  final int quantity;
  final double lineTotal;
  final double? unitPrice;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        itemName: json['item_name'] as String,
        quantity: (json['quantity'] as num).toInt(),
        lineTotal: double.parse(json['line_total'].toString()),
        unitPrice: json['unit_price'] == null ? null : double.tryParse(json['unit_price'].toString()),
      );
}
