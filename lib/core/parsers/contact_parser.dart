// vCard 3.0 and MECARD contact parsing.
// Pure Dart: no Flutter imports.

import '../models/parsed_result.dart';

/// Try to parse [raw] as a contact.
///
/// Accepts vCard 3.0 (`BEGIN:VCARD ... END:VCARD`, reading `FN:` — falling
/// back to `N:` as "given family" — plus `TEL:`, `EMAIL:`, `ORG:`, `NOTE:`)
/// and MECARD (`MECARD:N:name;TEL:..;EMAIL:..;ORG:..;;`). Returns null for
/// anything else.
ParsedResult? tryParseContact(String raw) {
  final String trimmed = raw.trimLeft();
  final String upper = trimmed.toUpperCase();
  if (upper.startsWith('BEGIN:VCARD')) {
    return _parseVCard(raw, trimmed);
  }
  if (upper.startsWith('MECARD:')) {
    return _parseMecard(raw, trimmed);
  }
  return null;
}

/// Parse a vCard payload.
ParsedResult? _parseVCard(String raw, String trimmed) {
  String name = '';
  String phone = '';
  String email = '';
  String org = '';
  String note = '';
  String nField = '';

  for (final String line in _unfoldLines(trimmed)) {
    final int colon = line.indexOf(':');
    if (colon == -1) continue;
    final String key =
        line.substring(0, colon).split(';')[0].trim().toUpperCase();
    final String value = _unescapeVCard(line.substring(colon + 1).trim());
    switch (key) {
      case 'FN':
        if (name.isEmpty) name = value;
      case 'N':
        if (nField.isEmpty) nField = value;
      case 'TEL':
        if (phone.isEmpty) phone = value;
      case 'EMAIL':
        if (email.isEmpty) email = value;
      case 'ORG':
        if (org.isEmpty) org = value;
      case 'NOTE':
        if (note.isEmpty) note = value;
    }
  }

  if (name.isEmpty && nField.isNotEmpty) {
    name = _nameFromN(nField);
  }
  if (name.isEmpty && phone.isEmpty && email.isEmpty) return null;

  return ParsedResult(
    kind: ResultKind.contact,
    rawValue: raw,
    scannedAt: DateTime.now(),
    fields: <String, String>{
      'name': name,
      'phone': phone,
      'email': email,
      'org': org,
      'note': note,
    },
    title: name.isEmpty ? phone : name,
  );
}

/// Parse a MECARD payload (`MECARD:N:name;TEL:..;EMAIL:..;ORG:..;;`).
ParsedResult? _parseMecard(String raw, String trimmed) {
  final String body = trimmed.substring(7); // after 'MECARD:'
  String name = '';
  String phone = '';
  String email = '';
  String org = '';
  String note = '';

  for (final String part in _splitFields(body)) {
    final int colon = part.indexOf(':');
    if (colon == -1) continue;
    final String key = part.substring(0, colon).trim().toUpperCase();
    final String value = part.substring(colon + 1);
    switch (key) {
      case 'N':
        if (name.isEmpty) name = value;
      case 'TEL':
        if (phone.isEmpty) phone = value;
      case 'EMAIL':
        if (email.isEmpty) email = value;
      case 'ORG':
        if (org.isEmpty) org = value;
      case 'NOTE':
        if (note.isEmpty) note = value;
    }
  }

  if (name.isEmpty && phone.isEmpty && email.isEmpty && org.isEmpty) {
    return null;
  }

  return ParsedResult(
    kind: ResultKind.contact,
    rawValue: raw,
    scannedAt: DateTime.now(),
    fields: <String, String>{
      'name': name,
      'phone': phone,
      'email': email,
      'org': org,
      'note': note,
    },
    title: name.isEmpty ? phone : name,
  );
}

/// Build a display name from an `N:` field (`family;given;...`).
String _nameFromN(String nField) {
  final List<String> parts = nField.split(';');
  final String family = parts.isNotEmpty ? parts[0].trim() : '';
  final String given = parts.length > 1 ? parts[1].trim() : '';
  if (given.isEmpty) return family;
  if (family.isEmpty) return given;
  return '$given $family';
}

/// Unfold continuation lines (a line starting with space/tab continues the
/// previous line, per RFC 2426 / RFC 5545).
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

/// Unescape vCard text escapes (`\;`, `\,`, `\\`, `\n`).
String _unescapeVCard(String value) => value
    .replaceAll(RegExp(r'\\[nN]'), ' ')
    .replaceAll(r'\,', ',')
    .replaceAll(r'\;', ';')
    .replaceAll(r'\\', r'\');

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
