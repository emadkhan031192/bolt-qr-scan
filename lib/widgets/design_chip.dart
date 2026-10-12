// Filter/type pill matching the Bolt Scan design: the selected pill is solid
// ink/black with white text, unselected pills are card-colored with a hairline
// border. Used on the History (filter) and Create (type) screens.
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A text pill used for filter and type selection rows.
class DesignChip extends StatelessWidget {
  /// Creates a design filter chip.
  const DesignChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Chip text.
  final String label;

  /// Whether the chip is currently selected.
  final bool selected;

  /// Called when the chip is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final Color selectedBg = dark ? Colors.white : AppColors.ink;
    final Color selectedFg = dark ? AppColors.ink : Colors.white;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? selectedBg : theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: selected
                ? null
                : Border.all(color: AppColors.line.withValues(alpha: 0.9)),
          ),
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: selected ? selectedFg : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
