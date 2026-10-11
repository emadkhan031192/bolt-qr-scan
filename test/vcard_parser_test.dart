import 'package:boltscan/core/models/parsed_result.dart';
import 'package:boltscan/core/parsers/contact_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tryParseContact vCard', () {
    test('parses a full vCard 3.0', () {
      const String vcard = 'BEGIN:VCARD\r\n'
          'VERSION:3.0\r\n'
          'FN:John Doe\r\n'
          'TEL;TYPE=CELL:+15551234567\r\n'
          'EMAIL:john@example.com\r\n'
          'ORG:Acme Corp\r\n'
          'NOTE:Friend from work\r\n'
          'END:VCARD';
      final ParsedResult? result = tryParseContact(vcard);
      expect(result, isNotNull);
      expect(result!.kind, ResultKind.contact);
      expect(result.fields['name'], 'John Doe');
      expect(result.fields['phone'], '+15551234567');
      expect(result.fields['email'], 'john@example.com');
      expect(result.fields['org'], 'Acme Corp');
      expect(result.fields['note'], 'Friend from work');
      expect(result.title, 'John Doe');
    });

    test('falls back to N: when FN: is missing', () {
      const String vcard = 'BEGIN:VCARD\n'
          'VERSION:3.0\n'
          'N:Doe;John;;;\n'
          'TEL:+15551234567\n'
          'END:VCARD';
      final ParsedResult? result = tryParseContact(vcard);
      expect(result, isNotNull);
      expect(result!.fields['name'], 'John Doe');
      expect(result.title, 'John Doe');
    });

    test('takes the first TEL when several are present', () {
      const String vcard = 'BEGIN:VCARD\n'
          'FN:Jane\n'
          'TEL;TYPE=WORK:+111\n'
          'TEL;TYPE=HOME:+222\n'
          'END:VCARD';
      final ParsedResult? result = tryParseContact(vcard);
      expect(result, isNotNull);
      expect(result!.fields['phone'], '+111');
    });

    test('rejects vCards without a name or contact detail', () {
      const String vcard = 'BEGIN:VCARD\nVERSION:3.0\nORG:Acme\nEND:VCARD';
      expect(tryParseContact(vcard), isNull);
    });
  });

  group('tryParseContact MECARD', () {
    test('parses a MECARD payload', () {
      const String mecard =
          'MECARD:N:Jane Smith;TEL:+15559876543;EMAIL:jane@example.com;ORG:Acme;;';
      final ParsedResult? result = tryParseContact(mecard);
      expect(result, isNotNull);
      expect(result!.kind, ResultKind.contact);
      expect(result.fields['name'], 'Jane Smith');
      expect(result.fields['phone'], '+15559876543');
      expect(result.fields['email'], 'jane@example.com');
      expect(result.fields['org'], 'Acme');
      expect(result.title, 'Jane Smith');
    });

    test('accepts a phone-only MECARD', () {
      final ParsedResult? result = tryParseContact('MECARD:TEL:+15550001111;;');
      expect(result, isNotNull);
      expect(result!.fields['phone'], '+15550001111');
      expect(result.title, '+15550001111');
    });

    test('rejects an empty MECARD', () {
      expect(tryParseContact('MECARD:;;'), isNull);
    });
  });

  group('tryParseContact rejects', () {
    test('rejects non-contact payloads', () {
      expect(tryParseContact('http://example.com'), isNull);
      expect(tryParseContact('John Doe'), isNull);
      expect(tryParseContact(''), isNull);
    });
  });
}
