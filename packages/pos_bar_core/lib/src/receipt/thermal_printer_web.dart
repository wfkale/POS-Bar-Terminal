import 'dart:async';
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

  @JS('printBytes')
  external JSPromise printBytes(JSUint8Array data, JSString transport);
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
      await _printer.printBytes(bytes.toJS, paired.transport.toJS).toDart;
    } catch (e) {
      throw ThermalPrinterException(_errorMessage(e, 'Print failed.'));
    }
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
    return msg.isNotEmpty ? msg.replaceFirst('Exception: ', '') : fallback;
  }
}
