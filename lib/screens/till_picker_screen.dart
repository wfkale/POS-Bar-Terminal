import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

/// Bartender picks a till after PIN login (staff already identified).
class TillPickerScreen extends StatefulWidget {
  const TillPickerScreen({
    super.key,
    required this.api,
    required this.session,
    required this.onTillSelected,
    required this.onBack,
  });

  final ApiClient api;
  final StaffSession session;
  final ValueChanged<TillStatus> onTillSelected;
  final VoidCallback onBack;

  @override
  State<TillPickerScreen> createState() => _TillPickerScreenState();
}

class _TillPickerScreenState extends State<TillPickerScreen> {
  late Future<TillRoster> _rosterFuture;

  @override
  void initState() {
    super.initState();
    _rosterFuture = widget.api.fetchCashierRoster();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) VenueScope.of(context).refresh();
    });
  }

  void _refresh() {
    setState(() => _rosterFuture = widget.api.fetchCashierRoster());
    VenueScope.of(context).refresh();
  }

  void _pickTill(TillStatus till) {
    final shift = till.activeShift;
    final staffId = widget.session.staff.id;

    if (shift != null && shift.staffId != staffId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tillInUse(shift.staffName ?? context.l10n.bartenderRole))),
      );
      return;
    }

    widget.onTillSelected(till);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: Text(l10n.selectYourTill),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          const FloorAppBarActions(),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.hi(widget.session.staff.name),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.tapTillToSignIn,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: FutureBuilder<TillRoster>(
                  future: _rosterFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.couldNotLoadRoster('${snapshot.error}'), textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(onPressed: _refresh, child: Text(l10n.retry)),
                          ],
                        ),
                      );
                    }

                    final tills = snapshot.data!.tills;
                    if (tills.isEmpty) {
                      return Center(child: Text(l10n.noTillsConfigured));
                    }

                    return ListView.separated(
                      itemCount: tills.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final till = tills[index];
                        return _TillCard(
                          till: till,
                          l10n: l10n,
                          staffId: widget.session.staff.id,
                          onTap: () => _pickTill(till),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TillCard extends StatelessWidget {
  const _TillCard({
    required this.till,
    required this.l10n,
    required this.staffId,
    required this.onTap,
  });

  final TillStatus till;
  final AppStrings l10n;
  final int staffId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shift = till.activeShift;
    final isMine = shift?.staffId == staffId;
    final isBusy = shift != null && !isMine;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isMine
                    ? AppTheme.success.withOpacity(0.15)
                    : isBusy
                        ? AppTheme.danger.withOpacity(0.12)
                        : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.point_of_sale,
                color: isMine ? AppTheme.success : isBusy ? AppTheme.danger : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(till.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  Text(till.code, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  if (isMine)
                    Text(l10n.resumeShift, style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w500))
                  else if (isBusy)
                    Text(l10n.tillInUse(shift!.staffName ?? l10n.bartenderRole), style: const TextStyle(color: AppTheme.danger))
                  else
                    Text(l10n.available, style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
            FilledButton(
              onPressed: isBusy ? null : onTap,
              child: Text(isMine ? l10n.resume : l10n.signIn),
            ),
          ],
        ),
      ),
    );
  }
}
