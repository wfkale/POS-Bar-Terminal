class TabDeletionRequestInfo {
  const TabDeletionRequestInfo({
    required this.id,
    required this.status,
    required this.reason,
    this.requestedByName,
  });

  final int id;
  final String status;
  final String reason;
  final String? requestedByName;

  bool get isPending => status == 'pending';

  factory TabDeletionRequestInfo.fromJson(Map<String, dynamic> json) => TabDeletionRequestInfo(
        id: json['id'] as int,
        status: json['status'] as String,
        reason: json['reason'] as String,
        requestedByName: json['requested_by'] != null
            ? (json['requested_by'] as Map<String, dynamic>)['name'] as String?
            : null,
      );
}
