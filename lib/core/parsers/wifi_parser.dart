// Wi-Fi QR payload parsing and building: WIFI:T:..;S:..;P:..;H:..;;
// Pure Dart: no Flutter imports.

import '../models/parsed_result.dart';

/// Try to parse [raw] as a Wi-Fi QR payload.
///
/// Handles escaped `\;`, `\:`, `\,` and `\\` inside values, normalizes the
/// auth type to `'WPA'`, `'WEP'` or `'nopass'` (defaulting to `'nopass'`),
/// and defaults `hidden` to false. Returns null when [raw] is not a `WIFI:`
/// payload or carries no SSID.
ParsedResult? tryParseWifi(String raw) {
  final String trimmed = raw.trim();
  if (!trimmed.toUpperCase().startsWith('WIFI:')) return null;
  final String body = trimmed.substring(5);

  String ssid = '';
  String password = '';
  String auth = 'nopass';
  bool hidden = false;

  for (final String part in _splitFields(body)) {
    if (part.length < 2 || part[1] != ':') continue;
    final String key = part[0].toUpperCase();
    final String value = part.substring(2);
    switch (key) {
      case 'S':
        ssid = value;
      case 'P':
        password = value;
      case 'T':
        auth = _normalizeAuth(value);
      case 'H':
        hidden = value.trim().toLowerCase() == 'true';
    }
  }

  if (ssid.isEmpty) return null;

  return ParsedResult(
    kind: ResultKind.wifi,
    rawValue: raw,
    scannedAt: DateTime.now(),
    fields: <String, String>{
      'ssid': ssid,
      'password': password,
      'auth': auth,
      'hidden': hidden ? 'true' : 'false',
    },
    title: ssid,
  );
}

/// Build a `WIFI:` QR payload string.
///
/// [auth] must be one of `'WPA'`, `'WEP'` or `'nopass'`. Values are escaped
/// (`\`, `;`, `,`, `:`) so the result round-trips through [tryParseWifi].
String buildWifiPayload({
  required String ssid,
  required String password,
  required String auth,
  required bool hidden,
}) {
  final StringBuffer sb = StringBuffer()
    ..write('WIFI:T:')
    ..write(auth)
    ..write(';S:')
    ..write(_escapeWifi(ssid))
    ..write(';P:')
    ..write(_escapeWifi(password))
    ..write(';H:')
    ..write(hidden ? 'true' : 'false')
    ..write(';;');
  return sb.toString();
}

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

/// Escape `\`, `;`, `,` and `:` inside a Wi-Fi field value.
String _escapeWifi(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll(';', r'\;')
    .replaceAll(',', r'\,')
    .replaceAll(':', r'\:');

/// Normalize an auth-type value to `'WPA'`, `'WEP'` or `'nopass'`.
String _normalizeAuth(String value) {
  final String upper = value.trim().toUpperCase();
  if (upper == 'WEP') return 'WEP';
  if (upper == 'NOPASS' || upper.isEmpty) return 'nopass';
  if (upper.startsWith('WPA')) return 'WPA';
  return 'nopass';
}
