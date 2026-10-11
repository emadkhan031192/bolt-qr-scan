import 'package:boltscan/core/parsers/payload_builders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildTextPayload', () {
    test('returns the text unchanged', () {
      expect(buildTextPayload('Hello world'), 'Hello world');
    });
  });

  group('buildLinkPayload', () {
    test('prepends https:// when no scheme is present', () {
      expect(buildLinkPayload('example.com/page'), 'https://example.com/page');
    });

    test('keeps an existing scheme', () {
      expect(buildLinkPayload('http://example.com'), 'http://example.com');
      expect(
        buildLinkPayload('https://example.com/x'),
        'https://example.com/x',
      );
    });
  });

  group('buildVCard', () {
    test('builds an exact vCard 3.0 payload', () {
      expect(
        buildVCard(
          name: 'John Doe',
          phone: '+15551234567',
          email: 'john@example.com',
          org: 'Acme',
        ),
        'BEGIN:VCARD\n'
        'VERSION:3.0\n'
        'FN:John Doe\n'
        'TEL:+15551234567\n'
        'EMAIL:john@example.com\n'
        'ORG:Acme\n'
        'END:VCARD',
      );
    });

    test('omits empty optional fields', () {
      expect(
        buildVCard(name: 'Jane'),
        'BEGIN:VCARD\nVERSION:3.0\nFN:Jane\nEND:VCARD',
      );
    });
  });

  group('buildMailto', () {
    test('builds a mailto URI with encoded params', () {
      expect(
        buildMailto(
          to: 'a@b.com',
          subject: 'Hi there',
          body: 'Hello & bye',
        ),
        'mailto:a@b.com?subject=Hi%20there&body=Hello%20%26%20bye',
      );
    });

    test('omits the query when no subject/body', () {
      expect(buildMailto(to: 'a@b.com'), 'mailto:a@b.com');
    });
  });

  group('buildTel', () {
    test('builds a tel: URI', () {
      expect(buildTel('+15551234567'), 'tel:+15551234567');
    });
  });

  group('buildSmsto', () {
    test('builds an SMSTO: payload', () {
      expect(
        buildSmsto(number: '+1555', body: 'hello'),
        'SMSTO:+1555:hello',
      );
    });

    test('builds an SMSTO: payload without body', () {
      expect(buildSmsto(number: '+1555'), 'SMSTO:+1555:');
    });
  });

  group('buildGeo', () {
    test('builds a geo: URI without query', () {
      expect(buildGeo(lat: 24.5, lng: 67.1), 'geo:24.5,67.1');
    });

    test('builds a geo: URI with encoded query', () {
      expect(
        buildGeo(lat: 24.5, lng: 67.1, query: 'coffee shop'),
        'geo:24.5,67.1?q=coffee%20shop',
      );
    });
  });

  group('buildWifiPayload (re-exported)', () {
    test('builds a WIFI: payload', () {
      expect(
        buildWifiPayload(
          ssid: 'mynet',
          password: 'secret',
          auth: 'WPA',
          hidden: false,
        ),
        'WIFI:T:WPA;S:mynet;P:secret;H:false;;',
      );
    });
  });
}
