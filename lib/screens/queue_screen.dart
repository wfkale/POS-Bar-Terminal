import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  List<BarOrder>? _orders;
  Object? _loadError;
  bool _loading = true;
  bool _paying = false;
  bool _printing = false;
  final Set<String> _expandedDockets = {};

  @override
  void initState() {
    super.initState();
    _loadQueue();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) VenueScope.of(context).refresh();
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadQueue(silent: true));
  }

  @override
  void dispose() {
    _pollTimer.cancel();
    super.dispose();
  }

  Future<void> _loadQueue({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final orders = await widget.api.fetchCashierQueue();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loadError = null;
        _loading = false;
        _expandedDockets.removeWhere(
          (key) => !StaffQueueDocket.group(orders).any((d) => d.key == key),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  void _refresh() {
    _loadQueue();
    VenueScope.of(context).refresh();
  }

  Future<void> _payWithMethod(BarOrder order, String method) async {
    if (_paying) return;
    await _pay(order, method, withReceipt: true);
  }

  Future<void> _printBill(BarOrder order) async {
    if (_printing) return;
    setState(() => _printing = true);
    try {
      await BillPrintService.printOrderBillWithFeedback(
        context: context,
        api: widget.api,
        order: order,
      );
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
    final orders = _orders;
    final dockets = orders == null ? const <StaffQueueDocket>[] : StaffQueueDocket.group(orders);

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
      body: _buildBody(l10n, currency, dockets),
    );
  }

  Widget _buildBody(AppStrings l10n, NumberFormat currency, List<StaffQueueDocket> dockets) {
    if (_loading && _orders == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }
    if (_loadError != null && _orders == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$_loadError', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _refresh, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }
    if (dockets.isEmpty) {
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

    final totalOrders = dockets.fold<int>(0, (s, d) => s + d.orderCount);
    final totalOwed = dockets.fold<double>(0, (s, d) => s + d.cumulativeOwed);

    return Column(
      children: [
        Material(
          color: AppTheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.view_agenda_outlined, color: AppTheme.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.queueSummary(
                      staffCount: dockets.length,
                      orderCount: totalOrders,
                      total: currency.format(totalOwed),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: dockets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final docket = dockets[i];
              final expanded = _expandedDockets.contains(docket.key);
              return _StaffDocketCard(
                docket: docket,
                currency: currency,
                l10n: l10n,
                expanded: expanded,
                busy: _paying || _printing,
                printing: _printing,
                onToggle: () {
                  setState(() {
                    if (expanded) {
                      _expandedDockets.remove(docket.key);
                    } else {
                      _expandedDockets.add(docket.key);
                    }
                  });
                },
                onPrint: _printBill,
                onPay: _payWithMethod,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StaffDocketCard extends StatelessWidget {
  const _StaffDocketCard({
    required this.docket,
    required this.currency,
    required this.l10n,
    required this.expanded,
    required this.busy,
    required this.printing,
    required this.onToggle,
    required this.onPrint,
    required this.onPay,
  });

  final StaffQueueDocket docket;
  final NumberFormat currency;
  final AppStrings l10n;
  final bool expanded;
  final bool busy;
  final bool printing;
  final VoidCallback onToggle;
  final ValueChanged<BarOrder> onPrint;
  final void Function(BarOrder order, String method) onPay;

  @override
  Widget build(BuildContext context) {
    final displayName = docket.staffName.isEmpty ? l10n.unknownStaff : docket.staffName;
    final initial = displayName.isNotEmpty ? displayName.characters.first.toUpperCase() : '?';

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.accent.withOpacity(0.2),
                    foregroundColor: AppTheme.accent,
                    child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${l10n.staffOrderCount(docket.orderCount)} · ${l10n.cumulativeOwed(currency.format(docket.cumulativeOwed))}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.textSecondary),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...docket.orders.map(
                  (order) => _QueuedOrderTile(
                    order: order,
                    currency: currency,
                    l10n: l10n,
                    busy: busy,
                    printing: printing,
                    onPrint: () => onPrint(order),
                    onPay: (method) => onPay(order, method),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QueuedOrderTile extends StatelessWidget {
  const _QueuedOrderTile({
    required this.order,
    required this.currency,
    required this.l10n,
    required this.busy,
    required this.printing,
    required this.onPrint,
    required this.onPay,
  });

  final BarOrder order;
  final NumberFormat currency;
  final AppStrings l10n;
  final bool busy;
  final bool printing;
  final VoidCallback onPrint;
  final ValueChanged<String> onPay;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final methods = VenueScope.of(context).venue.paymentMethods;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.background),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Chip(
                label: Text(order.type.toUpperCase(), style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
                backgroundColor: AppTheme.surface,
              ),
            ],
          ),
          if (order.tabCustomer != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(l10n.tabCustomer(order.tabCustomer!), style: const TextStyle(color: AppTheme.textSecondary)),
            ),
          const SizedBox(height: 8),
          ...order.lines.map(
            (l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  Expanded(child: Text('${l.quantity}× ${l.itemName}', style: const TextStyle(fontSize: 13))),
                  Text(currency.format(l.lineTotal), style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(currency.format(order.total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : onPrint,
                icon: printing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.receipt_long, size: 18),
                label: Text(l10n.printBill),
              ),
              for (final method in methods)
                FilledButton(
                  onPressed: busy ? null : () => onPay(method.code),
                  child: Text(method.labelForLocale(locale)),
                ),
            ],
          ),
        ],
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
