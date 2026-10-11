import 'package:boltscan/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Centered empty-state illustration: icon in a volt-yellow tinted circle,
/// a title, a muted body, and an optional action widget (usually a button).
class EmptyState extends StatelessWidget {
  /// Creates an empty state.
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  /// Icon drawn in the tinted circle.
  final IconData icon;

  /// Headline text.
  final String title;

  /// Supporting text.
  final String body;

  /// Optional action placed below the body.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.voltYellow.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 40,
                color: dark ? AppColors.voltYellow : AppColors.ink,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: dark ? AppColors.darkMuted : AppColors.muted,
              ),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
