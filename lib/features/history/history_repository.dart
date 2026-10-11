// Riverpod repository over HistoryDb: save + query + export helpers.
// Re-parses raw values through parseResult() on read so fields/safetyFlags
// stay fresh without extra columns.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/parsed_result.dart';
import '../../core/parsers/result_parser.dart';
import '../settings/settings_model.dart';
import 'history_db.dart';

/// Query descriptor for the history list.
class HistoryQuery {
  const HistoryQuery({
    this.search = '',
    this.kind = 'all',
    this.favoritesOnly = false,
  });

  final String search;
  final String kind; // 'all' | 'favorites' | ResultKind.name ...
  final bool favoritesOnly;

  HistoryQuery copyWith({String? search, String? kind, bool? favoritesOnly}) =>
      HistoryQuery(
        search: search ?? this.search,
        kind: kind ?? this.kind,
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      );

  @override
  bool operator ==(Object other) =>
      other is HistoryQuery &&
      other.search == search &&
      other.kind == kind &&
      other.favoritesOnly == favoritesOnly;

  @override
  int get hashCode => Object.hash(search, kind, favoritesOnly);
}

/// Current history query, driven by the search field + filter chips.
final historyQueryProvider =
    NotifierProvider<HistoryQueryNotifier, HistoryQuery>(
        HistoryQueryNotifier.new);

class HistoryQueryNotifier extends Notifier<HistoryQuery> {
  @override
  HistoryQuery build() => const HistoryQuery();

  void setSearch(String v) => state = state.copyWith(search: v);
  void setKind(String v) =>
      state = state.copyWith(kind: v, favoritesOnly: v == 'favorites');
}

class HistoryRepository extends Notifier<int> {
  /// A generation counter; bumped on every mutation so the list refetches.
  @override
  int build() => 0;

  void _bump() => state = state + 1;

  /// Save a scan result (respects saveHistory / keepDuplicates / historyLimit).
  /// Returns the inserted [HistoryEntry] or null when skipped/disabled.
  Future<HistoryEntry?> saveScan(ParsedResult result, {String source = 'scanned'}) async {
    final SettingsModel settings = ref.read(settingsProvider);
    if (!settings.saveHistory && source == 'scanned') return null;
    final HistoryEntry entry = HistoryEntry(
      kind: result.kind,
      rawValue: result.rawValue,
      formatLabel: result.formatLabel,
      detectionMs: result.detectionMs,
      scannedAt: result.scannedAt,
      source: source,
      title: result.title,
    );
    final int id = await HistoryDb.insert(
      entry,
      limit: settings.historyLimit,
      skipDuplicates: !settings.keepDuplicates,
    );
    if (id < 0) return null;
    entry.id = id;
    _bump();
    return entry;
  }

  Future<void> toggleFavorite(HistoryEntry entry) async {
    if (entry.id == null) return;
    await HistoryDb.setFavorite(entry.id!, !entry.favorite);
    _bump();
  }

  Future<void> deleteEntry(HistoryEntry entry) async {
    if (entry.id == null) return;
    await HistoryDb.delete(entry.id!);
    _bump();
  }

  Future<HistoryEntry?> restoreEntry(HistoryEntry entry) async {
    final SettingsModel settings = ref.read(settingsProvider);
    final HistoryEntry copy = HistoryEntry(
      kind: entry.kind,
      rawValue: entry.rawValue,
      formatLabel: entry.formatLabel,
      detectionMs: entry.detectionMs,
      scannedAt: entry.scannedAt,
      favorite: entry.favorite,
      source: entry.source,
      title: entry.title,
    );
    final int id = await HistoryDb.insert(
      copy,
      limit: settings.historyLimit,
      skipDuplicates: false,
    );
    copy.id = id;
    _bump();
    return copy;
  }

  Future<int> deleteEntries(List<int> ids) async {
    final int n = await HistoryDb.deleteIds(ids);
    _bump();
    return n;
  }

  Future<void> clearAll() async {
    await HistoryDb.clear();
    _bump();
  }

  Future<int> count() => HistoryDb.count();

  void refresh() => _bump();
}

final historyRepositoryProvider =
    NotifierProvider<HistoryRepository, int>(HistoryRepository.new);

/// Current history list for the active query. Re-parsed into full entries.
final historyListProvider = FutureProvider<List<HistoryEntry>>((ref) async {
  ref.watch(historyRepositoryProvider);
  final HistoryQuery q = ref.watch(historyQueryProvider);
  final List<HistoryEntry> rows = await HistoryDb.query(
    search: q.search,
    kind: q.kind == 'favorites' ? null : q.kind,
    favoritesOnly: q.favoritesOnly,
  );
  for (final HistoryEntry e in rows) {
    final ParsedResult p = parseResult(e.rawValue, formatLabel: e.formatLabel);
    e.fields = p.fields;
    e.safetyFlags = p.safetyFlags;
  }
  return rows;
});
