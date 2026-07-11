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

  static const _padding = 16.0;
  static const _spacing = 12.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trailing = <Widget>[
      IconButton(
        tooltip: l10n.printerSettings,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
        ),
        icon: const Icon(Icons.print),
      ),
      ...extraAppBarActions,
      if (onLogout != null) IconButton(onPressed: onLogout, icon: const Icon(Icons.logout)),
    ];

    final tiles = [
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
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(l10n.welcome(session.staff.name)),
        actions: [FloorAppBarActions(trailing: trailing)],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = PosBreakpoints.homeColumns(constraints.maxWidth);
          final compact = PosBreakpoints.isCompact(constraints.maxWidth);
          final gridWidth = constraints.maxWidth - _padding * 2;
          final gridHeight = constraints.maxHeight - _padding * 2;
          final rows = (tiles.length / columns).ceil();

          if (compact || gridHeight < 280) {
            return Padding(
              padding: const EdgeInsets.all(_padding),
              child: GridView.count(
                crossAxisCount: columns,
                mainAxisSpacing: _spacing,
                crossAxisSpacing: _spacing,
                childAspectRatio: 1.15,
                children: tiles,
              ),
            );
          }

          final tileWidth = (gridWidth - _spacing * (columns - 1)) / columns;
          final tileHeight = (gridHeight - _spacing * (rows - 1)) / rows;
          final aspectRatio = tileWidth / tileHeight;

          return Padding(
            padding: const EdgeInsets.all(_padding),
            child: SizedBox(
              width: gridWidth,
              height: gridHeight,
              child: GridView.count(
                crossAxisCount: columns,
                mainAxisSpacing: _spacing,
                crossAxisSpacing: _spacing,
                childAspectRatio: aspectRatio,
                physics: const NeverScrollableScrollPhysics(),
                children: tiles,
              ),
            ),
          );
        },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final pad = (h * 0.12).clamp(10.0, 20.0);
        final iconSize = (h * 0.28).clamp(24.0, 40.0);
        final titleSize = (h * 0.13).clamp(14.0, 20.0);
        final subtitleSize = (h * 0.095).clamp(11.0, 14.0);

        return Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: iconSize, color: AppTheme.accent),
                  const Spacer(),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: pad * 0.3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: subtitleSize),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
