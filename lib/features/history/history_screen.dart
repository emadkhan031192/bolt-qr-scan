// History tab: searchable, filterable, day-grouped scan list with
// swipe-to-delete (undo), multi-select actions, CSV/JSON export and JSON
// backup import.
import 'package:boltscan/widgets/empty_state.dart';
import 'package:boltscan/widgets/type_badge.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/strings.dart';
import '../../core/models/parsed_result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/actions.dart';
import '../result/result_screen.dart';
import 'history_export.dart';
import 'history_repository.dart';

/// History tab: search, filter chips, grouped list, export/import.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  /// Ids selected in multi-select mode. Non-empty means selecting.
  final Set<int> _selected = <int>{};

  bool get _selecting => _selected.isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Currently visible entries (empty while loading / on error).
  List<HistoryEntry> _visibleEntries() =>
      ref.read(historyListProvider).maybeWhen(
            data: (List<HistoryEntry> entries) => entries,
            orElse: () => const <HistoryEntry>[],
          );

  List<HistoryEntry> _selectedEntries() {
    final Set<int> ids = _selected;
    return _visibleEntries()
        .where(
          (HistoryEntry e) => e.id != null && ids.contains(e.id),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = ref.watch(appStringsProvider);
    final AsyncValue<List<HistoryEntry>> list = ref.watch(historyListProvider);
    final HistoryQuery query = ref.watch(historyQueryProvider);
    final int count = list.maybeWhen(
      data: (List<HistoryEntry> entries) => entries.length,
      orElse: () => 0,
    );
    return Scaffold(
      appBar: _selecting ? _selectAppBar(s) : _mainAppBar(s, count),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: s.searchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (String v) =>
                  ref.read(historyQueryProvider.notifier).setSearch(v),
            ),
          ),
          _FilterChips(query: query),
          const SizedBox(height: 4),
          Expanded(
            child: list.when(
              data: (List<HistoryEntry> entries) =>
                  _buildList(s, entries, query),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(s.error)),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ app bars

  AppBar _mainAppBar(AppStrings s, int count) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(s.historyTitle),
          Text(
            s.historySubtitle(count),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: <Widget>[
        PopupMenuButton<String>(
          onSelected: _onMenu,
          itemBuilder: (BuildContext c) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'csv', child: Text(s.exportCsv)),
            PopupMenuItem<String>(value: 'json', child: Text(s.exportJson)),
            PopupMenuItem<String>(
                value: 'import', child: Text(s.importBackup)),
            PopupMenuItem<String>(value: 'clear', child: Text(s.clearAll)),
          ],
        ),
      ],
    );
  }

  AppBar _selectAppBar(AppStrings s) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: s.close,
        onPressed: () => setState(_selected.clear),
      ),
      title: Text(s.selectedCount(_selected.length)),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.share_outlined),
          tooltip: s.shareSelected,
          onPressed: _shareSelected,
        ),
        IconButton(
          icon: const Icon(Icons.file_download_outlined),
          tooltip: s.exportCsv,
          onPressed: _exportSelected,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: s.deleteSelected,
          onPressed: _deleteSelected,
        ),
      ],
    );
  }

  // ------------------------------------------------------------ menu

  Future<void> _onMenu(String value) async {
    switch (value) {
      case 'csv':
        final XFile? file = await exportAllCsv(ref);
        if (file != null && mounted) {
          await BoltActions.shareFile(file);
        }
      case 'json':
        final XFile? file = await exportAllJson(ref);
        if (file != null && mounted) {
          await BoltActions.shareFile(file);
        }
      case 'import':
        await _importBackup();
      case 'clear':
        await _confirmClear();
    }
  }

  Future<void> _importBackup() async {
    final AppStrings s = ref.read(appStringsProvider);
    // file_picker 13.x: static pickFiles returns List<PlatformFile>
    // (the older FilePicker.platform API no longer exists).
    final List<PlatformFile> files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
    );
    if (files.isEmpty) return;
    final String? path = files.first.path;
    if (path == null) return;
    try {
      final int n = await importBackupFile(ref, path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.importedCount(n))),
      );
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.importFailed)),
      );
    }
  }

  Future<void> _confirmClear() async {
    final AppStrings s = ref.read(appStringsProvider);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: Text(s.clearAllTitle),
        content: Text(s.clearAllBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: Text(s.clearAll),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(historyRepositoryProvider.notifier).clearAll();
      if (mounted) setState(_selected.clear);
    }
  }

  // ------------------------------------------------------------ select mode

  Future<void> _shareSelected() async {
    final List<HistoryEntry> entries = _selectedEntries();
    if (entries.isEmpty) return;
    await BoltActions.shareText(
      entries.map((HistoryEntry e) => e.rawValue).join('\n\n'),
    );
  }

  Future<void> _exportSelected() async {
    final List<HistoryEntry> entries = _selectedEntries();
    if (entries.isEmpty) return;
    final XFile? file = await exportHistoryCsv(entries);
    if (file != null && mounted) {
      await BoltActions.shareFile(file);
    }
  }

  Future<void> _deleteSelected() async {
    final AppStrings s = ref.read(appStringsProvider);
    await ref
        .read(historyRepositoryProvider.notifier)
        .deleteEntries(_selected.toList());
    if (!mounted) return;
    setState(_selected.clear);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.deletedSnack)),
    );
  }

  void _toggleSelect(int? id) {
    if (id == null) return;
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _deleteEntry(HistoryEntry entry) async {
    final AppStrings s = ref.read(appStringsProvider);
    await ref.read(historyRepositoryProvider.notifier).deleteEntry(entry);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.deletedSnack),
        action: SnackBarAction(
          label: s.undo,
          onPressed: () =>
              ref.read(historyRepositoryProvider.notifier).restoreEntry(entry),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ list

  Widget _buildList(
    AppStrings s,
    List<HistoryEntry> entries,
    HistoryQuery query,
  ) {
    if (entries.isEmpty) {
      final bool filtering =
          query.search.trim().isNotEmpty || query.kind != 'all';
      return EmptyState(
        title: s.noHistoryTitle,
        body: filtering ? s.noResultsBody : s.noHistoryBody,
        icon: Icons.qr_code_scanner_outlined,
      );
    }
    final List<_ListItem> items = _groupedItems(s, entries);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      itemBuilder: (BuildContext c, int i) {
        final _ListItem item = items[i];
        if (item is _HeaderItem) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              item.label,
              style: Theme.of(c).textTheme.titleSmall,
            ),
          );
        }
        final HistoryEntry entry = (item as _RowItem).entry;
        return _HistoryRow(
          entry: entry,
          selecting: _selecting,
          selected: entry.id != null && _selected.contains(entry.id),
          onTap: () {
            if (_selecting) {
              _toggleSelect(entry.id);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ResultScreen(entry: entry),
                ),
              );
            }
          },
          onToggleSelect: () => _toggleSelect(entry.id),
          onDelete: _deleteEntry,
        );
      },
    );
  }

  /// Flatten entries into day-grouped header/row items (newest first).
  List<_ListItem> _groupedItems(AppStrings s, List<HistoryEntry> entries) {
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final DateFormat dayFormat = DateFormat.yMMMd(locale);
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    final List<_ListItem> items = <_ListItem>[];
    DateTime? currentDay;
    for (final HistoryEntry e in entries) {
      final DateTime day =
          DateTime(e.scannedAt.year, e.scannedAt.month, e.scannedAt.day);
      if (day != currentDay) {
        currentDay = day;
        final String label = day == today
            ? s.today
            : day == yesterday
                ? s.yesterday
                : dayFormat.format(e.scannedAt);
        items.add(_HeaderItem(label));
      }
      items.add(_RowItem(e));
    }
    return items;
  }
}

/// Filter chips driving [historyQueryProvider].
class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.query});

  final HistoryQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = ref.watch(appStringsProvider);
    final List<(String, String)> chips = <(String, String)>[
      ('all', s.filterAll),
      ('favorites', s.filterFavorites),
      ('url', s.filterLinks),
      ('product', s.filterBarcodes),
      ('wifi', s.filterWifi),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext c, int i) {
          final (String value, String label) = chips[i];
          return ChoiceChip(
            label: Text(label),
            selected: query.kind == value,
            onSelected: (_) =>
                ref.read(historyQueryProvider.notifier).setKind(value),
          );
        },
      ),
    );
  }
}

/// One history row: badge, two-line mono preview, time, favorite star.
/// Swipe left to delete (with undo); long-press enters multi-select.
class _HistoryRow extends ConsumerWidget {
  const _HistoryRow({
    required this.entry,
    required this.selecting,
    required this.selected,
    required this.onTap,
    required this.onToggleSelect,
    required this.onDelete,
  });

  final HistoryEntry entry;
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggleSelect;
  final ValueChanged<HistoryEntry> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final String preview =
        (entry.title != null && entry.title!.isNotEmpty)
            ? entry.title!
            : entry.rawValue;
    final Widget content = InkWell(
      onTap: onTap,
      onLongPress: onToggleSelect,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: <Widget>[
            if (selecting)
              Checkbox(
                value: selected,
                onChanged: (_) => onToggleSelect(),
              )
            else ...<Widget>[
              TypeBadge(kind: entry.kind, source: entry.source),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    preview,
                    style: AppText.mono(context, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.jm(locale).format(entry.scannedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (!selecting && entry.favorite)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.star,
                  size: 20,
                  color: AppColors.voltYellow,
                ),
              ),
          ],
        ),
      ),
    );
    if (entry.id == null || selecting) return content;
    return Dismissible(
      key: ValueKey<int>(entry.id!),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(entry),
      child: content,
    );
  }
}

/// Flattened list item: either a day header or a history row.
sealed class _ListItem {
  const _ListItem();
}

/// Day-group header label.
class _HeaderItem extends _ListItem {
  const _HeaderItem(this.label);

  final String label;
}

/// One history entry row.
class _RowItem extends _ListItem {
  const _RowItem(this.entry);

  final HistoryEntry entry;
}
