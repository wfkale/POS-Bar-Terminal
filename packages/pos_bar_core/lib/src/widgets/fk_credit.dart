import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

/// Developer credit — console-style signature for FK Solutions.
class FkCredit extends StatelessWidget {
  const FkCredit({super.key, this.compact = false});

  final bool compact;

  static const company = 'FK Solutions';
  static const phone = '+255768141059';
  static const email = 'sales@fksolutions.co';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final year = DateTime.now().year.toString();
    final baseStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: compact ? 10.5 : 11.5,
      letterSpacing: 0.55,
      height: 1.4,
      color: AppTheme.textSecondary.withOpacity(0.88),
    );

    return Semantics(
      label: l10n.fkCreditA11y,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                style: baseStyle,
                children: [
                  TextSpan(
                    text: '// ',
                    style: TextStyle(color: AppTheme.accent.withOpacity(0.95), fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: '${l10n.fkForgedBy} '),
                  TextSpan(
                    text: 'FK',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const TextSpan(
                    text: ' Solutions',
                    style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            if (!compact) ...[
              const SizedBox(height: 3),
              Text.rich(
                TextSpan(
                  style: baseStyle.copyWith(
                    fontSize: 10,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                  children: [
                    TextSpan(text: phone, style: TextStyle(color: AppTheme.accent.withOpacity(0.75))),
                    const TextSpan(text: '  ·  '),
                    TextSpan(text: email),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '© $year · ${l10n.fkTagline}',
                textAlign: TextAlign.center,
                style: baseStyle.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.7,
                  color: AppTheme.textSecondary.withOpacity(0.55),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Back-compat alias while splash screens catch up.
typedef KasiCredit = FkCredit;
