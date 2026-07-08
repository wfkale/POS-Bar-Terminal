import 'package:intl/intl.dart';

import 'bar_receipt.dart';

/// POS Butcher-style receipt layout for 80mm paper (≈72mm print width).
class ReceiptLayoutService {
  /// Characters usable on 80mm thermal with condensed monospace font.
  static const int thermalWidth = 42;

  static String formatMoney(double number) {
    final parts = number.toStringAsFixed(2).split('.');
    final formattedInteger = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );
    return '$formattedInteger.${parts[1]}';
  }

  static List<String> buildLines(BarReceipt receipt) {
    final lines = <String>[];
    final date = DateFormat('dd-MM-yyyy').format(receipt.printedAt.toLocal());
    final time = DateFormat('HH:mm').format(receipt.printedAt.toLocal());

    lines.add(receipt.isProforma ? '*** CUSTOMER BILL ***' : '*** SALE RECEIPT ***');
    lines.add(_center(receipt.venueName.toUpperCase()));
    if (_has(receipt.location)) lines.add(_center(receipt.location!.toUpperCase()));
    if (_has(receipt.phone)) lines.add('TEL: ${receipt.phone!.trim()}');
    if (_has(receipt.tin)) lines.add('TIN: ${receipt.tin!.trim()}');
    if (_has(receipt.vrn)) lines.add('VRN: ${receipt.vrn!.trim()}');
    lines.add(_rule());

    if (receipt.isProforma) {
      lines.add('BILL NO: ${receipt.documentNumber}');
    } else {
      lines.add('RECEIPT NO: ${receipt.documentNumber}');
    }
    if (_has(receipt.orderNumber)) lines.add('ORDER: ${receipt.orderNumber}');
    lines.add('DATE: $date  TIME: $time');
    if (_has(receipt.staffName)) lines.add('STAFF: ${receipt.staffName}');
    if (_has(receipt.tillLabel)) lines.add('TILL: ${receipt.tillLabel}');
    if (_has(receipt.customerName)) lines.add('CUSTOMER: ${receipt.customerName}');
    if (_has(receipt.tableLabel)) lines.add('TABLE: ${receipt.tableLabel}');
    if (!receipt.isProforma && _has(receipt.paymentMethod)) {
      lines.add('PAYMENT: ${receipt.paymentMethod!.toUpperCase()}');
    }
    lines.add('');
    lines.addAll(_itemSection(receipt));
    lines.add(_moneyLine('TOTAL EXCL. TAX', receipt.subtotal));
    lines.add(_moneyLine('VAT ${receipt.taxRate.toStringAsFixed(0)}%', receipt.taxAmount));
    lines.add(_moneyLine('TOTAL INCL. TAX', receipt.total, bold: true));
    lines.add(_rule());

    if (receipt.isProforma) {
      lines.add(_center('PAY AT CASHIER'));
      lines.add(_center('NOT A FISCAL RECEIPT'));
    } else {
      lines.add(_center('THANK YOU'));
    }
    if (_has(receipt.notes)) {
      lines.add('');
      for (final noteLine in _wrap(receipt.notes!.trim(), thermalWidth)) {
        lines.add(_center(noteLine));
      }
    }
    lines.add(receipt.isProforma ? '*** END OF BILL ***' : '*** END OF RECEIPT ***');

    return lines;
  }

  static String buildText(BarReceipt receipt) => '${buildLines(receipt).join('\n')}\n';

  static List<String> _itemSection(BarReceipt receipt) {
    final lines = <String>[
      _rule(),
      _columnsLine('DESCRIPTION', 'QTY', 'PRICE', 'AMOUNT'),
      _rule(),
    ];

    for (final item in receipt.items) {
      final name = item.name.trim().isEmpty ? 'ITEM' : item.name.trim().toUpperCase();
      for (final nameLine in _wrap(name, thermalWidth)) {
        lines.add(nameLine);
      }
      lines.add(_itemDetailLine(item));
    }

    lines.add(_rule());
    return lines;
  }

  static String _itemDetailLine(BarReceiptItem item) {
    const qtyW = 8;
    const priceW = 12;
    const amtW = 13;
    final qtyLabel = item.quantity == item.quantity.roundToDouble()
        ? '${item.quantity.toInt()} pcs'
        : item.quantity.toStringAsFixed(2);
    final qty = qtyLabel.padLeft(qtyW);
    final price = formatMoney(item.unitPrice).padLeft(priceW);
    final amt = formatMoney(item.lineTotal).padLeft(amtW);
    return '  $qty $price $amt';
  }

  static String _columnsLine(String desc, String qty, String price, String amount) {
    return '${desc.padRight(14)}${qty.padLeft(6)} ${price.padLeft(10)} ${amount.padLeft(11)}';
  }

  static String _moneyLine(String label, double amount, {bool bold = false}) {
    final value = formatMoney(amount);
    final pad = (thermalWidth - label.length - value.length).clamp(1, 80);
    final line = '$label${' ' * pad}$value';
    return bold ? line.toUpperCase() : line;
  }

  static String _rule() => '-' * thermalWidth;

  static String _center(String text) {
    if (text.length >= thermalWidth) return text.substring(0, thermalWidth);
    final pad = (thermalWidth - text.length) ~/ 2;
    return '${' ' * pad}$text';
  }

  static bool _has(String? value) => value != null && value.trim().isNotEmpty;

  static List<String> _wrap(String text, int width) {
    if (text.length <= width) return [text];
    final words = text.split(RegExp(r'\s+'));
    final lines = <String>[];
    var current = '';
    for (final word in words) {
      if (current.isEmpty) {
        current = word;
      } else if ('$current $word'.length <= width) {
        current = '$current $word';
      } else {
        lines.add(current);
        current = word.length > width ? word.substring(0, width) : word;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines.isEmpty ? [text.substring(0, width)] : lines;
  }
}
