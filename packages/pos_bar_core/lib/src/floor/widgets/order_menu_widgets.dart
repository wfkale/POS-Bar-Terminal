import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

/// Distinct tab colours for bottom category navigation (cycles by index).
class MenuCategoryColors {
  static const _palette = <Color>[
    Color(0xFFfbbf24),
    Color(0xFF92400e),
    Color(0xFFd4a574),
    Color(0xFF166534),
    Color(0xFFca8a04),
    Color(0xFF16a34a),
    Color(0xFF64748b),
    Color(0xFFea580c),
    Color(0xFF7c3aed),
    Color(0xFF0891b2),
  ];

  static Color forIndex(int index) => _palette[index % _palette.length];

  static Color labelOn(Color background) =>
      background.computeLuminance() > 0.45 ? const Color(0xFF1e293b) : Colors.white;
}

class OrderTopBar extends StatelessWidget {
  const OrderTopBar({
    super.key,
    required this.title,
    required this.categoryName,
    required this.categoryColor,
    required this.onBack,
    this.searchQuery = '',
    this.searchOpen = false,
    this.onSearchToggle,
    this.onSearchChanged,
    this.tabPicker,
  });

  final String title;
  final String categoryName;
  final Color categoryColor;
  final VoidCallback onBack;
  final String searchQuery;
  final bool searchOpen;
  final VoidCallback? onSearchToggle;
  final ValueChanged<String>? onSearchChanged;
  final Widget? tabPicker;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: AppTheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    onPressed: onBack,
                    tooltip: l10n.close,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        Text(
                          categoryName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: categoryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tabPicker != null) ...[tabPicker!, const SizedBox(width: 8)],
                  if (onSearchToggle != null)
                    IconButton(
                      icon: Icon(searchOpen ? Icons.search_off : Icons.search, size: 26),
                      tooltip: l10n.searchItems,
                      onPressed: onSearchToggle,
                    ),
                  const FloorAppBarActions(),
                ],
              ),
            ),
          ),
          if (searchOpen && onSearchChanged != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                autofocus: true,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: l10n.searchItems,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CategoryTabBar extends StatelessWidget {
  const CategoryTabBar({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<MenuCategory> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final color = MenuCategoryColors.forIndex(index);
              final selected = index == selectedIndex;
              final labelColor = MenuCategoryColors.labelOn(color);
              return Material(
                color: color,
                borderRadius: BorderRadius.circular(10),
                elevation: selected ? 4 : 0,
                child: InkWell(
                  onTap: () => onSelected(index),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: selected ? Border.all(color: Colors.white, width: 3) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: labelColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.items,
    required this.cart,
    required this.onAdd,
    required this.onRemove,
    this.emptyMessage,
  });

  final List<MenuItem> items;
  final Map<MenuItem, int> cart;
  final ValueChanged<MenuItem> onAdd;
  final ValueChanged<MenuItem> onRemove;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMessage ?? context.l10n.noItemsFound,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnCount(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _ProductTile(
            item: items[index],
            quantity: cart[items[index]] ?? 0,
            onTap: () => onAdd(items[index]),
            onRemove: () => onRemove(items[index]),
          ),
        );
      },
    );
  }

  int _columnCount(double width) {
    if (width > 1100) return 6;
    if (width > 850) return 5;
    if (width > 600) return 4;
    return 3;
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.item,
    required this.quantity,
    required this.onTap,
    required this.onRemove,
  });

  final MenuItem item;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final inCart = quantity > 0;
    return Material(
      color: const Color(0xFFe8edf3),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: inCart ? AppTheme.accent : const Color(0xFFcbd5e1),
              width: inCart ? 3 : 1,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Text(
                        item.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1e293b),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatMoneyCompact(item.sellPrice),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF2563eb),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (inCart)
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.remove, size: 14, color: AppTheme.background),
                          const SizedBox(width: 2),
                          Text(
                            '$quantity',
                            style: const TextStyle(
                              color: AppTheme.background,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderCartPanel extends StatelessWidget {
  const OrderCartPanel({
    super.key,
    required this.cart,
    required this.total,
    required this.busy,
    required this.isTab,
    required this.onIncrement,
    required this.onDecrement,
    required this.onAddToTab,
    required this.onSendToBartender,
    required this.onPrintBill,
    required this.onSendAndPrint,
    required this.onClear,
    this.onViewTab,
    this.showViewTab = false,
  });

  final Map<MenuItem, int> cart;
  final double total;
  final bool busy;
  final bool isTab;
  final ValueChanged<MenuItem> onIncrement;
  final ValueChanged<MenuItem> onDecrement;
  final VoidCallback? onAddToTab;
  final VoidCallback? onSendToBartender;
  final VoidCallback? onPrintBill;
  final VoidCallback? onSendAndPrint;
  final VoidCallback onClear;
  final VoidCallback? onViewTab;
  final bool showViewTab;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = currencyFormat;
    final hasItems = cart.isNotEmpty;

    return Container(
      width: 300,
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(l10n.cart, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const Spacer(),
                if (hasItems)
                  TextButton(
                    onPressed: busy ? null : onClear,
                    child: Text(l10n.clearCart, style: const TextStyle(color: AppTheme.danger)),
                  ),
              ],
            ),
          ),
          if (!hasItems)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.tapToAddHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: cart.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.surfaceLight),
                itemBuilder: (context, index) {
                  final entry = cart.entries.elementAt(index);
                  return _CartLine(
                    item: entry.key,
                    quantity: entry.value,
                    onIncrement: () => onIncrement(entry.key),
                    onDecrement: () => onDecrement(entry.key),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              border: Border(top: BorderSide(color: AppTheme.background, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${l10n.total}: ${currency.format(total)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (isTab) ...[
                  _BigActionButton(
                    label: l10n.addToTab,
                    icon: Icons.add_shopping_cart,
                    filled: true,
                    busy: busy,
                    enabled: hasItems,
                    onPressed: onAddToTab,
                  ),
                  const SizedBox(height: 8),
                  _BigActionButton(
                    label: l10n.sendToBartender,
                    icon: Icons.send,
                    busy: busy,
                    enabled: hasItems,
                    onPressed: onSendToBartender,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: busy || !hasItems ? null : onPrintBill,
                    icon: const Icon(Icons.print),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppTheme.textPrimary,
                    ),
                    label: Text(l10n.printBill),
                  ),
                  if (showViewTab && onViewTab != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: busy ? null : onViewTab,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(l10n.viewTab),
                    ),
                  ],
                ] else ...[
                  _BigActionButton(
                    label: l10n.sendAndPrintBill,
                    icon: Icons.receipt_long,
                    filled: true,
                    busy: busy,
                    enabled: hasItems,
                    onPressed: onSendAndPrint,
                  ),
                  const SizedBox(height: 8),
                  _BigActionButton(
                    label: l10n.sendToBartender,
                    icon: Icons.send,
                    busy: busy,
                    enabled: hasItems,
                    onPressed: onSendToBartender,
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

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.item,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final MenuItem item;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final currency = currencyFormat;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _QtyButton(icon: Icons.remove, onPressed: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$quantity',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
          _QtyButton(icon: Icons.add, onPressed: onIncrement),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  currency.format(item.sellPrice * quantity),
                  style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

class _BigActionButton extends StatelessWidget {
  const _BigActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
    this.busy = false,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;
  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Flexible(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
            ],
          );

    if (filled) {
      return FilledButton(
        onPressed: enabled && !busy ? onPressed : null,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: enabled && !busy ? onPressed : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: AppTheme.textPrimary,
      ),
      child: child,
    );
  }
}
