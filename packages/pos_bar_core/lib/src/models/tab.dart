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
