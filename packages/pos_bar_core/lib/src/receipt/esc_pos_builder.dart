import 'dart:convert';
import 'dart:typed_data';

import 'bar_receipt.dart';
import 'receipt_layout_service.dart';
import 'receipt_line.dart';

/// ESC/POS bytes for 80mm (≈72mm print area) thermal printers.
class EscPosBuilder {
  static Uint8List build(BarReceipt receipt) {
    final out = BytesBuilder();

    // ESC @ — initialize
    out.add([0x1B, 0x40]);
    out.add([0x1B, 0x33, 0x18]); // line spacing
    out.add([0x1B, 0x74, 0x00]); // code page PC437

    for (final line in ReceiptLayoutService.buildStyledLines(receipt)) {
      out.add(_encodeLine(line));
    }

    out.add([0x0A, 0x0A, 0x0A, 0x0A]);
    out.add([0x1D, 0x56, 0x01]); // partial cut

    return out.toBytes();
  }

  static List<int> _encodeLine(ReceiptLine line) {
    final out = BytesBuilder();

    // Alignment
    out.add([0x1B, 0x61, line.align == ReceiptAlign.center ? 0x01 : 0x00]);

    // Style
    switch (line.style) {
      case ReceiptTextStyle.fine:
        out.add([0x1B, 0x4D, 0x01]); // Font B (smaller)
        out.add([0x1D, 0x21, 0x00]);
        out.add([0x1B, 0x45, 0x00]); // bold off
      case ReceiptTextStyle.normal:
        out.add([0x1B, 0x4D, 0x00]); // Font A
        out.add([0x1D, 0x21, 0x00]);
        out.add([0x1B, 0x45, 0x00]);
      case ReceiptTextStyle.bold:
        out.add([0x1B, 0x4D, 0x00]);
        out.add([0x1D, 0x21, 0x00]);
        out.add([0x1B, 0x45, 0x01]); // bold on
      case ReceiptTextStyle.title:
        out.add([0x1B, 0x4D, 0x00]);
        out.add([0x1D, 0x21, 0x11]); // double width + height
        out.add([0x1B, 0x45, 0x01]);
    }

    out.add(_encodeAsciiSafe('${line.text}\n'));

    // Reset to normal after title/bold/fine so next line starts clean.
    out.add([0x1B, 0x4D, 0x00]);
    out.add([0x1D, 0x21, 0x00]);
    out.add([0x1B, 0x45, 0x00]);
    out.add([0x1B, 0x61, 0x00]);

    return out.toBytes();
  }

  static List<int> _encodeAsciiSafe(String text) {
    final buf = StringBuffer();
    for (final unit in text.runes) {
      if (unit == 0x09 || unit == 0x0A || unit == 0x0D) {
        buf.writeCharCode(unit);
      } else if (unit >= 0x20 && unit <= 0x7E) {
        buf.writeCharCode(unit);
      } else if (unit >= 0xA0 && unit <= 0xFF) {
        buf.writeCharCode(unit);
      } else {
        buf.write('?');
      }
    }
    return latin1.encode(buf.toString());
  }
}
