import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

/// Pair Bluetooth / USB-serial 80mm thermal printers for Chrome PWAs.
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  PairedPrinter? _printer;
  bool _supported = false;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final supported = await ThermalPrinterService.isSupported;
    final paired = await ThermalPrinterService.getPairedPrinter();
    if (!mounted) return;
    setState(() {
      _supported = supported;
      _printer = paired;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await action();
      await _load();
    } on ThermalPrinterException catch (e) {
      if (mounted) setState(() => _status = e.message);
    } catch (e) {
      if (mounted) setState(() => _status = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final venueName = VenueScope.of(context).venue.name;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.printerSettings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.printerSettingsIntro,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Icon(
                _printer != null ? Icons.print : Icons.print_disabled,
                color: _printer != null ? AppTheme.success : AppTheme.textSecondary,
              ),
              title: Text(_printer?.name ?? l10n.noPrinterPaired),
              subtitle: Text(
                _printer == null
                    ? l10n.pairPrinterHint
                    : '${_printer!.transport} · ${_printer!.id}',
              ),
              trailing: _printer == null
                  ? null
                  : IconButton(
                      tooltip: l10n.forgetPrinter,
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                                await ThermalPrinterService.clearPairedPrinter();
                                setState(() => _status = l10n.printerForgotten);
                              }),
                      icon: const Icon(Icons.link_off),
                    ),
            ),
          ),
          if (!_supported) ...[
            const SizedBox(height: 12),
            Text(
              l10n.printerNotSupported,
              style: const TextStyle(color: AppTheme.danger),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: (!_supported || _busy)
                ? null
                : () => _run(() async {
                      final p = await ThermalPrinterService.requestBluetoothPrinter();
                      setState(() => _status = l10n.printerPaired(p.name));
                    }),
            icon: const Icon(Icons.bluetooth),
            label: Text(l10n.connectBluetooth),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: (!_supported || _busy)
                ? null
                : () => _run(() async {
                      final p = await ThermalPrinterService.requestSerialPrinter();
                      setState(() => _status = l10n.printerPaired(p.name));
                    }),
            icon: const Icon(Icons.usb),
            label: Text(l10n.connectUsbSerial),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: (_printer == null || _busy)
                ? null
                : () => _run(() async {
                      await ThermalPrinterService.testPrint(venueName: venueName);
                      setState(() => _status = l10n.testPrintSent);
                    }),
            icon: const Icon(Icons.receipt_long),
            label: Text(l10n.testPrint),
          ),
          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          ],
          if (_status != null) ...[
            const SizedBox(height: 20),
            Text(_status!, style: const TextStyle(height: 1.4)),
          ],
        ],
      ),
    );
  }
}
