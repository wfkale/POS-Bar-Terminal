import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

/// Traditional POS numeric keypad — PIN mode (fixed length) or amount mode.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onClear,
    this.showDecimal = false,
    this.keyHeight = 72,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onClear;
  final bool showDecimal;
  final double keyHeight;

  @override
  Widget build(BuildContext context) {
    final keys = showDecimal
        ? ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '.']
        : ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: keyHeight,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key.isEmpty) return const SizedBox.shrink();

        return _KeyButton(
          label: key,
          onTap: () {
            if (key == '⌫') {
              onBackspace();
            } else if (key == 'C') {
              onClear?.call();
            } else {
              onDigit(key);
            }
          },
          isAction: key == '⌫' || key == 'C',
        );
      },
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.label,
    required this.onTap,
    this.isAction = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isAction ? AppTheme.surface : AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(8),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black26, width: 0.5),
          ),
          child: Center(
            child: label == '⌫'
                ? const Icon(Icons.backspace_outlined, size: 26)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: isAction ? 20 : 28,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// PIN entry dots + numpad layout used on floor terminals.
class PinEntryPanel extends StatelessWidget {
  const PinEntryPanel({
    super.key,
    required this.staffName,
    required this.avatarColor,
    required this.pinLength,
    required this.filledCount,
    required this.onDigit,
    required this.onBackspace,
    this.error,
    this.loading = false,
    this.subtitle,
  });

  final String staffName;
  final String avatarColor;
  final int pinLength;
  final int filledCount;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final String? error;
  final bool loading;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.parseHex(avatarColor);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: color,
          child: Text(
            staffName.isNotEmpty ? staffName.characters.first.toUpperCase() : '?',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(staffName, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pinLength, (i) {
            final filled = i < filledCount;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppTheme.accent : AppTheme.surfaceLight,
                border: Border.all(color: filled ? AppTheme.accent : AppTheme.textSecondary),
              ),
            );
          }),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: AppTheme.danger)),
        ],
        const SizedBox(height: 24),
        if (loading)
          const CircularProgressIndicator(color: AppTheme.accent)
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: NumericKeypad(onDigit: onDigit, onBackspace: onBackspace),
          ),
      ],
    );
  }
}
