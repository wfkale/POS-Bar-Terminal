import 'dart:convert';
import 'dart:typed_data';

import 'bar_receipt.dart';
import 'receipt_layout_service.dart';

/// ESC/POS bytes for 80mm (≈72mm print area) thermal printers.
class EscPosBuilder {
  /// Initialize + text + feed + partial cut.
  static Uint8List build(BarReceipt receipt) {
    final text = ReceiptLayoutService.buildText(receipt);
    final out = BytesBuilder();

    // ESC @ — initialize
    out.add([0x1B, 0x40]);
    // ESC a 0 — left align
    out.add([0x1B, 0x61, 0x00]);
    // ESC 3 n — line spacing
    out.add([0x1B, 0x33, 0x18]);
    // ESC M 0 — Font A
    out.add([0x1B, 0x4D, 0x00]);
    // ESC t 0 — code page PC437 (widely supported ASCII-compatible)
    out.add([0x1B, 0x74, 0x00]);

    out.add(_encodeAsciiSafe(text));

    // Feed a few lines so the cut is below the last text
    out.add([0x0A, 0x0A, 0x0A, 0x0A]);
    // GS V 1 — partial cut (safer than full cut on many 80mm printers)
    out.add([0x1D, 0x56, 0x01]);

    return out.toBytes();
  }

  /// ESC/POS printers typically expect single-byte encodings.
  /// Map anything outside Latin-1 printable to '?' so latin1.encode never throws.
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
