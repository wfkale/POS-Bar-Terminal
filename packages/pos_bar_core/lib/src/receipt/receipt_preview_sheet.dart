import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'bar_receipt.dart';
import 'receipt_layout_service.dart';
import 'receipt_line.dart';

/// Shows the receipt layout that will be sent to the thermal printer.
Future<void> showReceiptPreview({
  required BuildContext context,
  required BarReceipt receipt,
  String title = 'Receipt preview',
}) {
  final lines = ReceiptLayoutService.buildStyledLines(receipt);
  final text = ReceiptLayoutService.buildText(receipt);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).padding.bottom;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Preview copied')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.65,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.textSecondary.withOpacity(0.25)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final line in lines) _PreviewLine(line: line),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.line});

  final ReceiptLine line;

  @override
  Widget build(BuildContext context) {
    if (line.text.isEmpty) {
      return const SizedBox(height: 6);
    }

    final style = switch (line.style) {
      ReceiptTextStyle.fine => const TextStyle(
          fontFamily: 'Courier',
          fontFamilyFallback: ['Courier New', 'monospace'],
          fontSize: 9,
          height: 1.2,
          color: Colors.black54,
        ),
      ReceiptTextStyle.title => const TextStyle(
          fontFamily: 'Courier',
          fontFamilyFallback: ['Courier New', 'monospace'],
          fontSize: 16,
          fontWeight: FontWeight.w800,
          height: 1.2,
          color: Colors.black,
        ),
      ReceiptTextStyle.bold => const TextStyle(
          fontFamily: 'Courier',
          fontFamilyFallback: ['Courier New', 'monospace'],
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.25,
          color: Colors.black,
        ),
      ReceiptTextStyle.normal => const TextStyle(
          fontFamily: 'Courier',
          fontFamilyFallback: ['Courier New', 'monospace'],
          fontSize: 12,
          height: 1.25,
          color: Colors.black,
        ),
    };

    return Text(
      line.text,
      textAlign: line.align == ReceiptAlign.center ? TextAlign.center : TextAlign.left,
      style: style,
    );
  }
}
