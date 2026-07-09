import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

class TabDetailScreen extends StatefulWidget {
  const TabDetailScreen({super.key, required this.api, required this.tabId});

  final ApiClient api;
  final int tabId;

  @override
  State<TabDetailScreen> createState() => _TabDetailScreenState();
}

class _TabDetailScreenState extends State<TabDetailScreen> {
  late Future<BarTabDetail> _detailFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() => setState(() => _detailFuture = widget.api.fetchTabDetail(widget.tabId));

  Future<void> _sendToBartender(BarTabDetail detail) async {
    final l10n = context.l10n;
    final drafts = detail.draftOrders;
    if (drafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noDraftOrdersOnTab)));
      return;
    }

    setState(() => _busy = true);
    try {
      for (final order in drafts) {
        await widget.api.sendOrder(order.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.tabSentToBartender)));
        _refresh();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _printTabBill(BarTabDetail detail) async {
    final l10n = context.l10n;
    final merged = detail.mergedDraftOrder();
    if (merged == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noDraftOrdersOnTab)));
      return;
    }

    setState(() => _busy = true);
    try {
      await BillPrintService.printOrderBillWithFeedback(
        context: context,
        api: widget.api,
        order: merged,
        tableLabel: detail.tab.tableLabel,
      );
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelTab(BarTab tab) async {
    final l10n = context.l10n;
    final reasonController = TextEditingController();
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(l10n.cancelTab),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${tab.customerName}${tab.tableLabel != null ? ' · ${tab.tableLabel}' : ''}'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(labelText: l10n.cancelTabReason),
                maxLines: 3,
                enabled: !submitting,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: submitting ? null : () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final reason = reasonController.text.trim();
                      if (reason.isEmpty) return;
                      setDialogState(() => submitting = true);
                      try {
                        await widget.api.requestTabDeletion(tab.id, reason: reason);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.tabCancelRequested)));
                          Navigator.pop(context);
                        }
                      } on ApiException catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        }
                      } finally {
                        if (ctx.mounted) setDialogState(() => submitting = false);
                      }
                    },
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.cancelTab),
            ),
          ],
        ),
      ),
    );
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = currencyFormat;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabDetails),
        actions: const [FloorAppBarActions()],
      ),
      body: FutureBuilder<BarTabDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          final detail = snapshot.data!;
          final tab = detail.tab;
          final pending = tab.pendingDeletionRequest?.isPending ?? false;
          final drafts = detail.draftOrders;
          final sent = detail.orders.where((o) => o.status == 'sent_to_cashier').toList();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tab.customerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            if (tab.tableLabel != null)
                              Text(tab.tableLabel!, style: const TextStyle(color: AppTheme.textSecondary)),
                            const SizedBox(height: 8),
                            Text('${l10n.total}: ${currency.format(tab.runningTotal)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            if (pending)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(l10n.deletionPending, style: const TextStyle(color: AppTheme.accent)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (drafts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(l10n.draftOrders, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...drafts.map((order) => _OrderCard(order: order, currency: currency)),
                    ],
                    if (sent.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(l10n.sentOrders, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...sent.map((order) => _OrderCard(order: order, currency: currency)),
                    ],
                  ],
                ),
              ),
              if (!pending)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: _busy || drafts.isEmpty ? null : () => _sendToBartender(detail),
                          icon: const Icon(Icons.send),
                          label: Text(l10n.sendToBartender),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _busy || drafts.isEmpty ? null : () => _printTabBill(detail),
                          icon: const Icon(Icons.print),
                          label: Text(l10n.printBill),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : () => _cancelTab(tab),
                          icon: const Icon(Icons.cancel_outlined, color: AppTheme.danger),
                          label: Text(l10n.cancelTab, style: const TextStyle(color: AppTheme.danger)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.currency});

  final BarOrder order;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Chip(label: Text(order.status.replaceAll('_', ' ')), backgroundColor: AppTheme.surfaceLight),
              ],
            ),
            const SizedBox(height: 8),
            ...order.lines.map(
              (line) => Text('${line.quantity}× ${line.itemName} · ${currency.format(line.lineTotal)}'),
            ),
            const Divider(),
            Text(currency.format(order.total), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
