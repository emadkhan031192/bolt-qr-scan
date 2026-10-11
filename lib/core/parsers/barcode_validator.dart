// EAN/UPC/ISBN validation, UPC-E expansion, barcode digit grouping and
// product-barcode parsing.
// Pure Dart: no Flutter imports.

import '../models/parsed_result.dart';
import 'gs1_prefixes.dart';

/// True when [d] is exactly 13 digits with a valid EAN-13 check digit.
bool isValidEan13(String d) {
  if (d.length != 13 || !_isDigits(d)) return false;
  return _eanCheckDigit(d.substring(0, 12)) == _digitAt(d, 12);
}

/// True when [d] is exactly 8 digits with a valid EAN-8 check digit.
bool isValidEan8(String d) {
  if (d.length != 8 || !_isDigits(d)) return false;
  int sum = 0;
  for (int i = 0; i < 7; i++) {
    sum += _digitAt(d, i) * (i.isEven ? 3 : 1);
  }
  return (10 - (sum % 10)) % 10 == _digitAt(d, 7);
}

/// True when [d] is exactly 12 digits with a valid UPC-A check digit.
bool isValidUpcA(String d) {
  if (d.length != 12 || !_isDigits(d)) return false;
  return isValidEan13('0$d');
}

/// Expand a UPC-E code to its 12-digit UPC-A form (with check digit).
///
/// Accepts the 6-digit core, or 8 digits including the number-system and
/// check digits (the supplied check digit is ignored and recomputed).
/// Throws [ArgumentError] for anything else.
String upcEToUpcA(String upce) {
  final String d = upce.trim();
  if (!_isDigits(d) || (d.length != 6 && d.length != 8)) {
    throw ArgumentError('UPC-E must be 6 or 8 digits: $upce');
  }
  final String numberSystem = d.length == 8 ? d[0] : '0';
  final String core = d.length == 8 ? d.substring(1, 7) : d;
  final String e1 = core[0];
  final String e2 = core[1];
  final String e3 = core[2];
  final String e4 = core[3];
  final String e5 = core[4];
  final String e6 = core[5];

  final String middle;
  if (e6 == '0' || e6 == '1' || e6 == '2') {
    middle = '$e1$e2$e6' '0000' '$e3$e4$e5';
  } else if (e6 == '3') {
    middle = '$e1$e2$e3' '00000' '$e4$e5';
  } else if (e6 == '4') {
    middle = '$e1$e2$e3$e4' '00000' '$e5';
  } else {
    middle = '$e1$e2$e3$e4$e5' '0000' '$e6';
  }

  final String first11 = '$numberSystem$middle';
  // The UPC-A check digit equals the EAN-13 check digit of the 12-digit
  // form ('0' + first11): weights are 3,1,3... from the left over first11.
  return '$first11${_eanCheckDigit('0$first11')}';
}

/// True when [d] looks like an ISBN: 13 digits starting with 978/979 and a
/// valid check digit, or 10 characters (digits with an optional trailing X)
/// with a valid ISBN-10 check.
bool looksLikeIsbn(String d) {
  final String s = d.trim().toUpperCase();
  if (s.length == 13) {
    if (!RegExp(r'^\d{13}$').hasMatch(s)) return false;
    if (!s.startsWith('978') && !s.startsWith('979')) return false;
    return isValidEan13(s);
  }
  if (s.length == 10) {
    if (!RegExp(r'^\d{9}[\dX]$').hasMatch(s)) return false;
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += _digitAt(s, i) * (10 - i);
    }
    final int check = s[9] == 'X' ? 10 : _digitAt(s, 9);
    return (sum + check) % 11 == 0;
  }
  return false;
}

/// Group barcode digits for display, e.g. `9691234567890` ->
/// `9 691234 567890`. Unsupported lengths are returned unchanged.
String groupBarcodeDigits(String d) {
  final String digits = d.trim();
  if (digits.length == 8 && _isDigits(digits)) {
    return '${digits.substring(0, 4)} ${digits.substring(4)}';
  }
  if ((digits.length == 12 || digits.length == 13) && _isDigits(digits)) {
    return '${digits[0]} '
        '${digits.substring(1, digits.length - 6)} '
        '${digits.substring(digits.length - 6)}';
  }
  return digits;
}

/// Try to parse [raw] as a product barcode.
///
/// Strips spaces and dashes, then accepts digit strings of length 6
/// (UPC-E), 8 (EAN-8), 10 (ISBN-10, must be check-valid), 12 (UPC-A) or 13
/// (EAN-13, or ISBN-13 when it starts with 978/979 and is check-valid).
/// [formatLabel] is recorded on the result but does not change detection.
ParsedResult? tryParseProduct(String raw, String formatLabel) {
  final String digits = raw.replaceAll(RegExp(r'[\s-]'), '');
  if (digits.isEmpty || !_isDigits(digits)) return null;

  final String format;
  final bool checkValid;
  switch (digits.length) {
    case 6:
      // UPC-E 6-digit core carries no check digit of its own.
      format = 'UPC-E';
      checkValid = true;
    case 8:
      format = 'EAN-8';
      checkValid = isValidEan8(digits);
    case 10:
      if (!looksLikeIsbn(digits)) return null;
      format = 'ISBN-10';
      checkValid = true;
    case 12:
      format = 'UPC-A';
      checkValid = isValidUpcA(digits);
    case 13:
      format = looksLikeIsbn(digits) ? 'ISBN-13' : 'EAN-13';
      checkValid = isValidEan13(digits);
    default:
      return null;
  }

  return ParsedResult(
    kind: ResultKind.product,
    rawValue: raw,
    formatLabel: formatLabel,
    scannedAt: DateTime.now(),
    fields: <String, String>{
      'checkDigit': digits[digits.length - 1],
      'checkValid': checkValid ? 'true' : 'false',
      'gs1Country': gs1Country(digits.substring(0, 3)) ?? '',
      'format': format,
    },
    title: groupBarcodeDigits(digits),
  );
}

/// True when [s] is non-empty and consists only of ASCII digits.
bool _isDigits(String s) => s.isNotEmpty && RegExp(r'^\d+$').hasMatch(s);

/// Numeric value of the ASCII digit at [index] in [s].
int _digitAt(String s, int index) => s.codeUnitAt(index) - 0x30;

/// Compute the EAN check digit for the leading digits ([first] is 11 or 12
/// digits; weights 1,3,1,3... from the left).
int _eanCheckDigit(String first) {
  int sum = 0;
  for (int i = 0; i < first.length; i++) {
    sum += _digitAt(first, i) * (i.isEven ? 1 : 3);
  }
  return (10 - (sum % 10)) % 10;
}
