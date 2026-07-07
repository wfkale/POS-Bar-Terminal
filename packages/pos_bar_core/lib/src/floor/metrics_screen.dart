import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myPerformance),
        actions: const [FloorAppBarActions()],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: api.fetchMyMetrics(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final m = snapshot.data!;
          return GridView.count(
            padding: const EdgeInsets.all(20),
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _MetricCard(l10n.tabsOpened, '${m['tabs_opened']}'),
              _MetricCard(l10n.ordersCreated, '${m['orders_created']}'),
              _MetricCard(l10n.ordersPaid, '${m['orders_paid']}'),
              _MetricCard(l10n.totalSales, formatMoneyCompact(m['total_sales'] as num)),
              _MetricCard(l10n.avgOrder, formatMoneyCompact(m['average_order_value'] as num)),
              _MetricCard(l10n.billsPrinted, '${m['bills_printed']}'),
              _MetricCard(l10n.voids, '${m['voids']}'),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
