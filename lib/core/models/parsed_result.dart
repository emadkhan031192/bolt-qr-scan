// Pure-Dart models shared by parsers, history DB and the UI.
// No Flutter imports here so unit tests stay fast and hermetic.

/// The smart result type detected from a scanned payload.
enum ResultKind {
  url,
  wifi,
  contact,
  email,
  phone,
  sms,
  geo,
  event,
  product,
  text,
}

/// The outcome of parsing one scanned raw value.
class ParsedResult {
  const ParsedResult({
    required this.kind,
    required this.rawValue,
    this.formatLabel = '',
    this.detectionMs = 0,
    required this.scannedAt,
    this.fields = const <String, String>{},
    this.safetyFlags = const <String>[],
    this.title,
  });

  final ResultKind kind;
  final String rawValue;
  final String formatLabel;
  final int detectionMs;
  final DateTime scannedAt;

  /// Type-specific key/value detail rows (ssid, gs1Country, ...).
  final Map<String, String> fields;

  /// URL safety flags, e.g. 'ip_host', 'punycode', 'shortener', 'http', 'long_url'.
  final List<String> safetyFlags;

  /// Human title: domain for URLs, SSID for Wi-Fi, name for contacts, ...
  final String? title;

  ParsedResult copyWith({
    ResultKind? kind,
    String? rawValue,
    String? formatLabel,
    int? detectionMs,
    DateTime? scannedAt,
    Map<String, String>? fields,
    List<String>? safetyFlags,
    String? title,
  }) =>
      ParsedResult(
        kind: kind ?? this.kind,
        rawValue: rawValue ?? this.rawValue,
        formatLabel: formatLabel ?? this.formatLabel,
        detectionMs: detectionMs ?? this.detectionMs,
        scannedAt: scannedAt ?? this.scannedAt,
        fields: fields ?? this.fields,
        safetyFlags: safetyFlags ?? this.safetyFlags,
        title: title ?? this.title,
      );
}

/// A history row, mirroring the sqflite `scans` table.
class HistoryEntry {
  HistoryEntry({
    this.id,
    required this.kind,
    required this.rawValue,
    this.formatLabel = '',
    this.detectionMs = 0,
    required this.scannedAt,
    this.favorite = false,
    this.source = 'scanned',
    this.fields = const <String, String>{},
    this.safetyFlags = const <String>[],
    this.title,
  });

  int? id;
  ResultKind kind;
  String rawValue;
  String formatLabel;
  int detectionMs;
  DateTime scannedAt;
  bool favorite;

  /// 'scanned' | 'created'
  String source;
  Map<String, String> fields;
  List<String> safetyFlags;
  String? title;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'raw_value': rawValue,
        'kind': kind.name,
        'format_label': formatLabel,
        'detection_ms': detectionMs,
        'scanned_at': scannedAt.millisecondsSinceEpoch,
        'favorite': favorite ? 1 : 0,
        'source': source,
        'title': title,
      };

  static HistoryEntry fromMap(Map<String, Object?> map) => HistoryEntry(
        id: map['id'] as int?,
        rawValue: (map['raw_value'] as String?) ?? '',
        kind: ResultKind.values.firstWhere(
          (ResultKind k) => k.name == (map['kind'] as String?),
          orElse: () => ResultKind.text,
        ),
        formatLabel: (map['format_label'] as String?) ?? '',
        detectionMs: (map['detection_ms'] as int?) ?? 0,
        scannedAt: DateTime.fromMillisecondsSinceEpoch(
          (map['scanned_at'] as int?) ?? 0,
        ),
        favorite: ((map['favorite'] as int?) ?? 0) == 1,
        source: (map['source'] as String?) ?? 'scanned',
        title: map['title'] as String?,
      );

  ParsedResult toParsed() => ParsedResult(
        kind: kind,
        rawValue: rawValue,
        formatLabel: formatLabel,
        detectionMs: detectionMs,
        scannedAt: scannedAt,
        fields: fields,
        safetyFlags: safetyFlags,
        title: title,
      );
}
