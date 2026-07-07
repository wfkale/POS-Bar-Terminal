import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

class OpenTabsScreen extends StatefulWidget {
  const OpenTabsScreen({super.key, required this.api, this.openCreate = false});

  final ApiClient api;
  final bool openCreate;

  @override
  State<OpenTabsScreen> createState() => _OpenTabsScreenState();
}

class _OpenTabsScreenState extends State<OpenTabsScreen> {
  late Future<List<BarTab>> _tabsFuture;
  final _nameController = TextEditingController();
  final _tableController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
    if (widget.openCreate) WidgetsBinding.instance.addPostFrameCallback((_) => _showCreateDialog());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tableController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _tabsFuture = widget.api.fetchOpenTabs());

  Future<void> _showCreateDialog() async {
    final l10n = context.l10n;
    _nameController.clear();
    _tableController.clear();
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(l10n.openNewTab),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.customerName),
                enabled: !submitting,
                textInputAction: TextInputAction.next,
              ),
              TextField(
                controller: _tableController,
                decoration: InputDecoration(labelText: l10n.tableArea),
                enabled: !submitting,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;

                      setDialogState(() => submitting = true);
                      try {
                        await widget.api.createTab(
                          customerName: name,
                          tableLabel: _tableController.text.trim().isEmpty ? null : _tableController.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) _refresh();
                      } on ApiException catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        }
                      } finally {
                        if (ctx.mounted) setDialogState(() => submitting = false);
                      }
                    },
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.openTab),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestDeletion(BarTab tab) async {
    final l10n = context.l10n;
    final reasonController = TextEditingController();
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(l10n.requestTabDeletion),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${tab.customerName}${tab.tableLabel != null ? ' · ${tab.tableLabel}' : ''}'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(labelText: l10n.deletionReason),
                maxLines: 3,
                enabled: !submitting,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: submitting ? null : () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final reason = reasonController.text.trim();
                      if (reason.isEmpty) return;
                      setDialogState(() => submitting = true);
                      try {
                        await widget.api.requestTabDeletion(tab.id, reason: reason);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deletionRequested)));
                          _refresh();
                        }
                      } on ApiException catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        }
                      } finally {
                        if (ctx.mounted) setDialogState(() => submitting = false);
                      }
                    },
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.requestTabDeletion),
            ),
          ],
        ),
      ),
    );
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.openTabs),
        actions: [
          const FloorAppBarActions(),
          IconButton(onPressed: _showCreateDialog, icon: const Icon(Icons.add)),
        ],
      ),
      body: FutureBuilder<List<BarTab>>(
        future: _tabsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) {
            return Center(child: Text(l10n.noOpenTabs));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final tab = snapshot.data![i];
              final pending = tab.pendingDeletionRequest?.isPending ?? false;
              return ListTile(
                tileColor: AppTheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Row(
                  children: [
                    Expanded(child: Text(tab.customerName)),
                    if (pending)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(l10n.deletionPending, style: const TextStyle(fontSize: 11, color: AppTheme.accent)),
                      ),
                  ],
                ),
                subtitle: Text(tab.tableLabel ?? l10n.noTableLabel),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(formatMoneyCompact(tab.runningTotal)),
                    if (!pending) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                        tooltip: l10n.requestTabDeletion,
                        onPressed: () => _requestDeletion(tab),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
