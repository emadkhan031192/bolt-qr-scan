import 'package:boltscan/core/models/parsed_result.dart';
import 'package:boltscan/core/parsers/url_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tryParseUrl detection', () {
    test('accepts https URLs', () {
      final ParsedResult? result = tryParseUrl('https://example.com/path?q=1');
      expect(result, isNotNull);
      expect(result!.kind, ResultKind.url);
      expect(result.fields['url'], 'https://example.com/path?q=1');
      expect(result.fields['domain'], 'example.com');
      expect(result.title, 'example.com');
      expect(result.safetyFlags, isEmpty);
    });

    test('accepts http URLs and flags them', () {
      final ParsedResult? result = tryParseUrl('http://example.com');
      expect(result, isNotNull);
      expect(result!.safetyFlags, contains('http'));
      expect(result.fields['url'], 'http://example.com');
    });

    test('accepts www. without scheme', () {
      final ParsedResult? result = tryParseUrl('www.example.com/page');
      expect(result, isNotNull);
      expect(result!.fields['url'], 'https://www.example.com/page');
      expect(result.fields['domain'], 'www.example.com');
    });

    test('accepts bare domains', () {
      final ParsedResult? result = tryParseUrl('example.com/path');
      expect(result, isNotNull);
      expect(result!.fields['url'], 'https://example.com/path');
      expect(result.fields['domain'], 'example.com');
    });

    test('rejects strings with spaces', () {
      expect(tryParseUrl('not a url'), isNull);
      expect(tryParseUrl('example.com/a path'), isNull);
    });

    test('rejects non-URLs', () {
      expect(tryParseUrl('hello'), isNull);
      expect(tryParseUrl('example'), isNull);
      expect(tryParseUrl('user@example.com'), isNull);
      expect(tryParseUrl(''), isNull);
    });
  });

  group('url safety flags', () {
    test('flags an IPv4 host', () {
      final ParsedResult? result = tryParseUrl('http://192.168.1.1/admin');
      expect(result, isNotNull);
      expect(result!.safetyFlags, contains('ip_host'));
    });

    test('flags an IPv6 host', () {
      final ParsedResult? result = tryParseUrl('http://[::1]/');
      expect(result, isNotNull);
      expect(result!.safetyFlags, contains('ip_host'));
    });

    test('flags a punycode host', () {
      final ParsedResult? result =
          tryParseUrl('https://xn--nxasmq6b.example/login');
      expect(result, isNotNull);
      expect(result!.safetyFlags, contains('punycode'));
    });

    test('flags a URL shortener', () {
      final ParsedResult? result = tryParseUrl('https://bit.ly/abc123');
      expect(result, isNotNull);
      expect(result!.safetyFlags, contains('shortener'));
      expect(result.safetyFlags, isNot(contains('http')));
    });

    test('flags a long URL', () {
      final String longPath = 'a' * 210;
      final ParsedResult? result = tryParseUrl('https://example.com/$longPath');
      expect(result, isNotNull);
      expect(result!.safetyFlags, contains('long_url'));
    });

    test('clean https URL has no flags', () {
      final ParsedResult? result = tryParseUrl('https://example.com/path');
      expect(result, isNotNull);
      expect(result!.safetyFlags, isEmpty);
    });

    test('http URL on an IP combines flags', () {
      final ParsedResult? result = tryParseUrl('http://10.0.0.1/');
      expect(result, isNotNull);
      expect(result!.safetyFlags, containsAll(<String>['ip_host', 'http']));
    });
  });
}
