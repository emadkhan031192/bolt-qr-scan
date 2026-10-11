import 'package:boltscan/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// One selectable option inside a [BoltSegmentedControl].
class SegmentedOption<T> {
  /// Creates a segmented option.
  const SegmentedOption({
    required this.value,
    required this.label,
    this.icon,
  });

  /// Value reported to [BoltSegmentedControl.onChanged] when selected.
  final T value;

  /// Text label shown in the segment.
  final String label;

  /// Optional leading icon.
  final IconData? icon;
}

/// Pill-shaped segmented control; the selected option is highlighted in
/// volt yellow. Each option exposes button semantics with a selected state,
/// and segments grow vertically so the control survives large text scales.
class BoltSegmentedControl<T> extends StatelessWidget {
  /// Creates a segmented control.
  const BoltSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  /// Options to display, in order.
  final List<SegmentedOption<T>> options;

  /// Currently selected value.
  final T value;

  /// Called when the user picks an option.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: <Widget>[
          for (final SegmentedOption<T> option in options)
            Expanded(child: _segment(context, scheme, option)),
        ],
      ),
    );
  }

  /// One segment, with button semantics and the selected-state pill.
  Widget _segment(
    BuildContext context,
    ColorScheme scheme,
    SegmentedOption<T> option,
  ) {
    final bool selected = option.value == value;
    final Color foreground =
        selected ? AppColors.ink : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      onTap: () => onChanged(option.value),
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => onChanged(option.value),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: selected
                ? BoxDecoration(
                    color: AppColors.voltYellow,
                    borderRadius: BorderRadius.circular(24),
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (option.icon != null) ...<Widget>[
                  Icon(option.icon, size: 18, color: foreground),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    option.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ).copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
