import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/venue_config.dart';
import 'bar_receipt.dart';
import 'receipt_builder.dart';
import 'receipt_preview_sheet.dart';
import 'thermal_printer_service.dart';

/// High-level bill/receipt print orchestration for floor + till.
class ReceiptPrintService {
  static Future<void> printProformaBill({
    required BarOrder order,
    required VenueConfig venue,
    required String billNumber,
    String? tableLabel,
    BuildContext? previewContext,
  }) async {
    final receipt = ReceiptBuilder.proforma(
      order: order,
      venue: venue,
      billNumber: billNumber,
      tableLabel: tableLabel,
    );
    await _printOrPreview(receipt, previewContext, title: 'Bill preview');
  }

  static Future<void> printFinalReceipt({
    required BarOrder order,
    required VenueConfig venue,
    required String paymentMethod,
    String? billNumber,
    String? tillLabel,
    BuildContext? previewContext,
  }) async {
    final receipt = ReceiptBuilder.finalReceipt(
      order: order,
      venue: venue,
      paymentMethod: paymentMethod,
      billNumber: billNumber,
      tillLabel: tillLabel,
    );
    await _printOrPreview(receipt, previewContext, title: 'Receipt preview');
  }

  static Future<void> _printOrPreview(
    BarReceipt receipt,
    BuildContext? previewContext, {
    required String title,
  }) async {
    final paired = await ThermalPrinterService.getPairedPrinter();
    if (paired == null) {
      if (previewContext != null && previewContext.mounted) {
        await showReceiptPreview(
          context: previewContext,
          receipt: receipt,
          title: title,
        );
      }
      throw ThermalPrinterException(
        'No printer paired. Open Printer settings and connect your 80mm (72mm) thermal printer.',
      );
    }

    try {
      await ThermalPrinterService.printReceipt(receipt);
    } catch (e) {
      // Always show what we tried to print so operators can diagnose silent hardware issues.
      if (previewContext != null && previewContext.mounted) {
        await showReceiptPreview(
          context: previewContext,
          receipt: receipt,
          title: '$title (print failed)',
        );
      }
      rethrow;
    }
  }
}
