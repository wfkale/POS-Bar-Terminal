/// One styled line for thermal + on-screen receipt preview.
class ReceiptLine {
  const ReceiptLine(
    this.text, {
    this.style = ReceiptTextStyle.normal,
    this.align = ReceiptAlign.left,
  });

  final String text;
  final ReceiptTextStyle style;
  final ReceiptAlign align;
}

enum ReceiptTextStyle { fine, normal, title, bold }

enum ReceiptAlign { left, center }
