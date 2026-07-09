import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({
    super.key,
    required this.api,
    required this.session,
    required this.shift,
    required this.onEndShift,
    required this.onLogout,
  });

  final ApiClient api;
  final StaffSession session;
  final StaffShiftInfo shift;
  final Future<void> Function() onEndShift;
  final Future<void> Function() onLogout;

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  late Timer _pollTimer;
  late Future<List<BarOrder>> _queueFuture;
  bool _paying = false;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _queueFuture = widget.api.fetchCashierQueue();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) VenueScope.of(context).refresh();
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshQueue());
  }

  @override
  void dispose() {
    _pollTimer.cancel();
    super.dispose();
  }

  void _refreshQueue() {
    setState(() => _queueFuture = widget.api.fetchCashierQueue());
  }

  void _refresh() {
    _refreshQueue();
    VenueScope.of(context).refresh();
  }

  Future<void> _openCheckout(BarOrder order) async {
    if (_paying) return;
    await showPayCheckoutSheet(
      context: context,
      order: order,
      onComplete: (method, {required bool withReceipt}) => _pay(order, method, withReceipt: withReceipt),
    );
  }

  /// Print proforma bill only — does not record payment (use checkout for pay).
  Future<void> _printBill(BarOrder order) async {
    final l10n = context.l10n;
    setState(() => _printing = true);
    try {
      final bill = await widget.api.printBill(order.id, type: 'proforma');
      final billNumber = bill['bill_number']?.toString() ?? order.orderNumber;
      final venue = VenueScope.of(context).venue;
      final receipt = BillPrintService.buildBill(
        order: order,
        venue: venue,
        billNumber: billNumber,
      );

      final result = await BillPrintService.printCustomerBill(receipt);
      if (!mounted) return;

      switch (result.status) {
        case BillPrintStatus.printed:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.billPrinted)),
          );
        case BillPrintStatus.noPrinter:
        case BillPrintStatus.failed:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.status == BillPrintStatus.noPrinter
                    ? '${l10n.billPrintFailed}. ${l10n.printerNeeded}'
                    : '${l10n.billPrintFailed}: ${result.message ?? ''}',
              ),
            ),
          );
          await BillPrintService.previewBill(
            context: context,
            receipt: receipt,
            closeLabel: l10n.close,
          );
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _pay(BarOrder order, String method, {required bool withReceipt}) async {
    final l10n = context.l10n;
    setState(() => _paying = true);
    try {
      final paid = await widget.api.payOrder(order.id, method: method);

      if (withReceipt) {
        try {
          final bill = await widget.api.printBill(paid.id, type: 'final');
          final venue = VenueScope.of(context).venue;
          String methodLabel = method;
          for (final m in venue.paymentMethods) {
            if (m.code == method) {
              methodLabel = m.label;
              break;
            }
          }
          await ReceiptPrintService.printFinalReceipt(
            order: paid,
            venue: venue,
            paymentMethod: methodLabel,
            billNumber: bill['bill_number']?.toString(),
            tillLabel: widget.shift.tillName ?? widget.shift.tillCode,
            previewContext: context,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.orderPaid(order.orderNumber)} · ${l10n.receiptPrinted}')),
            );
          }
        } on ThermalPrinterException catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.receiptPrintFailed}: ${e.message}')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.receiptPrintFailed}: $e')),
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.orderPaid(order.orderNumber))));
      }

      if (mounted) _refresh();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _confirmEndShift() async {
    final l10n = context.l10n;
    final closingFloat = await showDialog<String>(
      context: context,
      builder: (ctx) => LocaleScope(
        controller: LocaleScope.of(context),
        child: _CloseShiftDialog(l10n: l10n),
      ),
    );
    if (closingFloat == null || !mounted) return;

    try {
      await widget.api.endShift(
        closingFloat: closingFloat.isEmpty ? null : double.tryParse(closingFloat),
      );
      await widget.onEndShift();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = currencyFormat;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.shift.tillName ?? l10n.bartenderQueue, style: const TextStyle(fontSize: 16)),
            Text(
              '${widget.session.staff.name} · ${widget.shift.tillCode ?? ''}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          FloorAppBarActions(
            trailing: [
              IconButton(
                tooltip: l10n.printerSettings,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
                ),
                icon: const Icon(Icons.print),
              ),
            ],
          ),
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          TextButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout, size: 18),
            label: Text(l10n.logout),
          ),
          TextButton.icon(
            onPressed: _confirmEndShift,
            icon: const Icon(Icons.logout, size: 18),
            label: Text(l10n.closeShift),
          ),
        ],
      ),
      body: FutureBuilder<List<BarOrder>>(
        future: _queueFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppTheme.success.withOpacity(0.7)),
                  const SizedBox(height: 16),
                  Text(l10n.queueClear, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(l10n.waitingOrders, style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final order = orders[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          Chip(label: Text(order.type.toUpperCase()), backgroundColor: AppTheme.surfaceLight),
                        ],
                      ),
                      if (order.staffName != null)
                        Text(l10n.fromStaff(order.staffName!), style: const TextStyle(color: AppTheme.textSecondary)),
                      if (order.tabCustomer != null)
                        Text(l10n.tabCustomer(order.tabCustomer!), style: const TextStyle(color: AppTheme.textSecondary)),
                      const Divider(),
                      ...order.lines.map((l) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Expanded(child: Text('${l.quantity}× ${l.itemName}')),
                                Text(currency.format(l.lineTotal)),
                              ],
                            ),
                          )),
                      const SizedBox(height: 12),
                      Text(
                        currency.format(order.total),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: (_paying || _printing) ? null : () => _printBill(order),
                            icon: _printing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.receipt_long),
                            label: Text(l10n.printBill),
                          ),
                          FilledButton.icon(
                            onPressed: _paying ? null : () => _openCheckout(order),
                            icon: const Icon(Icons.payments),
                            label: Text(l10n.choosePayment),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CloseShiftDialog extends StatefulWidget {
  const _CloseShiftDialog({required this.l10n});

  final AppStrings l10n;

  @override
  State<_CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<_CloseShiftDialog> {
  String _amount = '';

  void _tapKey(String key) {
    setState(() {
      if (key == '.') {
        if (!_amount.contains('.')) _amount += _amount.isEmpty ? '0.' : '.';
      } else {
        _amount += key;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(l10n.closeShift),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.countClosingCash),
            const SizedBox(height: 12),
            Text(
              _amount.isEmpty ? '—' : '$currencyCode $_amount',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            NumericKeypad(
              showDecimal: true,
              keyHeight: 56,
              onDigit: _tapKey,
              onBackspace: () => setState(() {
                if (_amount.isNotEmpty) _amount = _amount.substring(0, _amount.length - 1);
              }),
              onClear: () => setState(() => _amount = ''),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _amount), child: Text(l10n.closeShift)),
      ],
    );
  }
}
