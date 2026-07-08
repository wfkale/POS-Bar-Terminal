import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

/// Butcher-style checkout: pick payment, then complete WITH or WITHOUT receipt.
Future<void> showPayCheckoutSheet({
  required BuildContext context,
  required BarOrder order,
  required Future<void> Function(String method, {required bool withReceipt}) onComplete,
}) async {
  final l10n = context.l10n;
  final currency = currencyFormat;
  final methods = VenueScope.of(context).venue.paymentMethods;
  if (methods.isEmpty) return;

  String selected = methods.first.code;
  final locale = Localizations.localeOf(context).languageCode;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(ctx).padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  order.orderNumber,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(order.total),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.accent),
                ),
                const SizedBox(height: 16),
                Text(l10n.choosePayment, style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in methods)
                      ChoiceChip(
                        label: Text(m.labelForLocale(locale)),
                        selected: selected == m.code,
                        onSelected: (_) => setModalState(() => selected = m.code),
                        selectedColor: AppTheme.accent,
                        labelStyle: TextStyle(
                          color: selected == m.code ? AppTheme.background : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onComplete(selected, withReceipt: true);
                  },
                  child: Text(l10n.completeWithReceipt),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onComplete(selected, withReceipt: false);
                  },
                  child: Text(l10n.completeNoReceipt),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
