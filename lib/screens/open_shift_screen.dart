import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

class OpenShiftScreen extends StatefulWidget {
  const OpenShiftScreen({
    super.key,
    required this.api,
    required this.till,
    required this.cashierName,
    required this.onShiftOpened,
    required this.onBack,
  });

  final ApiClient api;
  final TillStatus till;
  final String cashierName;
  final ValueChanged<StaffShiftInfo> onShiftOpened;
  final VoidCallback onBack;

  @override
  State<OpenShiftScreen> createState() => _OpenShiftScreenState();
}

class _OpenShiftScreenState extends State<OpenShiftScreen> {
  String _amount = '';
  bool _loading = false;
  String? _error;

  double? get _parsedAmount {
    if (_amount.isEmpty) return null;
    return double.tryParse(_amount);
  }

  Future<void> _openShift() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final shift = await widget.api.startShift(
        tillId: widget.till.id,
        openingFloat: _parsedAmount,
      );
      widget.onShiftOpened(shift);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _tapKey(String key) {
    if (_loading) return;
    setState(() {
      if (key == '.') {
        if (!_amount.contains('.')) _amount += _amount.isEmpty ? '0.' : '.';
      } else {
        if (_amount == '0') {
          _amount = key;
        } else {
          _amount += key;
        }
      }
    });
  }

  void _backspace() {
    if (_amount.isEmpty) return;
    setState(() => _amount = _amount.substring(0, _amount.length - 1));
  }

  void _clear() => setState(() => _amount = '');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final display = _amount.isEmpty ? '0' : _amount;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: Text(l10n.openShiftTitle(widget.till.name)),
        actions: const [FloorAppBarActions()],
      ),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.hi(widget.cashierName), style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(l10n.openingFloatIntro, style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 32),
                  Text(l10n.openingFloat, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                    ),
                    child: Text(
                      '$currencyCode $display',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppTheme.danger)),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading ? null : _openShift,
                          child: Text(l10n.skipNoFloat),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _loading ? null : _openShift,
                          child: _loading
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(l10n.openShiftBtn),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 320,
            color: AppTheme.surface,
            padding: const EdgeInsets.all(16),
            child: NumericKeypad(
              showDecimal: true,
              onDigit: _tapKey,
              onBackspace: _backspace,
              onClear: _clear,
            ),
          ),
        ],
      ),
    );
  }
}
