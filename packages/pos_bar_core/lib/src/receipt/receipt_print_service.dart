import '../models/order.dart';
import '../models/venue_config.dart';
import 'bar_receipt.dart';
import 'receipt_builder.dart';
import 'thermal_printer_service.dart';

/// High-level bill/receipt print orchestration for floor + till.
class ReceiptPrintService {
  static Future<void> printProformaBill({
    required BarOrder order,
    required VenueConfig venue,
    required String billNumber,
    String? tableLabel,
  }) async {
    final receipt = ReceiptBuilder.proforma(
      order: order,
      venue: venue,
      billNumber: billNumber,
      tableLabel: tableLabel,
    );
    await ThermalPrinterService.printReceipt(receipt);
  }

  static Future<void> printFinalReceipt({
    required BarOrder order,
    required VenueConfig venue,
    required String paymentMethod,
    String? billNumber,
    String? tillLabel,
  }) async {
    final receipt = ReceiptBuilder.finalReceipt(
      order: order,
      venue: venue,
      paymentMethod: paymentMethod,
      billNumber: billNumber,
      tillLabel: tillLabel,
    );
    await ThermalPrinterService.printReceipt(receipt);
  }
}
