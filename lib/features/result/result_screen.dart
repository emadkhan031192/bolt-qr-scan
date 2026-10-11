// Full result view for one scan, opened from history rows or from the scan
// sheet's "open full" action (which passes a transient entry with id null).
import 'package:boltscan/widgets/barcode_painter.dart';
import 'package:boltscan/widgets/expandable_text.dart';
import 'package:boltscan/widgets/pill_button.dart';
import 'package:boltscan/widgets/type_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app.dart';
import '../../core/l10n/strings.dart';
import '../../core/models/parsed_result.dart';
import '../../core/parsers/barcode_validator.dart';
import '../../core/parsers/gs1_prefixes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/actions.dart';
import '../history/history_repository.dart';
import 'result_actions.dart';

/// Full-screen view of one scan result.
///
/// [entry] is the scan to display; a null [HistoryEntry.id] means the scan
/// is not in history yet (transient entry from the scan sheet). [activeTab]
/// selects the bottom-tab highlight (1 = History, the usual opener).
class ResultScreen extends ConsumerWidget {
  const ResultScreen({
    super.key,
    required this.entry,
    this.activeTab = 1,
  });

  /// The scan to display.
  final HistoryEntry entry;

  /// Bottom-tab index highlighted in the tab bar.
  final int activeTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild when history mutates (favorite toggles, saves).
    ref.watch(historyRepositoryProvider);
    final AppStrings s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: s.back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(s.resultTitle),
        actions: <Widget>[
          _FavoriteButton(entry: entry),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _HeroCard(entry: entry),
          const SizedBox(height: 16),
          BoltPillButton(
            label: primaryLabelFor(s, entry.kind),
            icon: primaryIconFor(entry.kind),
            onPressed: () => primaryActionFor(context, ref, entry.toParsed()),
          ),
          const SizedBox(height: 12),
          _TileRow(entry: entry),
          const SizedBox(height: 16),
          _DetailsCard(entry: entry),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeTab,
        onDestinationSelected: (int index) {
          Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
          ref.read(mainTabProvider.notifier).setTab(index);
        },
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: const Icon(Icons.qr_code_scanner),
            label: s.scanTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: s.historyTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_box_outlined),
            selectedIcon: const Icon(Icons.add_box),
            label: s.createTab,
          ),
        ],
      ),
    );
  }
}

/// Star toggle in the app bar. For transient entries (id == null) the scan
/// is saved to history first, then favorited.
class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = ref.watch(appStringsProvider);
    return IconButton(
      icon: Icon(entry.favorite ? Icons.star : Icons.star_border),
      tooltip: entry.favorite ? s.unfavorite : s.favorite,
      onPressed: () => _toggle(ref),
    );
  }

  Future<void> _toggle(WidgetRef ref) async {
    final HistoryRepository repo = ref.read(historyRepositoryProvider.notifier);
    if (entry.id == null) {
      final HistoryEntry? saved =
          await repo.saveScan(entry.toParsed(), source: entry.source);
      if (saved == null) return;
      entry.id = saved.id;
      await repo.toggleFavorite(saved);
      entry.favorite = true;
    } else {
      await repo.toggleFavorite(entry);
      entry.favorite = !entry.favorite;
    }
  }
}

/// Hero card: type badge, detection time, and the scanned content.
/// Products render a barcode strip plus the grouped digits; everything else
/// renders expandable mono text.
class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = ref.watch(appStringsProvider);
    final bool isProduct = entry.kind == ResultKind.product;
    final String digits = entry.rawValue.replaceAll(RegExp(r'[^0-9]'), '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                // TypeBadge renders the 'created' chip itself when needed.
                TypeBadge(kind: entry.kind, source: entry.source),
                const Spacer(),
                Flexible(
                  child: Text(
                    s.detectedIn(
                      (entry.detectionMs / 1000).toStringAsFixed(2),
                    ),
                    style: AppText.mono(context, fontSize: 12),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isProduct && digits.isNotEmpty) ...<Widget>[
              BarcodeStrip(digits: digits, height: 72),
              const SizedBox(height: 12),
              SelectableText(
                groupBarcodeDigits(digits),
                style: AppText.mono(
                  context,
                  fontSize: 22,
                  weight: FontWeight.w700,
                ),
              ),
            ] else
              ExpandableText(
                text: entry.rawValue,
                style: AppText.mono(context, fontSize: 15),
              ),
          ],
        ),
      ),
    );
  }
}

/// Copy / Share / Save-to-list tile row.
class _TileRow extends ConsumerWidget {
  const _TileRow({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = ref.watch(appStringsProvider);
    final bool saved = entry.id != null;
    return Row(
      children: <Widget>[
        _ActionTile(
          icon: Icons.copy_outlined,
          label: s.copy,
          onPressed: () => _copy(context, s),
        ),
        _ActionTile(
          icon: Icons.share_outlined,
          label: s.share,
          onPressed: () => BoltActions.shareText(entry.rawValue),
        ),
        _ActionTile(
          icon: saved ? Icons.check : Icons.bookmark_add_outlined,
          label: saved ? s.savedToList : s.saveToList,
          onPressed: saved ? null : () => _save(context, ref, s),
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context, AppStrings s) async {
    final ActionResult r = await BoltActions.copyText(context, entry.rawValue);
    if (r == ActionResult.ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.copiedToClipboard)),
      );
    }
  }

  Future<void> _save(BuildContext context, WidgetRef ref, AppStrings s) async {
    final HistoryEntry? savedEntry = await ref
        .read(historyRepositoryProvider.notifier)
        .saveScan(entry.toParsed(), source: entry.source);
    if (savedEntry != null) entry.id = savedEntry.id;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.savedToList)),
      );
    }
  }
}

/// One tile of the action row. A null [onPressed] renders the tile disabled.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool enabled = onPressed != null;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outline),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: 22,
                  color: enabled ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: enabled
                              ? scheme.onSurface
                              : scheme.onSurface.withValues(alpha: 0.4),
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

/// Details card with per-kind rows plus the scan timestamp.
class _DetailsCard extends ConsumerWidget {
  const _DetailsCard({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = ref.watch(appStringsProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              s.detailsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            ..._detailRows(context, s, entry),
          ],
        ),
      ),
    );
  }
}

/// Per-kind detail rows, always ending with the scanned-at row.
List<Widget> _detailRows(BuildContext context, AppStrings s, HistoryEntry entry) {
  final String locale = Localizations.localeOf(context).toLanguageTag();
  final DateFormat when = DateFormat.yMMMd(locale).add_jm();
  final List<Widget> rows = <Widget>[];
  switch (entry.kind) {
    case ResultKind.product:
      rows.addAll(_productRows(context, s, entry));
    case ResultKind.wifi:
      _maybeAdd(
        rows,
        _labeledRow(
          context,
          s.wifiNetworkRow,
          firstField(entry.fields, const <String>['ssid', 'name', 'network']),
        ),
      );
      _maybeAdd(
        rows,
        _labeledRow(
          context,
          s.wifiSecurityRow,
          firstField(entry.fields, const <String>['security', 'type', 'auth']),
        ),
      );
      final String password = firstField(
        entry.fields,
        const <String>['password', 'pass', 'key'],
      );
      if (password.isNotEmpty) {
        rows.add(
          _WifiPasswordRow(
            label: s.wifiPasswordRow,
            password: password,
            strings: s,
          ),
        );
      }
    case ResultKind.url:
      rows.add(_urlRow(context, s, entry.rawValue));
      if (entry.safetyFlags.isNotEmpty) {
        rows.add(_safetyRow(context, s, entry.safetyFlags));
      }
    case ResultKind.contact:
      _maybeAdd(rows, _labeledRow(context, s.labelName, firstField(entry.fields, const <String>['name', 'n'])));
      _maybeAdd(rows, _labeledRow(context, s.labelPhone, firstField(entry.fields, const <String>['phone', 'tel', 'number'])));
      _maybeAdd(rows, _labeledRow(context, s.labelEmail, firstField(entry.fields, const <String>['email'])));
      _maybeAdd(rows, _labeledRow(context, s.labelOrg, firstField(entry.fields, const <String>['org', 'organization', 'company'])));
    case ResultKind.email:
      _maybeAdd(rows, _labeledRow(context, s.labelEmail, firstField(entry.fields, const <String>['to', 'address', 'email'])));
      _maybeAdd(rows, _labeledRow(context, s.labelSubject, firstField(entry.fields, const <String>['subject', 'subj'])));
      _maybeAdd(rows, _labeledRow(context, s.labelMessage, firstField(entry.fields, const <String>['body', 'text', 'message'])));
    case ResultKind.phone:
      _maybeAdd(rows, _labeledRow(context, s.labelPhone, firstField(entry.fields, const <String>['number', 'phone', 'tel'])));
    case ResultKind.sms:
      _maybeAdd(rows, _labeledRow(context, s.labelPhone, firstField(entry.fields, const <String>['number', 'phone', 'to'])));
      _maybeAdd(rows, _labeledRow(context, s.labelMessage, firstField(entry.fields, const <String>['body', 'text', 'message'])));
    case ResultKind.geo:
      _maybeAdd(rows, _labeledRow(context, s.labelLatitude, firstField(entry.fields, const <String>['lat', 'latitude'])));
      _maybeAdd(rows, _labeledRow(context, s.labelLongitude, firstField(entry.fields, const <String>['lng', 'lon', 'longitude'])));
      _maybeAdd(rows, _labeledRow(context, s.labelContent, firstField(entry.fields, const <String>['query', 'q', 'label'])));
    case ResultKind.event:
      _maybeAdd(rows, _labeledRow(context, s.labelContent, firstField(entry.fields, const <String>['summary', 'title', 'name'])));
      _maybeAdd(rows, _labeledRow(context, s.typeLocation, firstField(entry.fields, const <String>['location', 'place'])));
      rows.add(_eventWhenRow(context, entry, when));
    case ResultKind.text:
      break;
  }
  rows.add(
    _labeledRow(context, s.scannedAtRow, when.format(entry.scannedAt))!,
  );
  return rows;
}

void _maybeAdd(List<Widget> rows, Widget? row) {
  if (row != null) rows.add(row);
}

/// Label/value row. Returns null when [value] is empty.
Widget? _labeledRow(BuildContext context, String label, String value,
    {bool mono = true}) {
  if (value.isEmpty) return null;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 2),
        Text(
          value,
          style: mono
              ? AppText.mono(context)
              : Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

/// Product rows: format, GS1 country, check-digit validity.
List<Widget> _productRows(BuildContext context, AppStrings s, HistoryEntry entry) {
  final List<Widget> rows = <Widget>[];
  final String format = entry.formatLabel.isNotEmpty
      ? entry.formatLabel
      : firstField(entry.fields, const <String>['format']);
  _maybeAdd(rows, _labeledRow(context, s.formatRow, format));
  _maybeAdd(rows, _labeledRow(context, s.gs1CountryRow, _gs1Display(entry) ?? ''));
  final String digits = entry.rawValue.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isNotEmpty) rows.add(_checkDigitRow(context, s, digits));
  return rows;
}

/// GS1 country display as `<prefix> - <country>`. Tolerates the parser
/// storing either the full string (e.g. "969 - Pakistan") or just the
/// country name, and derives it from the digits when missing.
String? _gs1Display(HistoryEntry entry) {
  final String stored = (entry.fields['gs1Country'] ?? '').trim();
  if (stored.contains(' - ')) return stored;
  final String digits = entry.rawValue.replaceAll(RegExp(r'[^0-9]'), '');
  final String prefix = digits.length >= 3 ? digits.substring(0, 3) : '';
  final String? country = prefix.isEmpty ? null : gs1Country(prefix);
  final String name =
      (country != null && country.isNotEmpty) ? country : stored;
  if (prefix.isEmpty || name.isEmpty) return null;
  return '$prefix - $name';
}

/// Check-digit row showing `<digit>` plus the localized valid/invalid word,
/// with a green/red icon + text (never color alone). Validity is unknown
/// for non-GTIN lengths.
Widget _checkDigitRow(BuildContext context, AppStrings s, String digits) {
  final bool? valid = switch (digits.length) {
    13 => isValidEan13(digits),
    8 => isValidEan8(digits),
    12 => isValidUpcA(digits),
    _ => null,
  };
  final String digit = digits.substring(digits.length - 1);
  final Color? color =
      valid == null ? null : (valid ? AppColors.success : AppColors.danger);
  final IconData? icon = valid == null
      ? null
      : (valid ? Icons.check_circle_outline : Icons.error_outline);
  final String value = valid == null
      ? digit
      : '$digit - ${valid ? s.checkDigitValid : s.checkDigitInvalid}';
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(s.checkDigitRow, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 2),
        Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                value,
                style: AppText.mono(context, fontSize: 16, color: color),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Full-URL row with the domain highlighted bold in electric blue.
Widget _urlRow(BuildContext context, AppStrings s, String url) {
  final String host = Uri.tryParse(url)?.host ?? '';
  final int hostIndex = host.isEmpty ? -1 : url.indexOf(host);
  final TextStyle base = AppText.mono(context);
  final TextSpan span = hostIndex < 0
      ? TextSpan(text: url, style: base)
      : TextSpan(
          style: base,
          children: <TextSpan>[
            TextSpan(text: url.substring(0, hostIndex)),
            TextSpan(
              text: host,
              style: base.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.electricBlue,
              ),
            ),
            TextSpan(text: url.substring(hostIndex + host.length)),
          ],
        );
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(s.urlFullRow, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 2),
        SelectableText.rich(span),
      ],
    ),
  );
}

/// Safety section: warning header plus one mono chip per flag key.
Widget _safetyRow(BuildContext context, AppStrings s, List<String> flags) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.warning_amber_outlined,
              size: 18,
              color: AppColors.danger,
            ),
            const SizedBox(width: 6),
            Text(
              s.safetyNoteTitle,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String flag in flags)
              Chip(
                label: Text(flag, style: AppText.mono(context, fontSize: 12)),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    ),
  );
}

/// Event start/end row. The strings contract has no start/end labels, so the
/// row is identified by a schedule icon plus formatted dates.
Widget _eventWhenRow(
    BuildContext context, HistoryEntry entry, DateFormat when) {
  final String start = _formatEventDate(
    when,
    firstField(entry.fields, const <String>['start', 'dtstart', 'begin']),
  );
  final String end = _formatEventDate(
    when,
    firstField(entry.fields, const <String>['end', 'dtend', 'finish']),
  );
  final String value =
      <String>[start, end].where((String t) => t.isNotEmpty).join(' → ');
  if (value.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: <Widget>[
        const Icon(Icons.schedule_outlined, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value, style: AppText.mono(context)),
        ),
      ],
    ),
  );
}

/// Format an event start/end value (ISO-8601 or ms epoch), or ''.
String _formatEventDate(DateFormat when, String value) {
  if (value.isEmpty) return '';
  final DateTime? iso = DateTime.tryParse(value);
  if (iso != null) return when.format(iso);
  final int? ms = int.tryParse(value);
  if (ms != null) {
    return when.format(DateTime.fromMillisecondsSinceEpoch(ms));
  }
  return value;
}

/// Wi-Fi password row with a show/hide toggle.
class _WifiPasswordRow extends StatefulWidget {
  const _WifiPasswordRow({
    required this.label,
    required this.password,
    required this.strings,
  });

  final String label;
  final String password;
  final AppStrings strings;

  @override
  State<_WifiPasswordRow> createState() => _WifiPasswordRowState();
}

class _WifiPasswordRowState extends State<_WifiPasswordRow> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 2),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _obscured
                      ? '•' * widget.password.length.clamp(1, 32)
                      : widget.password,
                  style: AppText.mono(context),
                ),
              ),
              IconButton(
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip:
                    _obscured ? widget.strings.show : widget.strings.hide,
                onPressed: () => setState(() => _obscured = !_obscured),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
