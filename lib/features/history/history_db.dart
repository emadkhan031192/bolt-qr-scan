// sqflite database for scan history. Opened lazily in the background so
// the first camera frame is never blocked. Table `scans` with indexes on
// scanned_at and kind. Fields/safety flags are re-derived by the parser on
// read, so they are NOT stored (keeps rows small and schema stable).
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/models/parsed_result.dart';

class HistoryDb {
  HistoryDb._();

  static const String table = 'scans';
  static Database? _db;

  /// Exposed for tests (sqflite_common_ffi) — a custom factory + directory.
  static DatabaseFactory? testFactory;
  static String? testDir;

  static Future<Database> database() async {
    final Database? existing = _db;
    if (existing != null) return existing;
    final DatabaseFactory factory = testFactory ?? databaseFactory;
    final String dir = testDir ?? (await getApplicationDocumentsDirectory()).path;
    final String path = p.join(dir, 'bolt_history.db');
    _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE $table(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              raw_value TEXT NOT NULL,
              kind TEXT NOT NULL,
              format_label TEXT NOT NULL DEFAULT '',
              detection_ms INTEGER NOT NULL DEFAULT 0,
              scanned_at INTEGER NOT NULL,
              favorite INTEGER NOT NULL DEFAULT 0,
              source TEXT NOT NULL DEFAULT 'scanned',
              title TEXT
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_scans_time ON $table(scanned_at DESC)',
          );
          await db.execute('CREATE INDEX idx_scans_kind ON $table(kind)');
        },
      ),
    );
    return _db!;
  }

  /// Insert [entry] and return its row id. Prunes oldest rows beyond [limit]
  /// (0 = unlimited). When [skipDuplicates] is true and an identical
  /// raw_value exists, returns -1 without inserting.
  static Future<int> insert(
    HistoryEntry entry, {
    int limit = 500,
    bool skipDuplicates = true,
  }) async {
    final Database db = await database();
    if (skipDuplicates) {
      final List<Map<String, Object?>> dup = await db.query(
        table,
        columns: const ['id'],
        where: 'raw_value = ?',
        whereArgs: [entry.rawValue],
        limit: 1,
      );
      if (dup.isNotEmpty) return -1;
    }
    final int id = await db.insert(table, entry.toMap()..remove('id'));
    if (limit > 0) {
      await db.execute('''
        DELETE FROM $table WHERE id NOT IN (
          SELECT id FROM $table ORDER BY scanned_at DESC LIMIT ?
        )
      ''', [limit]);
    }
    return id;
  }

  static Future<List<HistoryEntry>> query({
    String? search,
    String? kind,
    bool? favoritesOnly,
    int? limit,
  }) async {
    final Database db = await database();
    final List<String> where = <String>[];
    final List<Object?> args = <Object?>[];
    if (search != null && search.trim().isNotEmpty) {
      where.add('(raw_value LIKE ? OR title LIKE ?)');
      final String q = '%${search.trim()}%';
      args.addAll(<Object?>[q, q]);
    }
    if (kind != null && kind != 'all') {
      where.add('kind = ?');
      args.add(kind);
    }
    if (favoritesOnly == true) {
      where.add('favorite = 1');
    }
    final List<Map<String, Object?>> rows = await db.query(
      table,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'scanned_at DESC',
      limit: limit,
    );
    return rows.map(HistoryEntry.fromMap).toList();
  }

  static Future<void> setFavorite(int id, bool favorite) async {
    final Database db = await database();
    await db.update(
      table,
      <String, Object?>{'favorite': favorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> delete(int id) async {
    final Database db = await database();
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteIds(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final Database db = await database();
    return db.delete(
      table,
      where: 'id IN (${List<String>.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }

  static Future<void> clear() async {
    final Database db = await database();
    await db.delete(table);
  }

  static Future<int> count() async {
    final Database db = await database();
    final List<Map<String, Object?>> rows =
        await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
    return (rows.first['c'] as int?) ?? 0;
  }

  /// Close the cached database handle (used by tests; app keeps it open).
  static Future<void> closeForTest() async {
    await _db?.close();
    _db = null;
  }
}
