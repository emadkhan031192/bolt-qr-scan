import 'package:boltscan/core/models/parsed_result.dart';
import 'package:boltscan/core/parsers/wifi_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tryParseWifi', () {
    test('parses a full WPA payload', () {
      final ParsedResult? result =
          tryParseWifi('WIFI:T:WPA;S:mynet;P:secret;H:true;;');
      expect(result, isNotNull);
      expect(result!.kind, ResultKind.wifi);
      expect(result.fields['ssid'], 'mynet');
      expect(result.fields['password'], 'secret');
      expect(result.fields['auth'], 'WPA');
      expect(result.fields['hidden'], 'true');
      expect(result.title, 'mynet');
    });

    test('defaults hidden to false and auth to nopass', () {
      final ParsedResult? result = tryParseWifi('WIFI:S:open;;');
      expect(result, isNotNull);
      expect(result!.fields['hidden'], 'false');
      expect(result.fields['auth'], 'nopass');
      expect(result.fields['password'], '');
    });

    test('normalizes auth types', () {
      expect(tryParseWifi('WIFI:T:wep;S:x;;')!.fields['auth'], 'WEP');
      expect(tryParseWifi('WIFI:T:nopass;S:x;;')!.fields['auth'], 'nopass');
      expect(tryParseWifi('WIFI:T:WPA2;S:x;;')!.fields['auth'], 'WPA');
    });

    test('unescapes escaped characters in values', () {
      final ParsedResult? result =
          tryParseWifi(r'WIFI:T:WPA;S:my\;net\:name;P:pa\;ss;;');
      expect(result, isNotNull);
      expect(result!.fields['ssid'], r'my;net:name');
      expect(result.fields['password'], 'pa;ss');
    });

    test('rejects non-WIFI payloads and missing SSID', () {
      expect(tryParseWifi('WIFI:T:WPA;P:secret;;'), isNull);
      expect(tryParseWifi('WIFI:S:;;'), isNull);
      expect(tryParseWifi('http://example.com'), isNull);
      expect(tryParseWifi(''), isNull);
    });

    test('accepts lowercase prefix', () {
      final ParsedResult? result = tryParseWifi('wifi:T:WPA;S:x;;');
      expect(result, isNotNull);
      expect(result!.kind, ResultKind.wifi);
    });
  });

  group('buildWifiPayload', () {
    test('builds an exact payload', () {
      expect(
        buildWifiPayload(
          ssid: 'mynet',
          password: 'secret',
          auth: 'WPA',
          hidden: true,
        ),
        'WIFI:T:WPA;S:mynet;P:secret;H:true;;',
      );
    });

    test('escapes special characters', () {
      expect(
        buildWifiPayload(
          ssid: r'my;net:name\x',
          password: 'p,a',
          auth: 'WEP',
          hidden: false,
        ),
        r'WIFI:T:WEP;S:my\;net\:name\\x;P:p\,a;H:false;;',
      );
    });

    test('round-trips through tryParseWifi', () {
      const String ssid = r'café;net:name,2\x';
      const String password = r'p;a:s\s';
      final String payload = buildWifiPayload(
        ssid: ssid,
        password: password,
        auth: 'WPA',
        hidden: true,
      );
      final ParsedResult? parsed = tryParseWifi(payload);
      expect(parsed, isNotNull);
      expect(parsed!.fields['ssid'], ssid);
      expect(parsed.fields['password'], password);
      expect(parsed.fields['auth'], 'WPA');
      expect(parsed.fields['hidden'], 'true');
    });
  });
}
