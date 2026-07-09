import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

enum _OrderSubmitAction { addToTab, sendToBartender, printBill, sendAndPrint }

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({
    super.key,
    required this.api,
    required this.type,
    this.initialTabId,
  });

  final ApiClient api;
  final String type;
  final int? initialTabId;

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
    if (widget.type == 'tab') {
      _selectedTabId = widget.initialTabId;
      _tabsFuture = widget.api.fetchOpenTabs();
    }
  }

  double get _total => _cart.entries.fold(0.0, (sum, e) => sum + e.key.sellPrice * e.value);

  Future<String?> _tableLabelForTab(int tabId) async {
    final tabs = await widget.api.fetchOpenTabs();
    return tabs.where((t) => t.id == tabId).map((t) => t.tableLabel).firstOrNull;
  }

  Future<void> _submit(_OrderSubmitAction action) async {
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

      final send = action == _OrderSubmitAction.sendToBartender || action == _OrderSubmitAction.sendAndPrint;
      final print = action == _OrderSubmitAction.printBill || action == _OrderSubmitAction.sendAndPrint;

      if (send) order = await widget.api.sendOrder(order.id);

      if (print) {
        String? tableLabel;
        if (widget.type == 'tab' && _selectedTabId != null) {
          tableLabel = await _tableLabelForTab(_selectedTabId!);
        }
        await BillPrintService.printOrderBillWithFeedback(
          context: context,
          api: widget.api,
          order: order,
          tableLabel: tableLabel,
        );
      }

      if (!mounted) return;
      switch (action) {
        case _OrderSubmitAction.addToTab:
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.addedToTab)));
        case _OrderSubmitAction.sendToBartender:
        case _OrderSubmitAction.sendAndPrint:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.orderSentToCashier(order.orderNumber))),
          );
        case _OrderSubmitAction.printBill:
          break;
      }
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _viewTab() {
    final tabId = _selectedTabId;
    if (tabId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TabDetailScreen(api: widget.api, tabId: tabId)),
    );
  }

  Widget _busyOrLabel(String label) {
    if (_busy) {
      return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Text(label);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = currencyFormat;
    final isTab = widget.type == 'tab';
    return Scaffold(
      appBar: AppBar(
        title: Text(isTab ? l10n.tabOrder : l10n.cashOrder),
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
                    if (isTab)
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
            width: 300,
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
                if (isTab) ...[
                  FilledButton(
                    onPressed: _busy || _cart.isEmpty ? null : () => _submit(_OrderSubmitAction.addToTab),
                    child: _busyOrLabel(l10n.addToTab),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy || _cart.isEmpty ? null : () => _submit(_OrderSubmitAction.sendToBartender),
                    icon: const Icon(Icons.send, size: 18),
                    label: Text(l10n.sendToBartender),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy || _cart.isEmpty ? null : () => _submit(_OrderSubmitAction.printBill),
                    icon: const Icon(Icons.print, size: 18),
                    label: Text(l10n.printBill),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _busy || _cart.isEmpty ? null : () => _submit(_OrderSubmitAction.sendAndPrint),
                    child: Text(l10n.sendAndPrintBill),
                  ),
                  if (_selectedTabId != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _busy ? null : _viewTab,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(l10n.viewTab),
                    ),
                  ],
                ] else ...[
                  FilledButton(
                    onPressed: _busy || _cart.isEmpty ? null : () => _submit(_OrderSubmitAction.sendAndPrint),
                    child: _busyOrLabel(l10n.sendAndPrintBill),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy || _cart.isEmpty ? null : () => _submit(_OrderSubmitAction.sendToBartender),
                    icon: const Icon(Icons.send, size: 18),
                    label: Text(l10n.sendToBartender),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
