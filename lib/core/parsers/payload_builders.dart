// Pure-Dart payload builders for the Create screen: text, link, vCard,
// mailto, tel, SMS and geo payloads. The Wi-Fi builder lives in
// wifi_parser.dart and is re-exported here so the Create screen has one
// import. Pure Dart: no Flutter imports.

export 'wifi_parser.dart' show buildWifiPayload;

/// Build a plain-text payload.
String buildTextPayload(String text) => text;

/// Build a link payload, prepending `https://` when [url] has no scheme.
String buildLinkPayload(String url) {
  final String trimmed = url.trim();
  if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(trimmed)) {
    return trimmed;
  }
  return 'https://$trimmed';
}

/// Build a vCard 3.0 payload with the given contact fields.
String buildVCard({
  required String name,
  String phone = '',
  String email = '',
  String org = '',
}) {
  final StringBuffer sb = StringBuffer()
    ..writeln('BEGIN:VCARD')
    ..writeln('VERSION:3.0')
    ..writeln('FN:$name');
  if (phone.isNotEmpty) sb.writeln('TEL:$phone');
  if (email.isNotEmpty) sb.writeln('EMAIL:$email');
  if (org.isNotEmpty) sb.writeln('ORG:$org');
  sb.write('END:VCARD');
  return sb.toString();
}

/// Build a `mailto:` URI payload.
String buildMailto({
  required String to,
  String subject = '',
  String body = '',
}) {
  final List<String> params = <String>[];
  if (subject.isNotEmpty) {
    params.add('subject=${Uri.encodeComponent(subject)}');
  }
  if (body.isNotEmpty) {
    params.add('body=${Uri.encodeComponent(body)}');
  }
  final String query = params.isEmpty ? '' : '?${params.join('&')}';
  return 'mailto:$to$query';
}

/// Build a `tel:` URI payload.
String buildTel(String number) => 'tel:$number';

/// Build an `SMSTO:` payload.
String buildSmsto({required String number, String body = ''}) =>
    'SMSTO:$number:$body';

/// Build a `geo:` URI payload, with an optional `?q=` search query.
String buildGeo({
  required double lat,
  required double lng,
  String query = '',
}) {
  final String coords = '$lat,$lng';
  if (query.isEmpty) return 'geo:$coords';
  return 'geo:$coords?q=${Uri.encodeComponent(query)}';
}
