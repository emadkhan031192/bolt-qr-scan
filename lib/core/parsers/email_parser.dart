// mailto: and MATMSG: email payload parsing.
// Pure Dart: no Flutter imports.

import '../models/parsed_result.dart';

/// Try to parse [raw] as an email payload.
///
/// Accepts `mailto:to?subject=..&body=..` and
/// `MATMSG:TO:..;SUB:..;BODY:..;;`. Returns null for anything else.
ParsedResult? tryParseEmail(String raw) {
  final String trimmed = raw.trim();
  final String upper = trimmed.toUpperCase();
  if (upper.startsWith('MAILTO:')) {
    return _parseMailto(raw, trimmed);
  }
  if (upper.startsWith('MATMSG:')) {
    return _parseMatmsg(raw, trimmed);
  }
  return null;
}

/// Parse a `mailto:` URI.
ParsedResult? _parseMailto(String raw, String trimmed) {
  final Uri? uri = Uri.tryParse(trimmed);
  if (uri == null || uri.scheme.toLowerCase() != 'mailto') return null;
  final String to = uri.path.trim();
  if (to.isEmpty) return null;
  return _build(
    raw,
    to,
    uri.queryParameters['subject'] ?? '',
    uri.queryParameters['body'] ?? '',
  );
}

/// Parse a `MATMSG:TO:..;SUB:..;BODY:..;;` payload.
ParsedResult? _parseMatmsg(String raw, String trimmed) {
  final String body = trimmed.substring(7); // after 'MATMSG:'
  String to = '';
  String subject = '';
  String msgBody = '';
  for (final String part in _splitFields(body)) {
    final int colon = part.indexOf(':');
    if (colon == -1) continue;
    final String key = part.substring(0, colon).trim().toUpperCase();
    final String value = part.substring(colon + 1);
    switch (key) {
      case 'TO':
        if (to.isEmpty) to = value;
      case 'SUB':
        if (subject.isEmpty) subject = value;
      case 'BODY':
        if (msgBody.isEmpty) msgBody = value;
    }
  }
  if (to.isEmpty) return null;
  return _build(raw, to, subject, msgBody);
}

/// Build the shared email [ParsedResult].
ParsedResult _build(String raw, String to, String subject, String body) =>
    ParsedResult(
      kind: ResultKind.email,
      rawValue: raw,
      scannedAt: DateTime.now(),
      fields: <String, String>{
        'to': to,
        'subject': subject,
        'body': body,
      },
      title: to,
    );

/// Split a `;`-separated field list, honoring `\` escapes.
List<String> _splitFields(String body) {
  final List<String> parts = <String>[];
  final StringBuffer current = StringBuffer();
  bool escaped = false;
  for (int i = 0; i < body.length; i++) {
    final String ch = body[i];
    if (escaped) {
      current.write(ch);
      escaped = false;
    } else if (ch == r'\') {
      escaped = true;
    } else if (ch == ';') {
      parts.add(current.toString());
      current.clear();
    } else {
      current.write(ch);
    }
  }
  parts.add(current.toString());
  return parts;
}
