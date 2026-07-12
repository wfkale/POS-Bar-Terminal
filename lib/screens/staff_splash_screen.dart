import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

class StaffSplashScreen extends StatefulWidget {
  const StaffSplashScreen({
    super.key,
    required this.api,
    required this.onStaffSelected,
  });

  final ApiClient api;
  final ValueChanged<StaffCard> onStaffSelected;

  @override
  State<StaffSplashScreen> createState() => _StaffSplashScreenState();
}

class _StaffSplashScreenState extends State<StaffSplashScreen> {
  late Future<List<StaffCard>> _staffFuture;

  @override
  void initState() {
    super.initState();
    _staffFuture = widget.api.fetchOnDutyStaff();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 500 ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [LanguageToggle(compact: true)],
              ),
              const SizedBox(height: 8),
              const VenueBranding(height: 72, maxWidth: 200),
              const SizedBox(height: 8),
              Text(
                l10n.tapNameToSignIn,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: FutureBuilder<List<StaffCard>>(
                  future: _staffFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.couldNotLoadStaff('${snapshot.error}'), textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => setState(() => _staffFuture = widget.api.fetchOnDutyStaff()),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      );
                    }
                    final floorStaff = snapshot.data!
                        .where((s) => s.role == 'bar_attendant' || s.role == 'cashier')
                        .toList();

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = PosBreakpoints.signInColumns(constraints.maxWidth);
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1,
                          ),
                          itemCount: floorStaff.length,
                          itemBuilder: (context, index) {
                            final staff = floorStaff[index];
                            final roleLabel = staff.role == 'cashier' ? l10n.bartenderRole : l10n.barAttendant;
                            return _NameCard(
                              staff: staff,
                              roleLabel: roleLabel,
                              onTap: () => widget.onStaffSelected(staff),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const FkCredit(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  const _NameCard({
    required this.staff,
    required this.roleLabel,
    required this.onTap,
  });

  final StaffCard staff;
  final String roleLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.parseHex(staff.avatarColor);
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color,
                child: Text(
                  staff.name.characters.first.toUpperCase(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                staff.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                roleLabel,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary.withOpacity(0.9)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
