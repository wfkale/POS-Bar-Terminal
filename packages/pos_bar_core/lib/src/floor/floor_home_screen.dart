import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

import 'metrics_screen.dart';
import 'new_order_screen.dart';
import 'open_tabs_screen.dart';

/// Floor terminal home — shared by bar attendants and cashiers.
class FloorHomeScreen extends StatelessWidget {
  const FloorHomeScreen({
    super.key,
    required this.api,
    required this.session,
    this.onLogout,
    this.extraAppBarActions = const [],
  });

  final ApiClient api;
  final StaffSession session;
  final VoidCallback? onLogout;
  final List<Widget> extraAppBarActions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trailing = <Widget>[
      ...extraAppBarActions,
      if (onLogout != null) IconButton(onPressed: onLogout, icon: const Icon(Icons.logout)),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(l10n.welcome(session.staff.name)),
        actions: [FloorAppBarActions(trailing: trailing)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _ActionTile(
              icon: Icons.receipt_long,
              label: l10n.cashOrder,
              subtitle: l10n.payAtCounter,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NewOrderScreen(api: api, type: 'cash')),
              ),
            ),
            _ActionTile(
              icon: Icons.tab,
              label: l10n.tabOrder,
              subtitle: l10n.addToOpenTab,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NewOrderScreen(api: api, type: 'tab')),
              ),
            ),
            _ActionTile(
              icon: Icons.person_add_alt_1,
              label: l10n.newTab,
              subtitle: l10n.openCustomerTab,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OpenTabsScreen(api: api, openCreate: true)),
              ),
            ),
            _ActionTile(
              icon: Icons.list_alt,
              label: l10n.openTabs,
              subtitle: l10n.viewRunningTabs,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OpenTabsScreen(api: api)),
              ),
            ),
            _ActionTile(
              icon: Icons.insights,
              label: l10n.myPerformance,
              subtitle: l10n.todaysMetrics,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MetricsScreen(api: api)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: AppTheme.accent),
              const Spacer(),
              Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
