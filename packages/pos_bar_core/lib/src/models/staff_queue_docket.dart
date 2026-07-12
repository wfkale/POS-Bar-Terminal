import 'order.dart';

/// Queued orders for one sending staff member (attendant / bartender).
class StaffQueueDocket {
  const StaffQueueDocket({
    required this.key,
    required this.staffId,
    required this.staffName,
    required this.orders,
  });

  final String key;
  final int? staffId;
  final String staffName;
  final List<BarOrder> orders;

  int get orderCount => orders.length;

  double get cumulativeOwed =>
      orders.fold<double>(0, (sum, order) => sum + order.total);

  /// Group pay-queue orders by the staff who sent them (oldest first within each docket).
  static List<StaffQueueDocket> group(List<BarOrder> orders) {
    final buckets = <String, List<BarOrder>>{};
    final names = <String, String>{};
    final ids = <String, int?>{};

    for (final order in orders) {
      final id = order.staffId;
      final name = (order.staffName ?? '').trim();
      final key = id != null ? 'id:$id' : 'name:${name.isEmpty ? 'unknown' : name.toLowerCase()}';
      buckets.putIfAbsent(key, () => <BarOrder>[]).add(order);
      ids[key] = id;
      names[key] = name;
    }

    final dockets = buckets.entries
        .map(
          (e) => StaffQueueDocket(
            key: e.key,
            staffId: ids[e.key],
            staffName: names[e.key] ?? '',
            orders: List<BarOrder>.unmodifiable(e.value),
          ),
        )
        .toList()
      ..sort((a, b) {
        final byName = a.staffName.toLowerCase().compareTo(b.staffName.toLowerCase());
        if (byName != 0) return byName;
        return a.key.compareTo(b.key);
      });

    return List<StaffQueueDocket>.unmodifiable(dockets);
  }
}
