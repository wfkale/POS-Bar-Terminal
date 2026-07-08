import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'thermal_printer_service.dart';

@JS('PosBarPrinter')
external PosBarPrinterJs get _printer;

@JS()
@staticInterop
class PosBarPrinterJs {}

extension PosBarPrinterJsExt on PosBarPrinterJs {
  @JS('isSupported')
  external JSBoolean isSupported();

  @JS('requestSerial')
  external JSPromise requestSerial();

  @JS('requestBluetooth')
  external JSPromise requestBluetooth();

  @JS('printBase64')
  external JSPromise printBase64(JSString data, JSString transport);

  @JS('forget')
  external JSPromise forget();
}

/// Web Serial + Web Bluetooth via helpers injected in web/index.html (`PosBarPrinter`).
class ThermalPrinterPlatform {
  static bool get isSupported {
    if (!kIsWeb) return false;
    try {
      return _printer.isSupported().toDart;
    } catch (_) {
      return false;
    }
  }

  static Future<PairedPrinter> requestSerialPort() async {
    try {
      final result = await _printer.requestSerial().toDart;
      final map = _asStringMap(result);
      return PairedPrinter(
        id: map['id'] ?? 'serial',
        name: map['name'] ?? 'Serial thermal printer',
        transport: map['transport'] ?? 'web_serial',
      );
    } catch (e) {
      throw ThermalPrinterException(_errorMessage(e, 'Could not open serial printer.'));
    }
  }

  static Future<PairedPrinter> requestBluetoothDevice() async {
    try {
      final result = await _printer.requestBluetooth().toDart;
      final map = _asStringMap(result);
      return PairedPrinter(
        id: map['id'] ?? 'bt',
        name: map['name'] ?? 'Bluetooth thermal printer',
        transport: map['transport'] ?? 'web_bluetooth',
      );
    } catch (e) {
      throw ThermalPrinterException(_errorMessage(e, 'Could not pair Bluetooth printer.'));
    }
  }

  static Future<void> printBytes(Uint8List bytes, PairedPrinter paired) async {
    try {
      // Base64 avoids fragile TypedArray dart2js interop on Flutter 3.19 / Dart 3.3.
      await _printer.printBase64(base64Encode(bytes).toJS, paired.transport.toJS).toDart;
    } catch (e) {
      throw ThermalPrinterException(_errorMessage(e, 'Print failed.'));
    }
  }

  static Future<void> forgetHardware() async {
    try {
      await _printer.forget().toDart;
    } catch (_) {}
  }

  static Map<String, String> _asStringMap(JSAny? result) {
    if (result == null) return {};
    final dart = result.dartify();
    if (dart is Map) {
      return dart.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    return {};
  }

  static String _errorMessage(Object e, String fallback) {
    final msg = e.toString();
    if (msg.contains('NotFoundError') || msg.contains('cancel')) {
      return 'Printer selection cancelled.';
    }
    // Chrome/JS often wraps as "Error: ..."
    final cleaned = msg
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^JSNull:\s*'), '')
        .replaceFirst(RegExp(r'^Error:\s*'), '');
    return cleaned.isNotEmpty ? cleaned : fallback;
  }
}
