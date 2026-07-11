import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

/// Compact developer credit — tech console vibe, not a marketing banner.
class KasiCredit extends StatelessWidget {
  const KasiCredit({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final year = DateTime.now().year.toString();

    return Semantics(
      label: l10n.kasiCreditA11y,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: compact ? 10.5 : 11.5,
                  letterSpacing: 0.6,
                  height: 1.35,
                  color: AppTheme.textSecondary.withOpacity(0.85),
                ),
                children: [
                  TextSpan(
                    text: '// ',
                    style: TextStyle(color: AppTheme.accent.withOpacity(0.9)),
                  ),
                  TextSpan(text: '${l10n.kasiEngineeredBy} '),
                  TextSpan(
                    text: 'KASI',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const TextSpan(
                    text: ' Technologies',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            if (!compact) ...[
              const SizedBox(height: 2),
              Text(
                '© $year · ${l10n.kasiTagline}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  letterSpacing: 0.8,
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
