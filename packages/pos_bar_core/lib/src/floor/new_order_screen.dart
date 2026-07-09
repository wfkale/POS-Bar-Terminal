import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key, required this.api, required this.type});

  final ApiClient api;
  final String type;

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  late Future<List<MenuCategory>> _menuFuture;
  late Future<List<BarTab>> _tabsFuture;
  final _cart = <MenuItem, int>{};
  int? _selectedTabId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _menuFuture = widget.api.fetchMenu();
    if (widget.type == 'tab') _tabsFuture = widget.api.fetchOpenTabs();
  }

  double get _total => _cart.entries.fold(0.0, (sum, e) => sum + e.key.sellPrice * e.value);

  Future<void> _submit({bool sendToCashier = true}) async {
    final l10n = context.l10n;
    if (_cart.isEmpty) return;
    if (widget.type == 'tab' && _selectedTabId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.selectTabFirst)));
      return;
    }
    setState(() => _busy = true);
    try {
      final lines = _cart.entries
          .map((e) => {'menu_item_id': e.key.id, 'quantity': e.value})
          .toList();
      var order = await widget.api.createOrder(type: widget.type, tabId: _selectedTabId, lines: lines);
      if (sendToCashier) order = await widget.api.sendOrder(order.id);
      final bill = await widget.api.printBill(order.id);
      final billNumber = bill['bill_number']?.toString() ?? order.orderNumber;
      final venue = VenueScope.of(context).venue;
      final receipt = BillPrintService.buildBill(
        order: order,
        venue: venue,
        billNumber: billNumber,
      );

      final printResult = await BillPrintService.printCustomerBill(receipt);
      if (!printResult.ok && mounted && printResult.status != BillPrintStatus.noPrinter) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.billPrintFailed}: ${printResult.message ?? ''}')),
        );
      }

      if (!mounted) return;
      await BillPrintService.previewBill(
        context: context,
        receipt: receipt,
        closeLabel: l10n.close,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sendToCashier ? l10n.orderSentToCashier(order.orderNumber) : l10n.billPrinted)),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = currencyFormat;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == 'cash' ? l10n.cashOrder : l10n.tabOrder),
        actions: const [FloorAppBarActions()],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: FutureBuilder<List<MenuCategory>>(
              future: _menuFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (widget.type == 'tab')
                      FutureBuilder<List<BarTab>>(
                        future: _tabsFuture,
                        builder: (context, tabSnap) {
                          if (!tabSnap.hasData) return const LinearProgressIndicator();
                          return DropdownButtonFormField<int>(
                            value: _selectedTabId,
                            decoration: InputDecoration(labelText: l10n.selectTab),
                            items: tabSnap.data!
                                .map((t) => DropdownMenuItem(value: t.id, child: Text('${t.customerName} (${t.tableLabel ?? '—'})')))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedTabId = v),
                          );
                        },
                      ),
                    ...snapshot.data!.expand((cat) sync* {
                      yield Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(cat.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.accent)),
                      );
                      for (final item in cat.items) {
                        yield ListTile(
                          title: Text(item.name),
                          subtitle: Text(currency.format(item.sellPrice)),
                          trailing: _cart[item] != null
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(onPressed: () => setState(() {
                                          final q = (_cart[item] ?? 1) - 1;
                                          if (q <= 0) {
                                            _cart.remove(item);
                                          } else {
                                            _cart[item] = q;
                                          }
                                        }), icon: const Icon(Icons.remove)),
                                    Text('${_cart[item]}'),
                                    IconButton(onPressed: () => setState(() => _cart[item] = (_cart[item] ?? 0) + 1), icon: const Icon(Icons.add)),
                                  ],
                                )
                              : IconButton(onPressed: () => setState(() => _cart[item] = 1), icon: const Icon(Icons.add_circle_outline)),
                        );
                      }
                    }),
                  ],
                );
              },
            ),
          ),
          Container(
            width: 280,
            color: AppTheme.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.cart, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: _cart.entries
                        .map((e) => ListTile(
                              dense: true,
                              title: Text('${e.value}× ${e.key.name}'),
                              trailing: Text(currency.format(e.key.sellPrice * e.value)),
                            ))
                        .toList(),
                  ),
                ),
                Text('${l10n.total}: ${currency.format(_total)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy || _cart.isEmpty ? null : () => _submit(),
                  child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.sendAndPrintBill),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
