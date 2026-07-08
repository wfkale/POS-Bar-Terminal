import 'thermal_printer_service.dart';

/// Non-web platforms: thermal printing is only supported in the Chrome/Edge PWAs.
class ThermalPrinterPlatform {
  static bool get isSupported => false;

  static Future<PairedPrinter> requestSerialPort() async {
    throw ThermalPrinterException('Thermal printing is only available in the web PWA (Chrome/Edge).');
  }

  static Future<PairedPrinter> requestBluetoothDevice() async {
    throw ThermalPrinterException('Thermal printing is only available in the web PWA (Chrome/Edge).');
  }

  static Future<void> printBytes(dynamic bytes, PairedPrinter paired) async {
    throw ThermalPrinterException('Thermal printing is only available in the web PWA (Chrome/Edge).');
  }
}
