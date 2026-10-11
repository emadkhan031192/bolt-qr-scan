import 'package:boltscan/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Brand yellow pill button with a subtle press-scale effect.
///
/// The button shrinks to 0.95 while pressed (120ms); the animation is skipped
/// when [MediaQuery.disableAnimations] is true. Layout is flexible so it
/// survives large text scales.
class BoltPillButton extends StatefulWidget {
  /// Creates a pill button.
  const BoltPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.primary = true,
  });

  /// Text shown inside the button.
  final String label;

  /// Called on tap; null renders the button disabled.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// When true the button stretches to the full available width.
  final bool expanded;

  /// Primary buttons are yellow-filled; secondary are outlined.
  final bool primary;

  @override
  State<BoltPillButton> createState() => _BoltPillButtonState();
}

class _BoltPillButtonState extends State<BoltPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool enabled = widget.onPressed != null;
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;

    final Color background =
        widget.primary ? AppColors.voltYellow : Colors.transparent;
    final Color foreground =
        widget.primary ? AppColors.ink : scheme.onSurface;

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.icon != null) ...<Widget>[
          Icon(widget.icon, size: 20, color: foreground),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ).copyWith(color: foreground),
          ),
        ),
      ],
    );

    final Widget body = AnimatedScale(
      scale: _pressed && enabled ? 0.95 : 1.0,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 120),
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(28),
          border: widget.primary
              ? null
              : Border.all(color: scheme.outline, width: 1.5),
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );

    final Widget sized =
        widget.expanded ? SizedBox(width: double.infinity, child: body) : body;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Semantics(
        button: true,
        label: widget.label,
        enabled: enabled,
        onTap: widget.onPressed,
        child: ExcludeSemantics(
          child: GestureDetector(
            onTap: widget.onPressed,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: sized,
          ),
        ),
      ),
    );
  }
}
