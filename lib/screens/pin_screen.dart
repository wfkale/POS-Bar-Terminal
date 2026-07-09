import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({
    super.key,
    required this.staff,
    required this.api,
    required this.onSuccess,
    required this.onBack,
  });

  final StaffCard staff;
  final ApiClient api;
  final ValueChanged<StaffSession> onSuccess;
  final VoidCallback onBack;

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_pin.length < 4) return;
    final l10n = context.l10n;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await widget.api.pinLogin(staffId: widget.staff.id, pin: _pin);
      widget.onSuccess(session);
    } on ApiException catch (e) {
      setState(() {
        _error = e.pinLoginMessage(l10n);
        _pin = '';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _tapDigit(String digit) {
    if (_loading || _pin.length >= 4) return;
    setState(() => _pin += digit);
    if (_pin.length == 4) _submit();
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        actions: const [FloorAppBarActions()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: PinEntryPanel(
              staffName: widget.staff.name,
              avatarColor: widget.staff.avatarColor,
              pinLength: 4,
              filledCount: _pin.length,
              onDigit: _tapDigit,
              onBackspace: _backspace,
              error: _error,
              loading: _loading,
              subtitle: l10n.enterPin,
            ),
          ),
        ),
      ),
    );
  }
}
