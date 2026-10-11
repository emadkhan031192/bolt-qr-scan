import 'package:boltscan/core/l10n/strings.dart';
import 'package:boltscan/core/models/parsed_result.dart';
import 'package:boltscan/core/theme/app_colors.dart';
import 'package:boltscan/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Colored tint pill labelling a scan's [ResultKind], with text always
/// (never color-only). Optionally appends a second 'Created' chip when the
/// entry came from the Create tab ([source] == 'created').
class TypeBadge extends ConsumerWidget {
  /// Creates a type badge for [kind].
  const TypeBadge({
    super.key,
    required this.kind,
    this.source,
  });

  /// The parsed result kind to label.
  final ResultKind kind;

  /// History source ('scanned' | 'created'); 'created' adds a second chip.
  final String? source;

  /// Localized text label for [kind].
  String _kindLabel(AppStrings strings) => switch (kind) {
        ResultKind.url => strings.kindUrl,
        ResultKind.wifi => strings.kindWifi,
        ResultKind.contact => strings.kindContact,
        ResultKind.email => strings.kindEmail,
        ResultKind.phone => strings.kindPhone,
        ResultKind.sms => strings.kindSms,
        ResultKind.geo => strings.kindGeo,
        ResultKind.event => strings.kindEvent,
        ResultKind.product => strings.kindProduct,
        ResultKind.text => strings.kindText,
      };

  /// Base tint color for [kind].
  Color _baseColor(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return switch (kind) {
      ResultKind.url => AppColors.electricBlue,
      ResultKind.wifi => AppColors.success,
      ResultKind.product => AppColors.voltYellow,
      ResultKind.text => AppColors.muted,
      _ => dark ? AppColors.darkMuted : AppColors.muted,
    };
  }

  /// Readable text color derived from [base] for the current theme.
  Color _textColor(BuildContext context, Color base) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return Color.lerp(base, Colors.white, 0.35)!;
    }
    if (base == AppColors.voltYellow) {
      return Color.lerp(base, AppColors.ink, 0.55)!;
    }
    return base;
  }

  /// One tinted pill chip.
  Widget _chip(BuildContext context, String label, Color base) {
    final Color text = _textColor(context, base);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppText.mono(
          context,
          fontSize: 11.5,
          weight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = ref.watch(appStringsProvider);
    final Color base = _baseColor(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _chip(context, _kindLabel(strings), base),
        if (source == 'created')
          _chip(
            context,
            strings.createdTag,
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkMuted
                : AppColors.muted,
          ),
      ],
    );
  }
}
