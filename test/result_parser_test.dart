import 'package:boltscan/core/models/parsed_result.dart';
import 'package:boltscan/core/parsers/result_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseResult dispatcher', () {
    test('detects WIFI payloads', () {
      final ParsedResult result =
          parseResult('WIFI:T:WPA;S:home;P:secret;H:false;;');
      expect(result.kind, ResultKind.wifi);
      expect(result.fields['ssid'], 'home');
      expect(result.title, 'home');
    });

    test('detects mailto: payloads', () {
      final ParsedResult result =
          parseResult('mailto:support@example.com?subject=Help&body=Hi');
      expect(result.kind, ResultKind.email);
      expect(result.fields['to'], 'support@example.com');
      expect(result.fields['subject'], 'Help');
      expect(result.fields['body'], 'Hi');
    });

    test('detects MATMSG payloads', () {
      final ParsedResult result =
          parseResult('MATMSG:TO:a@b.com;SUB:Hi;BODY:Hello;;');
      expect(result.kind, ResultKind.email);
      expect(result.fields['to'], 'a@b.com');
    });

    test('detects geo: payloads', () {
      final ParsedResult result = parseResult('geo:24.8607,67.0011');
      expect(result.kind, ResultKind.geo);
      expect(result.fields['lat'], '24.8607');
      expect(result.fields['lng'], '67.0011');
    });

    test('detects vCard payloads', () {
      final ParsedResult result =
          parseResult('BEGIN:VCARD\nFN:John Doe\nTEL:+123\nEND:VCARD');
      expect(result.kind, ResultKind.contact);
      expect(result.title, 'John Doe');
    });

    test('detects tel: payloads', () {
      final ParsedResult result = parseResult('tel:+15551234567');
      expect(result.kind, ResultKind.phone);
      expect(result.fields['number'], '+15551234567');
    });

    test('prefers sms over phone for SMSTO:', () {
      final ParsedResult result = parseResult('SMSTO:+1555:hello there');
      expect(result.kind, ResultKind.sms);
      expect(result.fields['number'], '+1555');
      expect(result.fields['body'], 'hello there');
    });

    test('detects sms: payloads', () {
      final ParsedResult result = parseResult('sms:+1555?body=hello');
      expect(result.kind, ResultKind.sms);
      expect(result.fields['body'], 'hello');
    });

    test('detects VEVENT payloads', () {
      final ParsedResult result = parseResult(
        'BEGIN:VEVENT\nSUMMARY:Party\nDTSTART:20261011T180000Z\nEND:VEVENT',
      );
      expect(result.kind, ResultKind.event);
      expect(result.fields['dtstart'], '2026-10-11T18:00:00Z');
      expect(result.title, 'Party');
    });

    test('detects URLs', () {
      final ParsedResult result = parseResult('https://example.com/x');
      expect(result.kind, ResultKind.url);
      expect(result.title, 'example.com');
    });

    test('detects EAN-13 digits as product', () {
      final ParsedResult result =
          parseResult('5901234123457', formatLabel: 'EAN_13');
      expect(result.kind, ResultKind.product);
      expect(result.fields['format'], 'EAN-13');
      expect(result.formatLabel, 'EAN_13');
    });

    test('falls back to plain text', () {
      final ParsedResult result = parseResult('Just some words here');
      expect(result.kind, ResultKind.text);
      expect(result.title, 'Just some words here');
    });

    test('passes through detectionMs and formatLabel', () {
      final ParsedResult result = parseResult(
        'hello world',
        formatLabel: 'QR_CODE',
        detectionMs: 250,
      );
      expect(result.formatLabel, 'QR_CODE');
      expect(result.detectionMs, 250);
      expect(result.rawValue, 'hello world');
    });

    test('keeps rawValue for parsed results', () {
      const String raw = 'WIFI:T:WPA;S:home;P:secret;;';
      final ParsedResult result =
          parseResult(raw, formatLabel: 'QR_CODE', detectionMs: 99);
      expect(result.rawValue, raw);
      expect(result.formatLabel, 'QR_CODE');
      expect(result.detectionMs, 99);
    });
  });
}
