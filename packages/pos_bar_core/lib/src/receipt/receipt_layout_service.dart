import 'package:intl/intl.dart';

import 'bar_receipt.dart';
import 'receipt_line.dart';

/// Receipt layout for 80mm paper (≈72mm print width).
/// Proforma bills use the simple bar bill format; paid receipts use the Butcher-style layout.
class ReceiptLayoutService {
  /// Characters usable on 80mm thermal with condensed monospace font.
  static const int thermalWidth = 42;

  static const _nil = 'NIL';

  static String formatMoney(double number) {
    final parts = number.toStringAsFixed(2).split('.');
    final formattedInteger = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );
    return '$formattedInteger.${parts[1]}';
  }

  static List<ReceiptLine> buildStyledLines(BarReceipt receipt) {
    if (receipt.isProforma) {
      return _buildBillLines(receipt);
    }
    return _buildReceiptLines(receipt);
  }

  /// Simple customer bill (floor + till reprint) — unchanged bar format.
  static List<ReceiptLine> _buildBillLines(BarReceipt receipt) {
    final lines = <ReceiptLine>[];
    final date = DateFormat('dd-MM-yyyy').format(receipt.printedAt.toLocal());
    final time = DateFormat('HH:mm').format(receipt.printedAt.toLocal());

    lines.add(_cline('*** CUSTOMER BILL ***', style: ReceiptTextStyle.bold));
    lines.add(_cline(receipt.venueName.toUpperCase(), style: ReceiptTextStyle.title));
    if (_has(receipt.location)) {
      lines.add(_cline(receipt.location!.trim().toUpperCase()));
    }
    if (_has(receipt.phone)) lines.add(_cline('TEL: ${receipt.phone!.trim()}'));
    if (_has(receipt.tin)) lines.add(_cline('TIN: ${receipt.tin!.trim()}'));
    if (_has(receipt.vrn)) lines.add(_cline('VRN: ${receipt.vrn!.trim()}'));
    lines.add(_cline(_rule()));

    lines.add(_cline('BILL NO: ${receipt.documentNumber}'));
    if (_has(receipt.orderNumber)) lines.add(_cline('ORDER: ${receipt.orderNumber}'));
    lines.add(_cline('DATE: $date  TIME: $time'));
    if (_has(receipt.staffName)) lines.add(_cline('STAFF: ${receipt.staffName}'));
    if (_has(receipt.tableLabel)) lines.add(_cline('TABLE: ${receipt.tableLabel}'));
    if (_has(receipt.customerName)) lines.add(_cline('CUSTOMER: ${receipt.customerName}'));

    lines.add(const ReceiptLine(''));
    lines.addAll(_itemSection(receipt, centered: true));
    lines.add(_cline(
      _moneyLine('TOTAL', receipt.total),
      style: ReceiptTextStyle.bold,
    ));
    lines.add(_cline(_rule()));

    if (receipt.lipaNumbers.isNotEmpty) {
      lines.add(const ReceiptLine(''));
      lines.add(_cline('MOBILE MONEY LIPA', style: ReceiptTextStyle.bold));
      for (final lipa in receipt.lipaNumbers) {
        lines.add(_cline('${lipa.provider.toUpperCase()}: ${lipa.number}'));
      }
    }

    lines.add(const ReceiptLine(''));
    lines.add(_cline('NOT A FISCAL RECEIPT'));
    if (_has(receipt.notes)) {
      lines.add(const ReceiptLine(''));
      for (final noteLine in _wrap(receipt.notes!.trim(), thermalWidth)) {
        lines.add(_cline(noteLine));
      }
    }
    lines.add(const ReceiptLine(''));
    lines.add(_cline('*** END OF BILL ***'));

    return lines;
  }

  /// Butcher-style sale receipt after payment.
  static List<ReceiptLine> _buildReceiptLines(BarReceipt receipt) {
    final lines = <ReceiptLine>[];
    final date = DateFormat('dd-MM-yyyy').format(receipt.printedAt.toLocal());
    final time = DateFormat('HH:mm:ss').format(receipt.printedAt.toLocal());

    lines.add(_cline(
      '*** SYSTEM GENERATED RECEIPT ***',
      style: ReceiptTextStyle.fine,
    ));

    lines.add(_cline(
      receipt.venueName.toUpperCase(),
      style: ReceiptTextStyle.title,
    ));

    final location = _has(receipt.location) ? receipt.location!.trim() : 'HEAD OFFICE';
    lines.add(_cline(location.toUpperCase()));

    lines.add(_cline('TEL: ${_field(receipt.phone)}'));
    lines.add(_cline('TIN: ${_field(receipt.tin)}'));
    lines.add(_cline('VRN: ${_field(receipt.vrn)}'));
    lines.add(_cline('SERIAL NUMBER: ${_field(receipt.serialNumber)}'));
    lines.add(_cline('UIN: ${_field(receipt.uin)}'));
    lines.add(const ReceiptLine(''));

    final customer = _has(receipt.customerName) ? receipt.customerName!.trim().toUpperCase() : 'WALK-IN CUSTOMER';
    lines.add(_cline('CUSTOMER NAME: $customer'));
    lines.add(_cline('CUSTOMER ID TYPE: ${_customerIdType(receipt)}'));
    lines.add(_cline('CUSTOMER VRN: ${_field(receipt.customerVrn)}'));
    lines.add(const ReceiptLine(''));

    lines.add(_cline('RECEIPT NUMBER: ${receipt.documentNumber}'));
    lines.add(_cline('ZNO: ${_field(receipt.zno)}'));
    lines.add(_cline('RECEIPT DATE: $date  TIME: $time'));

    if (_has(receipt.orderNumber)) lines.add(_cline('ORDER: ${receipt.orderNumber}'));
    if (_has(receipt.tableLabel)) lines.add(_cline('TABLE: ${receipt.tableLabel}'));
    if (_has(receipt.staffName)) lines.add(_cline('STAFF: ${receipt.staffName}'));
    if (_has(receipt.tillLabel)) lines.add(_cline('TILL: ${receipt.tillLabel}'));
    if (_has(receipt.paymentMethod)) {
      lines.add(_cline('PAYMENT: ${receipt.paymentMethod!.toUpperCase()}'));
    }

    lines.add(const ReceiptLine(''));
    lines.addAll(_itemSection(receipt, centered: true));
    lines.add(_cline(_moneyLine('TOTAL EXCLUSIVE OF TAX', receipt.subtotal)));
    lines.add(_cline(_moneyLine('DISCOUNT', receipt.discount)));
    lines.add(_cline(_moneyLine('TAX A - ${receipt.taxRate.toStringAsFixed(0)}%', receipt.taxAmount)));
    lines.add(_cline(_moneyLine('TOTAL TAX', receipt.taxAmount)));
    lines.add(_cline(
      _moneyLine('TOTAL INCLUSIVE OF TAX', receipt.total),
      style: ReceiptTextStyle.bold,
    ));
    lines.add(const ReceiptLine(''));

    final code = receipt.verificationCode ?? _verificationCode(receipt);
    lines.add(_cline('RECEIPT VERIFICATION CODE'));
    lines.add(_cline(code, style: ReceiptTextStyle.bold));

    if (_has(receipt.notes)) {
      lines.add(const ReceiptLine(''));
      for (final noteLine in _wrap(receipt.notes!.trim(), thermalWidth)) {
        lines.add(_cline(noteLine));
      }
    }

    lines.add(const ReceiptLine(''));
    lines.add(_cline(
      '*** END OF SYSTEM GENERATED RECEIPT ***',
      style: ReceiptTextStyle.fine,
    ));

    return lines;
  }

  static ReceiptLine _cline(String text, {ReceiptTextStyle style = ReceiptTextStyle.normal}) =>
      ReceiptLine(text, style: style, align: ReceiptAlign.center);

  static List<String> buildLines(BarReceipt receipt) =>
      buildStyledLines(receipt).map((l) => l.text).toList();

  static String buildText(BarReceipt receipt) => '${buildLines(receipt).join('\n')}\n';

  static String _verificationCode(BarReceipt receipt) {
    final seed = '${receipt.documentNumber}|${receipt.printedAt.millisecondsSinceEpoch}|${receipt.total}';
    var hash = 2166136261;
    for (final unit in seed.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    const alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final buf = StringBuffer();
    var value = hash;
    for (var i = 0; i < 9; i++) {
      buf.write(alphabet[value % alphabet.length]);
      value ~/= alphabet.length;
      if (value == 0) value = hash + i + 1;
    }
    return buf.toString();
  }

  static String _customerIdType(BarReceipt receipt) {
    if (_has(receipt.customerName) && receipt.customerName!.trim().toLowerCase() != 'walk-in customer') {
      return 'Tab Customer';
    }
    return 'Walk-in Customer';
  }

  static String _field(String? value) {
    if (!_has(value)) return _nil;
    return value!.trim();
  }

  static List<ReceiptLine> _itemSection(BarReceipt receipt, {required bool centered}) {
    ReceiptLine row(String text, {ReceiptTextStyle style = ReceiptTextStyle.normal}) {
      if (centered) return _cline(text, style: style);
      return ReceiptLine(text, style: style);
    }

    final lines = <ReceiptLine>[
      row(_rule()),
      row(_columnsLine('DESCRIPTION', 'QTY', 'PRICE', 'AMOUNT'), style: ReceiptTextStyle.bold),
      row(_rule()),
    ];

    for (final item in receipt.items) {
      final name = item.name.trim().isEmpty ? 'ITEM' : item.name.trim().toUpperCase();
      final detail = _itemDetailLine(item);
      if (name.length <= 14) {
        lines.add(row(_itemRow(name, detail)));
      } else {
        for (final nameLine in _wrap(name, thermalWidth)) {
          lines.add(row(nameLine));
        }
        lines.add(row(detail));
      }
    }

    lines.add(row(_rule()));
    return lines;
  }

  static String _itemRow(String name, String detail) {
    const descW = 14;
    final desc = name.length <= descW ? name.padRight(descW) : name.substring(0, descW);
    return '$desc$detail';
  }

  static String _itemDetailLine(BarReceiptItem item) {
    const qtyW = 6;
    const priceW = 10;
    const amtW = 11;
    final qtyLabel = item.quantity == item.quantity.roundToDouble()
        ? '${item.quantity.toInt()} pcs'
        : '${item.quantity.toStringAsFixed(2)} kg';
    final qty = qtyLabel.padLeft(qtyW);
    final price = formatMoney(item.unitPrice).padLeft(priceW);
    final amt = formatMoney(item.lineTotal).padLeft(amtW);
    return '$qty $price $amt';
  }

  static String _columnsLine(String desc, String qty, String price, String amount) {
    return '${desc.padRight(14)}${qty.padLeft(6)} ${price.padLeft(10)} ${amount.padLeft(11)}';
  }

  static String _moneyLine(String label, double amount) {
    final value = formatMoney(amount);
    final pad = (thermalWidth - label.length - value.length).clamp(1, 80);
    return '$label${' ' * pad}$value';
  }

  static String _rule() => '-' * thermalWidth;

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
