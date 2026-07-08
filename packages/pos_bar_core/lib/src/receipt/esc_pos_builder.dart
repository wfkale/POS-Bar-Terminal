import 'dart:convert';
import 'dart:typed_data';

import 'bar_receipt.dart';
import 'receipt_layout_service.dart';

/// ESC/POS bytes for 80mm (≈72mm print area) thermal printers.
class EscPosBuilder {
  /// Initialize + UTF-8 where supported + text + feed + partial cut.
  static Uint8List build(BarReceipt receipt) {
    final text = ReceiptLayoutService.buildText(receipt);
    final out = BytesBuilder();

    // ESC @ — initialize
    out.add([0x1B, 0x40]);
    // ESC a 1 — center (we mix left/center in text; keep left default)
    out.add([0x1B, 0x61, 0x00]);
    // ESC 3 n — line spacing
    out.add([0x1B, 0x33, 0x18]);
    // Font A
    out.add([0x1B, 0x4D, 0x00]);

    out.add(latin1.encode(text));

    // Feed a few lines
    out.add([0x0A, 0x0A, 0x0A]);
    // GS V 0 — full cut (many 80mm printers support this)
    out.add([0x1D, 0x56, 0x00]);

    return out.toBytes();
  }
}
