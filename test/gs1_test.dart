import 'package:boltscan/core/parsers/gs1_prefixes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('gs1Country', () {
    test('969 maps to Pakistan', () {
      expect(gs1Country('969'), 'GS1 Pakistan');
    });

    test('890 maps to India', () {
      expect(gs1Country('890'), 'GS1 India');
    });

    test('000 and 139 map to USA/Canada', () {
      expect(gs1Country('000'), 'GS1 US');
      expect(gs1Country('019'), 'GS1 US');
      expect(gs1Country('139'), 'GS1 US');
    });

    test('020-029 is restricted distribution', () {
      expect(gs1Country('020'), 'Restricted distribution');
      expect(gs1Country('029'), 'Restricted distribution');
    });

    test('050-059 is coupons', () {
      expect(gs1Country('050'), 'Coupons');
    });

    test('978 and 979 map to Bookland', () {
      expect(gs1Country('978'), 'Bookland (ISBN books)');
      expect(gs1Country('979'), 'Bookland (ISBN books)');
    });

    test('628 maps to Saudi Arabia', () {
      expect(gs1Country('628'), 'GS1 Saudi Arabia');
    });

    test('999 maps to GS1 coupons', () {
      expect(gs1Country('999'), 'GS1 coupons');
    });

    test('981-983 maps to GS1 coupons', () {
      expect(gs1Country('981'), 'GS1 coupons');
    });

    test('range boundaries', () {
      expect(gs1Country('300'), 'GS1 France');
      expect(gs1Country('379'), 'GS1 France');
      expect(gs1Country('400'), 'GS1 Germany');
      expect(gs1Country('440'), 'GS1 Germany');
      expect(gs1Country('450'), 'GS1 Japan');
      expect(gs1Country('490'), 'GS1 Japan');
      expect(gs1Country('500'), 'GS1 UK');
      expect(gs1Country('754'), 'GS1 Canada');
      expect(gs1Country('755'), 'GS1 Canada');
      expect(gs1Country('800'), 'GS1 Italy');
      expect(gs1Country('839'), 'GS1 Italy');
      expect(gs1Country('868'), 'GS1 Turkey');
      expect(gs1Country('869'), 'GS1 Turkey');
      expect(gs1Country('960'), 'GS1 UK Office');
      expect(gs1Country('961'), 'GS1 UK Office');
    });

    test('individual codes', () {
      expect(gs1Country('380'), 'GS1 Bulgaria');
      expect(gs1Country('471'), 'GS1 Taiwan');
      expect(gs1Country('729'), 'GS1 Israel');
      expect(gs1Country('880'), 'GS1 South Korea');
      expect(gs1Country('977'), 'ISSN (serials)');
      expect(gs1Country('950'), 'GS1 Global Office');
    });

    test('returns null for unassigned prefixes', () {
      expect(gs1Country('140'), isNull);
      expect(gs1Country('199'), isNull);
      expect(gs1Country('382'), isNull);
      expect(gs1Country('472'), isNull);
    });

    test('returns null for invalid input', () {
      expect(gs1Country('96'), isNull);
      expect(gs1Country('9690'), isNull);
      expect(gs1Country('abc'), isNull);
      expect(gs1Country(''), isNull);
    });
  });
}
