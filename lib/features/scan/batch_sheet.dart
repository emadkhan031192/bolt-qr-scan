// Inline batch-scan panel: recent batch results with Export CSV + Clear.
// Embedded above the scan screen's bottom row (not a modal sheet).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/models/parsed_result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/type_badge.dart';

/// Compact batch-scan list panel.
///
/// Shows the accumulated [scans] (newest last) with an [onExportCsv] and
/// [onClear] action in the header. Kept to a max height of 220 logical px.
class BatchSheet extends ConsumerWidget {
  /// Creates a batch sheet panel.
  const BatchSheet({
    super.key,
    required this.scans,
    required this.onExportCsv,
    required this.onClear,
  });

  /// Accumulated batch scans, oldest first.
  final List<ParsedResult> scans;

  /// Called when the user taps Export CSV.
  final VoidCallback onExportCsv;

  /// Called when the user taps Clear.
  final VoidCallback onClear;

  String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = ref.watch(appStringsProvider);
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkLine),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${s.batchSheetTitle} · ${scans.length}',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onExportCsv,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: Text(s.exportCsv),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.voltYellow,
                    minimumSize: const Size(48, 40),
                    textStyle: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(s.clear),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.darkMuted,
                    minimumSize: const Size(48, 40),
                    textStyle: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            color: AppColors.darkLine,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: scans.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final ParsedResult scan = scans[index];
                return Row(
                  children: <Widget>[
                    TypeBadge(kind: scan.kind),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        scan.rawValue.replaceAll(RegExp(r'\s+'), ' ').trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.mono(
                          context,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _time(scan.scannedAt),
                      style: AppText.mono(
                        context,
                        fontSize: 12,
                        color: AppColors.darkMuted,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
