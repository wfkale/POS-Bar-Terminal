import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'bar_receipt.dart';
import 'esc_pos_builder.dart';
import 'thermal_printer_web.dart' if (dart.library.io) 'thermal_printer_stub.dart' as platform;

class ThermalPrinterException implements Exception {
  ThermalPrinterException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PairedPrinter {
  const PairedPrinter({
    required this.id,
    required this.name,
    required this.transport,
  });

  final String id;
  final String name;

  /// `web_serial` | `web_bluetooth` | `none`
  final String transport;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'transport': transport,
      };

  factory PairedPrinter.fromJson(Map<String, dynamic> json) => PairedPrinter(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Printer',
        transport: json['transport'] as String? ?? 'web_serial',
      );
}

/// Thermal print facade for Flutter web PWAs (Web Serial + Web Bluetooth).
class ThermalPrinterService {
  static const _prefsKey = 'pos_bar_paired_printer';

  static PairedPrinter? _cached;

  static Future<PairedPrinter?> getPairedPrinter() async {
    if (_cached != null) return _cached;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      _cached = PairedPrinter.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return _cached;
    } catch (_) {
      return null;
    }
  }

  static Future<void> savePairedPrinter(PairedPrinter printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(printer.toJson()));
    _cached = printer;
  }

  static Future<void> clearPairedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    _cached = null;
    await platform.ThermalPrinterPlatform.forgetHardware();
  }

  static Future<bool> get isSupported async => platform.ThermalPrinterPlatform.isSupported;

  static Future<PairedPrinter> requestSerialPrinter() async {
    final printer = await platform.ThermalPrinterPlatform.requestSerialPort();
    await savePairedPrinter(printer);
    return printer;
  }

  static Future<PairedPrinter> requestBluetoothPrinter() async {
    final printer = await platform.ThermalPrinterPlatform.requestBluetoothDevice();
    await savePairedPrinter(printer);
    return printer;
  }

  static Future<void> printReceipt(BarReceipt receipt) async {
    await printBytes(EscPosBuilder.build(receipt));
  }

  static Future<void> printBytes(Uint8List bytes) async {
    final paired = await getPairedPrinter();
    if (paired == null) {
      throw ThermalPrinterException(
        'No printer paired. Open Printer settings and connect your 80mm (72mm) thermal printer.',
      );
    }
    await platform.ThermalPrinterPlatform.printBytes(bytes, paired);
  }

  static Future<void> testPrint({String venueName = 'POS Bar'}) async {
    final receipt = BarReceipt(
      kind: 'final',
      venueName: venueName,
      documentNumber: 'TEST-PRINT',
      currency: 'TZS',
      items: const [
        BarReceiptItem(name: 'Test item', quantity: 1, unitPrice: 1000, lineTotal: 1000),
      ],
      subtotal: 847.46,
      taxAmount: 152.54,
      taxRate: 18,
      total: 1000,
      printedAt: DateTime.now(),
      notes: 'Printer connection OK',
    );
    await printReceipt(receipt);
  }
}
