// URL detection and safety-flagging for scanned payloads.
// Pure Dart: no Flutter imports.

import '../models/parsed_result.dart';

/// Hosts treated as URL shorteners for the 'shortener' safety flag.
const List<String> kUrlShorteners = <String>[
  'bit.ly',
  'tinyurl.com',
  't.co',
  'goo.gl',
  'ow.ly',
  'is.gd',
  'buff.ly',
  'adf.ly',
  'cutt.ly',
  'rb.gy',
  'shorturl.at',
  'tiny.cc',
];

/// Matches a bare domain like `example.com/path` (no scheme present).
final RegExp _bareDomain = RegExp(
  r'^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?'
  r'(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*'
  r'\.[A-Za-z]{2,}(:\d+)?([/?#][^\s]*)?$',
);

/// Try to parse [raw] as a URL.
///
/// Accepts `http://`, `https://`, `www.` and bare domains such as
/// `example.com/path` (requires a dot plus a TLD-like suffix; strings with
/// whitespace are rejected). Returns null when [raw] does not look like a URL.
ParsedResult? tryParseUrl(String raw) {
  final String candidate = raw.trim();
  if (candidate.isEmpty || candidate.contains(RegExp(r'\s'))) {
    return null;
  }

  final String normalized;
  if (candidate.startsWith(RegExp(r'https?://', caseSensitive: false))) {
    normalized = candidate;
  } else if (candidate.toLowerCase().startsWith('www.')) {
    normalized = 'https://$candidate';
  } else {
    if (!_bareDomain.hasMatch(candidate)) return null;
    normalized = 'https://$candidate';
  }

  final Uri? uri = Uri.tryParse(normalized);
  if (uri == null || uri.host.isEmpty) return null;
  final String host = uri.host.toLowerCase();

  final List<String> flags = <String>[];
  if (_isIpHost(host)) flags.add('ip_host');
  if (_looksPunycode(candidate)) flags.add('punycode');
  if (_isShortener(host)) flags.add('shortener');
  if (uri.scheme == 'http') flags.add('http');
  if (normalized.length > 200) flags.add('long_url');

  return ParsedResult(
    kind: ResultKind.url,
    rawValue: raw,
    scannedAt: DateTime.now(),
    fields: <String, String>{'url': normalized, 'domain': host},
    safetyFlags: flags,
    title: host,
  );
}

/// True when [host] is an IPv4 or IPv6 literal (brackets stripped by [Uri]).
bool _isIpHost(String host) {
  if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host)) return true;
  return host.contains(':');
}

/// True when [candidate] contains a punycode (`xn--`) or non-ASCII host.
bool _looksPunycode(String candidate) {
  if (candidate.toLowerCase().contains('xn--')) return true;
  return candidate.runes.any((int rune) => rune > 127);
}

/// True when [host] is a known URL shortener or a subdomain of one.
bool _isShortener(String host) => kUrlShorteners
    .any((String shortener) => host == shortener || host.endsWith('.$shortener'));
