import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/venue_config.dart';
import 'bar_receipt.dart';
import 'receipt_builder.dart';
import 'receipt_preview_sheet.dart';
import 'thermal_printer_service.dart';

/// Result of a customer bill print attempt (never records payment).
class BillPrintResult {
  const BillPrintResult._(this.status, {this.message});

  final BillPrintStatus status;
  final String? message;

  bool get ok => status == BillPrintStatus.printed;

  factory BillPrintResult.printed() => const BillPrintResult._(BillPrintStatus.printed);

  factory BillPrintResult.noPrinter(String message) =>
      BillPrintResult._(BillPrintStatus.noPrinter, message: message);

  factory BillPrintResult.failed(String message) =>
      BillPrintResult._(BillPrintStatus.failed, message: message);
}

enum BillPrintStatus { printed, noPrinter, failed }

/// Proforma customer bills only — separate from checkout / payment receipts.
class BillPrintService {
  static BarReceipt buildBill({
    required BarOrder order,
    required VenueConfig venue,
    required String billNumber,
    String? tableLabel,
  }) {
    return ReceiptBuilder.proforma(
      order: order,
      venue: venue,
      billNumber: billNumber,
      tableLabel: tableLabel,
    );
  }

  /// Print a customer bill to the paired thermal printer. Does not pay the order.
  static Future<BillPrintResult> printCustomerBill(BarReceipt receipt) async {
    final paired = await ThermalPrinterService.getPairedPrinter();
    if (paired == null) {
      return BillPrintResult.noPrinter(
        'No printer paired. Open Printer settings and connect your 80mm (72mm) thermal printer.',
      );
    }
    try {
      await ThermalPrinterService.printReceipt(receipt);
      return BillPrintResult.printed();
    } on ThermalPrinterException catch (e) {
      return BillPrintResult.failed(e.message);
    } catch (e) {
      return BillPrintResult.failed(e.toString());
    }
  }

  static Future<void> previewBill({
    required BuildContext context,
    required BarReceipt receipt,
    String? closeLabel,
  }) {
    return showReceiptPreview(
      context: context,
      receipt: receipt,
      title: 'Bill preview',
      closeLabel: closeLabel,
    );
  }
}
