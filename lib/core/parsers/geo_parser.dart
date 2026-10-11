// geo: URI parsing: geo:lat,lng[,zoom][?q=query].
// Pure Dart: no Flutter imports.

import '../models/parsed_result.dart';

/// Matches `geo:lat,lng` with an optional zoom and query string.
final RegExp _geoPattern = RegExp(
  r'^geo:(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)'
  r'(?:,-?\d+(?:\.\d+)?)?(?:\?(.*))?$',
  caseSensitive: false,
);

/// Try to parse [raw] as a `geo:` URI.
///
/// Returns null for anything else or for out-of-range coordinates
/// (latitude -90..90, longitude -180..180).
ParsedResult? tryParseGeo(String raw) {
  final RegExpMatch? match = _geoPattern.firstMatch(raw.trim());
  if (match == null) return null;
  final String latText = match.group(1)!;
  final String lngText = match.group(2)!;
  final double? lat = double.tryParse(latText);
  final double? lng = double.tryParse(lngText);
  if (lat == null || lng == null) return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;

  String query = '';
  final String? queryString = match.group(3);
  if (queryString != null && queryString.isNotEmpty) {
    for (final String pair in queryString.split('&')) {
      final int eq = pair.indexOf('=');
      final String key =
          (eq == -1 ? pair : pair.substring(0, eq)).toLowerCase();
      if (key == 'q') {
        query = Uri.decodeComponent(eq == -1 ? '' : pair.substring(eq + 1));
        break;
      }
    }
  }

  return ParsedResult(
    kind: ResultKind.geo,
    rawValue: raw,
    scannedAt: DateTime.now(),
    fields: <String, String>{
      'lat': latText,
      'lng': lngText,
      'query': query,
    },
    title: query.isEmpty ? '$latText,$lngText' : query,
  );
}
