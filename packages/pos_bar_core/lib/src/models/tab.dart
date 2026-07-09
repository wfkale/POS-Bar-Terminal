import 'order.dart';
import 'tab_deletion_request.dart';

class BarTab {
  const BarTab({
    required this.id,
    required this.customerName,
    this.tableLabel,
    required this.runningTotal,
    required this.status,
    this.pendingDeletionRequest,
  });

  final int id;
  final String customerName;
  final String? tableLabel;
  final double runningTotal;
  final String status;
  final TabDeletionRequestInfo? pendingDeletionRequest;

  factory BarTab.fromJson(Map<String, dynamic> json) => BarTab(
        id: json['id'] as int,
        customerName: json['customer_name'] as String,
        tableLabel: json['table_label'] as String?,
        runningTotal: json['running_total'] == null ? 0 : double.parse(json['running_total'].toString()),
        status: json['status'] as String,
        pendingDeletionRequest: json['pending_deletion_request'] != null
            ? TabDeletionRequestInfo.fromJson(json['pending_deletion_request'] as Map<String, dynamic>)
            : null,
      );
}

class BarTabDetail {
  const BarTabDetail({required this.tab, required this.orders});

  final BarTab tab;
  final List<BarOrder> orders;

  List<BarOrder> get draftOrders => orders.where((o) => o.status == 'draft').toList();

  factory BarTabDetail.fromJson(Map<String, dynamic> json) => BarTabDetail(
        tab: BarTab.fromJson(json),
        orders: (json['orders'] as List<dynamic>? ?? [])
            .map((e) => BarOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Merge draft lines for a single tab bill print.
  BarOrder? mergedDraftOrder() {
    final drafts = draftOrders;
    if (drafts.isEmpty) return null;

    final lines = <OrderLine>[];
    var total = 0.0;
    var subtotal = 0.0;
    var tax = 0.0;

    for (final order in drafts) {
      total += order.total;
      subtotal += order.subtotal ?? order.total;
      tax += order.taxAmount ?? 0;
      lines.addAll(order.lines);
    }

    final anchor = drafts.first;
    return BarOrder(
      id: anchor.id,
      orderNumber: anchor.orderNumber,
      type: anchor.type,
      status: anchor.status,
      total: total,
      subtotal: subtotal,
      taxAmount: tax,
      lines: lines,
      staffName: anchor.staffName,
      tabCustomer: tab.customerName,
    );
  }
}
