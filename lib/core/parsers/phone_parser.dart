// tel: URI phone-number parsing.
// Pure Dart: no Flutter imports.

import '../models/parsed_result.dart';

/// Matches `tel:` / `tel://` URIs (case-insensitive scheme).
final RegExp _telPattern = RegExp(r'^tel:(//)?([^;?]+)$', caseSensitive: false);

/// Try to parse [raw] as a `tel:` URI (`tel:+123456`, `tel://+123456`).
/// Returns null when [raw] is not a tel: URI or carries no digits.
ParsedResult? tryParsePhone(String raw) {
  final RegExpMatch? match = _telPattern.firstMatch(raw.trim());
  if (match == null) return null;
  final String number = (match.group(2) ?? '').trim();
  if (!RegExp(r'\d').hasMatch(number)) return null;
  return ParsedResult(
    kind: ResultKind.phone,
    rawValue: raw,
    scannedAt: DateTime.now(),
    fields: <String, String>{'number': number},
    title: number,
  );
}
