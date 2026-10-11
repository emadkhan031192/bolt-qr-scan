// iCalendar VEVENT parsing.
// Pure Dart: no Flutter imports.

import '../models/parsed_result.dart';

/// Try to parse [raw] as an iCalendar `VEVENT`.
///
/// Reads `SUMMARY`, `LOCATION`, `DESCRIPTION`, `DTSTART` and `DTEND`, and
/// converts date values given as `YYYYMMDDTHHMMSSZ`, `YYYYMMDDTHHMMSS` or
/// `YYYYMMDD` into ISO-8601 strings. Returns null when [raw] is not a
/// VEVENT or carries no SUMMARY.
ParsedResult? tryParseEvent(String raw) {
  final String trimmed = raw.trimLeft();
  if (!trimmed.toUpperCase().startsWith('BEGIN:VEVENT')) return null;

  String summary = '';
  String location = '';
  String description = '';
  String dtstart = '';
  String dtend = '';

  for (final String line in _unfoldLines(trimmed)) {
    final int colon = line.indexOf(':');
    if (colon == -1) continue;
    final String key =
        line.substring(0, colon).split(';')[0].trim().toUpperCase();
    final String value = line.substring(colon + 1).trim();
    switch (key) {
      case 'SUMMARY':
        if (summary.isEmpty) summary = value;
      case 'LOCATION':
        if (location.isEmpty) location = value;
      case 'DESCRIPTION':
        if (description.isEmpty) {
          description = value.replaceAll(r'\n', '\n').replaceAll(r'\N', '\n');
        }
      case 'DTSTART':
        if (dtstart.isEmpty) dtstart = _toIso8601(value);
      case 'DTEND':
        if (dtend.isEmpty) dtend = _toIso8601(value);
    }
  }

  if (summary.isEmpty) return null;

  return ParsedResult(
    kind: ResultKind.event,
    rawValue: raw,
    scannedAt: DateTime.now(),
    fields: <String, String>{
      'summary': summary,
      'location': location,
      'description': description,
      'dtstart': dtstart,
      'dtend': dtend,
    },
    title: summary,
  );
}

/// Convert an iCalendar date/time value to an ISO-8601 string.
///
/// Accepts `YYYYMMDDTHHMMSSZ`, `YYYYMMDDTHHMMSS` and `YYYYMMDD`.
/// Returns `''` when the value cannot be parsed.
String _toIso8601(String value) {
  final String v = value.trim();
  final RegExpMatch? dateTime =
      RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(Z?)$')
          .firstMatch(v);
  if (dateTime != null) {
    final int month = int.parse(dateTime.group(2)!);
    final int day = int.parse(dateTime.group(3)!);
    final int hour = int.parse(dateTime.group(4)!);
    final int minute = int.parse(dateTime.group(5)!);
    final int second = int.parse(dateTime.group(6)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return '';
    if (hour > 23 || minute > 59 || second > 59) return '';
    final String iso = '${dateTime.group(1)}-${dateTime.group(2)}-'
        '${dateTime.group(3)}T${dateTime.group(4)}:'
        '${dateTime.group(5)}:${dateTime.group(6)}';
    return dateTime.group(7) == 'Z' ? '${iso}Z' : iso;
  }
  final RegExpMatch? dateOnly =
      RegExp(r'^(\d{4})(\d{2})(\d{2})$').firstMatch(v);
  if (dateOnly != null) {
    final int month = int.parse(dateOnly.group(2)!);
    final int day = int.parse(dateOnly.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return '';
    return '${dateOnly.group(1)}-${dateOnly.group(2)}-${dateOnly.group(3)}';
  }
  return '';
}

/// Unfold continuation lines (a line starting with space/tab continues the
/// previous line, per RFC 5545).
List<String> _unfoldLines(String text) {
  final List<String> out = <String>[];
  for (final String line in text.split(RegExp(r'\r\n|\r|\n'))) {
    if (line.isEmpty) continue;
    if ((line.startsWith(' ') || line.startsWith('\t')) && out.isNotEmpty) {
      out[out.length - 1] = out.last + line.substring(1);
    } else {
      out.add(line);
    }
  }
  return out;
}
