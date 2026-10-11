// CSV / JSON export and JSON backup import for scan history.
// Signatures are a cross-worker contract (imported by the create/share
// worker) — do not rename them.
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/parsed_result.dart';
import '../settings/settings_model.dart';
import 'history_db.dart';
import 'history_repository.dart';

/// Timestamp used in export file names.
String _stamp() => DateTime.now().millisecondsSinceEpoch.toString();

/// Export [entries] as CSV with header
/// `time_iso,kind,format,detection_ms,favorite,source,value`.
///
/// Writes to `getTemporaryDirectory()/bolt_history_<ts>.csv` and returns the
/// file as an [XFile], or null when the export fails.
Future<XFile?> exportHistoryCsv(List<HistoryEntry> entries) async {
  try {
    final List<List<dynamic>> rows = <List<dynamic>>[
      const <Object?>[
        'time_iso',
        'kind',
        'format',
        'detection_ms',
        'favorite',
        'source',
        'value',
      ],
      for (final HistoryEntry e in entries)
        <Object?>[
          e.scannedAt.toIso8601String(),
          e.kind.name,
          e.formatLabel,
          e.detectionMs,
          e.favorite,
          e.source,
          e.rawValue,
        ],
    ];
    // csv 8.x API: the default `csv` instance encodes rows to a string.
    final String csvText = csv.encode(rows);
    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}/bolt_history_${_stamp()}.csv');
    await file.writeAsString(csvText);
    return XFile(file.path);
  } catch (_) {
    return null;
  }
}

/// Export [entries] as a JSON array of objects with keys `raw_value`, `kind`,
/// `format_label`, `detection_ms`, `scanned_at` (ms epoch), `favorite` (bool),
/// `source` and `title`.
///
/// Writes to `getTemporaryDirectory()/bolt_history_<ts>.json` and returns the
/// file as an [XFile], or null when the export fails.
Future<XFile?> exportHistoryJson(List<HistoryEntry> entries) async {
  try {
    final List<Map<String, Object?>> docs = <Map<String, Object?>>[
      for (final HistoryEntry e in entries)
        <String, Object?>{
          'raw_value': e.rawValue,
          'kind': e.kind.name,
          'format_label': e.formatLabel,
          'detection_ms': e.detectionMs,
          'scanned_at': e.scannedAt.millisecondsSinceEpoch,
          'favorite': e.favorite,
          'source': e.source,
          'title': e.title,
        },
    ];
    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}/bolt_history_${_stamp()}.json');
    await file.writeAsString(jsonEncode(docs));
    return XFile(file.path);
  } catch (_) {
    return null;
  }
}

/// Query the full history (newest first) and export it as CSV.
Future<XFile?> exportAllCsv(WidgetRef ref) async {
  final List<HistoryEntry> entries = await HistoryDb.query();
  return exportHistoryCsv(entries);
}

/// Query the full history (newest first) and export it as JSON.
Future<XFile?> exportAllJson(WidgetRef ref) async {
  final List<HistoryEntry> entries = await HistoryDb.query();
  return exportHistoryJson(entries);
}

/// Import a JSON backup file produced by [exportHistoryJson] at [path].
///
/// Returns the number of rows inserted. History-limit pruning applies;
/// duplicates are kept (backups are restored verbatim). Throws
/// [FormatException] when the file cannot be read or is not a valid backup.
Future<int> importBackupFile(WidgetRef ref, String path) async {
  final String raw;
  try {
    raw = await File(path).readAsString();
  } catch (e) {
    throw FormatException('Could not read backup file: $e');
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (e) {
    throw FormatException('Invalid backup JSON: ${e.message}');
  }
  if (decoded is! List<Object?>) {
    throw const FormatException('Backup must be a JSON array');
  }
  final SettingsModel settings = ref.read(settingsProvider);
  int inserted = 0;
  for (final Object? item in decoded) {
    if (item is! Map<String, Object?>) {
      throw const FormatException('Backup entry must be an object');
    }
    final HistoryEntry entry = _entryFromBackup(item);
    final int id = await HistoryDb.insert(
      entry,
      limit: settings.historyLimit,
      skipDuplicates: false,
    );
    if (id >= 0) inserted++;
  }
  ref.read(historyRepositoryProvider.notifier).refresh();
  return inserted;
}

/// Build a [HistoryEntry] from one decoded backup object.
/// Throws [FormatException] when required data is missing or mistyped.
HistoryEntry _entryFromBackup(Map<String, Object?> map) {
  final String? rawValue = map['raw_value'] as String?;
  if (rawValue == null) {
    throw const FormatException('Backup entry is missing raw_value');
  }
  final String kindName = (map['kind'] as String?) ?? 'text';
  final ResultKind kind = ResultKind.values.firstWhere(
    (ResultKind k) => k.name == kindName,
    orElse: () => ResultKind.text,
  );
  final Object? scannedAtRaw = map['scanned_at'];
  final DateTime scannedAt = switch (scannedAtRaw) {
    int ms => DateTime.fromMillisecondsSinceEpoch(ms),
    String iso => DateTime.tryParse(iso) ?? DateTime.now(),
    _ => DateTime.now(),
  };
  final Object? favoriteRaw = map['favorite'];
  return HistoryEntry(
    kind: kind,
    rawValue: rawValue,
    formatLabel: (map['format_label'] as String?) ?? '',
    detectionMs: (map['detection_ms'] as num?)?.toInt() ?? 0,
    scannedAt: scannedAt,
    favorite: favoriteRaw == true || favoriteRaw == 1,
    source: (map['source'] as String?) ?? 'scanned',
    title: map['title'] as String?,
  );
}
