import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

/// English / Kiswahili toggle shown on every floor terminal screen.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, this.compact = false});

  /// When true, shows EN / SW chips; when false, shows full language names.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = LocaleScope.of(context);
    final l10n = controller.strings;

    return Tooltip(
      message: l10n.language,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.textSecondary.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangChip(
              label: compact ? 'EN' : l10n.english,
              selected: !controller.isSwahili,
              onTap: () => controller.setLocale(const Locale('en')),
            ),
            _LangChip(
              label: compact ? 'SW' : l10n.kiswahili,
              selected: controller.isSwahili,
              onTap: () => controller.setLocale(const Locale('sw')),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: label.length > 3 ? 10 : 12,
            vertical: 6,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: label.length > 3 ? 11 : 12,
              color: selected ? AppTheme.background : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Standard app-bar actions: language toggle + optional trailing widgets.
class FloorAppBarActions extends StatelessWidget {
  const FloorAppBarActions({super.key, this.trailing = const []});

  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LanguageToggle(compact: true),
        ...trailing,
        const SizedBox(width: 8),
      ],
    );
  }
}
