// SMSTO: / sms: payload parsing.
// Pure Dart: no Flutter imports.

import '../models/parsed_result.dart';

/// Try to parse [raw] as an SMS payload.
///
/// Accepts `SMSTO:number:body` (any case) and `sms:number?body=..`.
/// Returns null for anything else.
ParsedResult? tryParseSms(String raw) {
  final String trimmed = raw.trim();
  final String upper = trimmed.toUpperCase();
  if (upper.startsWith('SMSTO:')) {
    final String rest = trimmed.substring(6);
    final int colon = rest.indexOf(':');
    final String number =
        (colon == -1 ? rest : rest.substring(0, colon)).trim();
    final String body = colon == -1 ? '' : rest.substring(colon + 1);
    if (number.isEmpty) return null;
    return _build(raw, number, body);
  }
  if (upper.startsWith('SMS:')) {
    final String rest = trimmed.substring(4);
    final int query = rest.indexOf('?');
    final String number =
        (query == -1 ? rest : rest.substring(0, query)).trim();
    if (number.isEmpty) return null;
    return _build(raw, number, _bodyParam(query == -1 ? '' : rest.substring(query + 1)));
  }
  return null;
}

/// Extract and decode the `body=` parameter from an sms: query string.
String _bodyParam(String query) {
  for (final String pair in query.split('&')) {
    final int eq = pair.indexOf('=');
    final String key = (eq == -1 ? pair : pair.substring(0, eq)).toLowerCase();
    if (key == 'body') {
      return Uri.decodeComponent(eq == -1 ? '' : pair.substring(eq + 1));
    }
  }
  return '';
}

/// Build the shared SMS [ParsedResult].
ParsedResult _build(String raw, String number, String body) => ParsedResult(
      kind: ResultKind.sms,
      rawValue: raw,
      scannedAt: DateTime.now(),
      fields: <String, String>{'number': number, 'body': body},
      title: number,
    );
