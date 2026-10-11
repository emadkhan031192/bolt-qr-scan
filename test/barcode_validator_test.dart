import 'package:boltscan/core/models/parsed_result.dart';
import 'package:boltscan/core/parsers/barcode_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidEan13', () {
    test('accepts a known-valid EAN-13', () {
      expect(isValidEan13('5901234123457'), isTrue);
    });

    test('accepts a valid 969-prefixed Pakistan code', () {
      expect(isValidEan13('9691234567899'), isTrue);
    });

    test('rejects a wrong check digit', () {
      expect(isValidEan13('5901234123458'), isFalse);
    });

    test('rejects wrong lengths and non-digits', () {
      expect(isValidEan13('590123412345'), isFalse);
      expect(isValidEan13('59012341234577'), isFalse);
      expect(isValidEan13('590123412345a'), isFalse);
      expect(isValidEan13(''), isFalse);
    });
  });

  group('isValidEan8', () {
    test('accepts a known-valid EAN-8', () {
      expect(isValidEan8('96385074'), isTrue);
    });

    test('rejects a wrong check digit', () {
      expect(isValidEan8('96385075'), isFalse);
    });

    test('rejects wrong lengths', () {
      expect(isValidEan8('9638507'), isFalse);
      expect(isValidEan8('963850744'), isFalse);
    });
  });

  group('isValidUpcA', () {
    test('accepts a known-valid UPC-A', () {
      expect(isValidUpcA('036000291452'), isTrue);
    });

    test('rejects a wrong check digit', () {
      expect(isValidUpcA('036000291453'), isFalse);
    });

    test('rejects wrong lengths', () {
      expect(isValidUpcA('36000291452'), isFalse);
    });
  });

  group('upcEToUpcA', () {
    test('expands a 6-digit core ending in 0', () {
      expect(upcEToUpcA('042100'), '004000002101');
    });

    test('expands a 6-digit core ending in 5-9', () {
      expect(upcEToUpcA('123456'), '012345000065');
    });

    test('expands a 6-digit core ending in 3', () {
      expect(upcEToUpcA('123364'), isA<String>());
      expect(isValidUpcA(upcEToUpcA('123364')), isTrue);
    });

    test('accepts 8 digits and recomputes the check digit', () {
      // NS=0, core=123456, supplied check digit ignored.
      expect(upcEToUpcA('01234560'), '012345000065');
    });

    test('expanded codes are valid UPC-A', () {
      expect(isValidUpcA(upcEToUpcA('042100')), isTrue);
      expect(isValidUpcA(upcEToUpcA('123456')), isTrue);
    });

    test('throws on invalid input', () {
      expect(() => upcEToUpcA('12345'), throwsArgumentError);
      expect(() => upcEToUpcA('1234567'), throwsArgumentError);
      expect(() => upcEToUpcA('12345a'), throwsArgumentError);
    });
  });

  group('looksLikeIsbn', () {
    test('accepts a known-valid ISBN-13', () {
      expect(looksLikeIsbn('9780306406157'), isTrue);
    });

    test('rejects ISBN-13 with wrong check digit', () {
      expect(looksLikeIsbn('9780306406158'), isFalse);
    });

    test('rejects 13 digits not starting with 978/979', () {
      expect(looksLikeIsbn('5901234123457'), isFalse);
    });

    test('accepts a known-valid ISBN-10', () {
      expect(looksLikeIsbn('0306406152'), isTrue);
    });

    test('accepts an ISBN-10 with X check digit', () {
      expect(looksLikeIsbn('080442957X'), isTrue);
    });

    test('rejects ISBN-10 with wrong check digit', () {
      expect(looksLikeIsbn('0306406153'), isFalse);
    });

    test('rejects other lengths', () {
      expect(looksLikeIsbn('97803064061'), isFalse);
      expect(looksLikeIsbn(''), isFalse);
    });
  });

  group('groupBarcodeDigits', () {
    test('groups a 13-digit code', () {
      expect(groupBarcodeDigits('9691234567890'), '9 691234 567890');
    });

    test('groups a 12-digit code', () {
      expect(groupBarcodeDigits('036000291452'), '0 36000 291452');
    });

    test('groups an 8-digit code', () {
      expect(groupBarcodeDigits('96385074'), '9638 5074');
    });

    test('returns other lengths unchanged', () {
      expect(groupBarcodeDigits('123456'), '123456');
    });
  });

  group('tryParseProduct', () {
    test('parses a valid EAN-13', () {
      final ParsedResult? result = tryParseProduct('5901234123457', 'EAN_13');
      expect(result, isNotNull);
      expect(result!.kind, ResultKind.product);
      expect(result.fields['format'], 'EAN-13');
      expect(result.fields['checkValid'], 'true');
      expect(result.fields['checkDigit'], '7');
      expect(result.fields['gs1Country'], 'GS1 Poland');
      expect(result.formatLabel, 'EAN_13');
    });

    test('flags an invalid check digit but still returns a result', () {
      final ParsedResult? result = tryParseProduct('5901234123458', '');
      expect(result, isNotNull);
      expect(result!.fields['checkValid'], 'false');
      expect(result.fields['format'], 'EAN-13');
    });

    test('detects ISBN-13 for 978 prefix', () {
      final ParsedResult? result = tryParseProduct('9780306406157', '');
      expect(result, isNotNull);
      expect(result!.fields['format'], 'ISBN-13');
      expect(result.fields['gs1Country'], 'Bookland (ISBN books)');
    });

    test('detects ISBN-10', () {
      final ParsedResult? result = tryParseProduct('0306406152', '');
      expect(result, isNotNull);
      expect(result!.fields['format'], 'ISBN-10');
      expect(result.fields['checkValid'], 'true');
    });

    test('rejects a 10-digit non-ISBN', () {
      expect(tryParseProduct('1234567890', ''), isNull);
    });

    test('parses UPC-E 6-digit core', () {
      final ParsedResult? result = tryParseProduct('042100', '');
      expect(result, isNotNull);
      expect(result!.fields['format'], 'UPC-E');
      expect(result.title, '042100');
    });

    test('parses EAN-8 and UPC-A', () {
      expect(tryParseProduct('96385074', '')!.fields['format'], 'EAN-8');
      expect(tryParseProduct('036000291452', '')!.fields['format'], 'UPC-A');
    });

    test('strips spaces and dashes', () {
      final ParsedResult? result = tryParseProduct('5901 2341-2345 7', '');
      expect(result, isNotNull);
      expect(result!.fields['format'], 'EAN-13');
      expect(result.fields['checkValid'], 'true');
    });

    test('rejects non-digits and unsupported lengths', () {
      expect(tryParseProduct('5901234a', ''), isNull);
      expect(tryParseProduct('1234567', ''), isNull);
      expect(tryParseProduct('', ''), isNull);
    });

    test('groups the title', () {
      final ParsedResult? result = tryParseProduct('9691234567899', '');
      expect(result, isNotNull);
      expect(result!.title, '9 691234 567899');
      expect(result.fields['gs1Country'], 'GS1 Pakistan');
    });
  });
}
