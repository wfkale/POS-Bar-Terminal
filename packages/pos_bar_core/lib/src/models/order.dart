class BarOrder {
  const BarOrder({
    required this.id,
    required this.orderNumber,
    required this.type,
    required this.status,
    required this.total,
    required this.lines,
    this.staffName,
    this.tabCustomer,
  });

  final int id;
  final String orderNumber;
  final String type;
  final String status;
  final double total;
  final List<OrderLine> lines;
  final String? staffName;
  final String? tabCustomer;

  factory BarOrder.fromJson(Map<String, dynamic> json) => BarOrder(
        id: json['id'] as int,
        orderNumber: json['order_number'] as String,
        type: json['type'] as String,
        status: json['status'] as String,
        total: double.parse(json['total'].toString()),
        lines: (json['lines'] as List<dynamic>? ?? [])
            .map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        staffName: (json['staff'] as Map<String, dynamic>?)?['name'] as String?,
        tabCustomer: (json['tab'] as Map<String, dynamic>?)?['customer_name'] as String?,
      );
}

class OrderLine {
  const OrderLine({
    required this.itemName,
    required this.quantity,
    required this.lineTotal,
  });

  final String itemName;
  final int quantity;
  final double lineTotal;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        itemName: json['item_name'] as String,
        quantity: json['quantity'] as int,
        lineTotal: double.parse(json['line_total'].toString()),
      );
}
