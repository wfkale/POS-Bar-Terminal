import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

import 'queue_screen.dart';

/// Cashier shift shell: pay queue + full floor terminal (tabs, orders).
class CashierShellScreen extends StatefulWidget {
  const CashierShellScreen({
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
  State<CashierShellScreen> createState() => _CashierShellScreenState();
}

class _CashierShellScreenState extends State<CashierShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          QueueScreen(
            api: widget.api,
            session: widget.session,
            shift: widget.shift,
            onEndShift: widget.onEndShift,
            onLogout: widget.onLogout,
          ),
          FloorHomeScreen(
            api: widget.api,
            session: widget.session,
            onLogout: () => widget.onLogout(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.point_of_sale), label: l10n.payQueue),
          NavigationDestination(icon: const Icon(Icons.local_bar), label: l10n.floorOps),
        ],
      ),
    );
  }
}
