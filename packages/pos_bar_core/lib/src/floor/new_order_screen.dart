import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

import 'widgets/order_menu_widgets.dart';

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
  int _categoryIndex = 0;
  bool _busy = false;
  bool _searchOpen = false;
  String _searchQuery = '';

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

  bool get _allowOversell => VenueScope.maybeConfigOf(context)?.allowOversell ?? true;

  List<MapEntry<MenuItem, int>> get _stockRiskLines {
    return _cart.entries.where((e) {
      final available = e.key.availableServings;
      if (e.key.isOutOfStock) return true;
      if (available != null && e.value > available) return true;
      return false;
    }).toList();
  }

  String _stockRiskSummary(AppStrings l10n) {
    return _stockRiskLines
        .map((e) {
          final available = e.key.availableServings;
          final availText = available == null ? l10n.stockOut : '$available left';
          return '• ${e.key.name} (${e.value}×, $availText)';
        })
        .join('\n');
  }

  Future<void> _addItem(MenuItem item) async {
    final l10n = context.l10n;
    final nextQty = (_cart[item] ?? 0) + 1;
    final available = item.availableServings;
    final wouldExceed = item.isOutOfStock || (available != null && nextQty > available);

    if (wouldExceed && !_allowOversell) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(l10n.stockBlockedTitle),
          content: Text(l10n.stockBlockedBody(item.name)),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.close)),
          ],
        ),
      );
      return;
    }

    if (wouldExceed && _allowOversell) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(l10n.stockEmptyTitle),
          content: Text(l10n.stockEmptyBody(item.name)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.sellAnyway),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _cart[item] = nextQty);
  }

  void _removeItem(MenuItem item) => setState(() {
        final q = (_cart[item] ?? 1) - 1;
        if (q <= 0) {
          _cart.remove(item);
        } else {
          _cart[item] = q;
        }
      });

  void _clearCart() => setState(() => _cart.clear());

  List<MenuItem> _visibleItems(List<MenuCategory> categories) {
    if (categories.isEmpty) return [];
    final safeIndex = _categoryIndex.clamp(0, categories.length - 1);
    var items = categories[safeIndex].items;
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = categories.expand((c) => c.items).where((i) => i.name.toLowerCase().contains(q)).toList();
    }
    return items;
  }

  Future<String?> _tableLabelForTab(int tabId) async {
    final tabs = await widget.api.fetchOpenTabs();
    return tabs.where((t) => t.id == tabId).map((t) => t.tableLabel).firstOrNull;
  }

  Future<bool> _confirmStockIfNeeded() async {
    final l10n = context.l10n;
    if (_stockRiskLines.isEmpty) return true;

    final summary = _stockRiskSummary(l10n);
    if (!_allowOversell) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(l10n.stockBlockedTitle),
          content: Text(l10n.stockBlockedBody(summary)),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.close)),
          ],
        ),
      );
      return false;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(l10n.stockEmptyTitle),
        content: Text(l10n.stockEmptyBody(summary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.sellAnyway),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _submit(_OrderSubmitAction action) async {
    final l10n = context.l10n;
    if (_cart.isEmpty) return;
    if (widget.type == 'tab' && _selectedTabId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.selectTabFirst)));
      return;
    }
    if (!await _confirmStockIfNeeded()) return;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger),
        );
      }
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

  Widget? _buildTabPicker(AppStrings l10n) {
    if (widget.type != 'tab') return null;
    return FutureBuilder<List<BarTab>>(
      future: _tabsFuture,
      builder: (context, tabSnap) {
        if (!tabSnap.hasData) {
          return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
        }
        final tabs = tabSnap.data!;
        return PopupMenuButton<int>(
          tooltip: l10n.selectTab,
          initialValue: _selectedTabId,
          onSelected: (v) => setState(() => _selectedTabId = v),
          itemBuilder: (context) => tabs
              .map(
                (t) => PopupMenuItem(
                  value: t.id,
                  child: Text('${t.customerName}${t.tableLabel != null ? ' · ${t.tableLabel}' : ''}'),
                ),
              )
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _selectedTabId != null ? AppTheme.accent.withOpacity(0.2) : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _selectedTabId != null ? AppTheme.accent : AppTheme.textSecondary),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tab, size: 20),
                const SizedBox(width: 6),
                Text(
                  _selectedTabId == null
                      ? l10n.selectTab
                      : tabs.where((t) => t.id == _selectedTabId).map((t) => t.customerName).firstOrNull ?? l10n.selectTab,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isTab = widget.type == 'tab';

    return Scaffold(
      body: FutureBuilder<List<MenuCategory>>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          final categories = snapshot.data!;
          if (categories.isEmpty) {
            return Center(child: Text(l10n.noItemsFound));
          }

          final safeIndex = _categoryIndex.clamp(0, categories.length - 1);
          final category = categories[safeIndex];
          final categoryColor = MenuCategoryColors.forIndex(safeIndex);
          final items = _visibleItems(categories);

          return Column(
            children: [
              OrderTopBar(
                title: isTab ? l10n.tabOrder : l10n.cashOrder,
                categoryName: _searchQuery.isNotEmpty ? l10n.searchItems : category.name,
                categoryColor: categoryColor,
                onBack: () => Navigator.pop(context),
                searchOpen: _searchOpen,
                searchQuery: _searchQuery,
                onSearchToggle: () => setState(() {
                  _searchOpen = !_searchOpen;
                  if (!_searchOpen) _searchQuery = '';
                }),
                onSearchChanged: (v) => setState(() => _searchQuery = v),
                tabPicker: _buildTabPicker(l10n),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OrderCartPanel(
                      cart: _cart,
                      total: _total,
                      busy: _busy,
                      isTab: isTab,
                      onIncrement: (item) => _addItem(item),
                      onDecrement: _removeItem,
                      onClear: _clearCart,
                      onAddToTab: () => _submit(_OrderSubmitAction.addToTab),
                      onSendToBartender: () => _submit(_OrderSubmitAction.sendToBartender),
                      onPrintBill: () => _submit(_OrderSubmitAction.printBill),
                      onSendAndPrint: () => _submit(_OrderSubmitAction.sendAndPrint),
                      onViewTab: _viewTab,
                      showViewTab: _selectedTabId != null,
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: AppTheme.background,
                        child: Column(
                          children: [
                            Expanded(
                              child: ProductGrid(
                                items: items,
                                cart: _cart,
                                onAdd: (item) => _addItem(item),
                                onRemove: _removeItem,
                                emptyMessage: _searchQuery.isNotEmpty ? l10n.noItemsFound : null,
                              ),
                            ),
                            if (_searchQuery.isEmpty)
                              CategoryTabBar(
                                categories: categories,
                                selectedIndex: safeIndex,
                                onSelected: (i) => setState(() => _categoryIndex = i),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
