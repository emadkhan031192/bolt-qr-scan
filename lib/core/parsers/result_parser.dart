// Central dispatcher: turns a raw scanned string into a ParsedResult.
// Each tryParse* lives in its own module (implemented by the core-parsers
// worker); this file only decides precedence. Pure Dart, no Flutter imports.
//
// Detection-time note (performance contract): mobile_scanner does not expose
// per-frame timestamps, so the scan screen measures real elapsed time from the
// scan-session start (controller start/resume/mode change/sheet dismiss) to
// the first onDetect callback, passes it as [detectionMs], and displays
// "Detected in X.XX s". That is the value shown in the UI.
import '../models/parsed_result.dart';
import 'barcode_validator.dart';
import 'contact_parser.dart';
import 'email_parser.dart';
import 'event_parser.dart';
import 'geo_parser.dart';
import 'phone_parser.dart';
import 'sms_parser.dart';
import 'url_parser.dart';
import 'wifi_parser.dart';

/// Maximum payload length kept verbatim; longer payloads are truncated for
/// display safety (very large or non-UTF8 payloads are shown as trimmed text).
const int kMaxPayloadChars = 4096;

/// Parse [raw] into a typed [ParsedResult]. Never returns null: unmatched
/// input becomes [ResultKind.text].
ParsedResult parseResult(
  String raw, {
  String formatLabel = '',
  int detectionMs = 0,
}) {
  final String safe = _sanitize(raw);
  final DateTime now = DateTime.now();

  ParsedResult base(ParsedResult p) => p.copyWith(
        rawValue: safe,
        formatLabel: formatLabel,
        detectionMs: detectionMs,
        scannedAt: now,
      );

  final ParsedResult? wifi = tryParseWifi(safe);
  if (wifi != null) return base(wifi);
  final ParsedResult? contact = tryParseContact(safe);
  if (contact != null) return base(contact);
  final ParsedResult? email = tryParseEmail(safe);
  if (email != null) return base(email);
  final ParsedResult? sms = tryParseSms(safe);
  if (sms != null) return base(sms);
  final ParsedResult? phone = tryParsePhone(safe);
  if (phone != null) return base(phone);
  final ParsedResult? geo = tryParseGeo(safe);
  if (geo != null) return base(geo);
  final ParsedResult? event = tryParseEvent(safe);
  if (event != null) return base(event);
  final ParsedResult? url = tryParseUrl(safe);
  if (url != null) return base(url);
  final ParsedResult? product = tryParseProduct(safe, formatLabel);
  if (product != null) return base(product);

  return ParsedResult(
    kind: ResultKind.text,
    rawValue: safe,
    formatLabel: formatLabel,
    detectionMs: detectionMs,
    scannedAt: now,
    title: _shortTitle(safe),
  );
}

/// Strip invalid characters and cap length so damaged/huge payloads cannot
/// break the UI or the database.
String _sanitize(String raw) {
  final StringBuffer out = StringBuffer();
  for (final int rune in raw.runes) {
    if (rune == 0xFFFD) continue; // replacement char from bad decoding
    if (rune < 0x20 && rune != 0x0A && rune != 0x0D && rune != 0x09) continue;
    out.writeCharCode(rune);
  }
  final String cleaned = out.toString();
  if (cleaned.length > kMaxPayloadChars) {
    return '${cleaned.substring(0, kMaxPayloadChars)}…';
  }
  return cleaned;
}

String _shortTitle(String raw) {
  final String oneLine = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  return oneLine.length > 48 ? '${oneLine.substring(0, 48)}…' : oneLine;
}
