// User-initiated outbound actions. Everything here is triggered explicitly
// by the user tapping a button; the app never auto-fires intents.
// Privacy: no scanned data is ever logged or sent anywhere by these helpers.
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Result of an action attempt, for UI feedback.
enum ActionResult { ok, notSupported, failed }

class BoltActions {
  const BoltActions._();

  // ------------------------------------------------------------------ links
  static Future<ActionResult> openUrl(String url) async {
    Uri uri = Uri.tryParse(url) ?? Uri();
    if (!uri.hasScheme) uri = Uri.parse('https://$url');
    try {
      final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ok ? ActionResult.ok : ActionResult.failed;
    } catch (_) {
      return ActionResult.failed;
    }
  }

  static Future<ActionResult> openWebSearch(String query) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeQueryComponent(query)}',
    );
    try {
      final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ok ? ActionResult.ok : ActionResult.failed;
    } catch (_) {
      return ActionResult.failed;
    }
  }

  // ------------------------------------------------------------------ phone
  /// Dials only (ACTION_DIAL) — never places a call directly.
  static Future<ActionResult> dial(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    try {
      if (!await canLaunchUrl(uri)) return ActionResult.notSupported;
      final bool ok = await launchUrl(uri);
      return ok ? ActionResult.ok : ActionResult.failed;
    } catch (_) {
      return ActionResult.failed;
    }
  }

  static Future<ActionResult> sendSms(String number, String body) async {
    final Uri uri = Uri(scheme: 'sms', path: number, queryParameters: body.isEmpty ? null : <String, String>{'body': body});
    try {
      if (!await canLaunchUrl(uri)) return ActionResult.notSupported;
      final bool ok = await launchUrl(uri);
      return ok ? ActionResult.ok : ActionResult.failed;
    } catch (_) {
      return ActionResult.failed;
    }
  }

  static Future<ActionResult> composeEmail(
    String to, {
    String subject = '',
    String body = '',
  }) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: <String, String>{
        if (subject.isNotEmpty) 'subject': subject,
        if (body.isNotEmpty) 'body': body,
      },
    );
    try {
      if (!await canLaunchUrl(uri)) return ActionResult.notSupported;
      final bool ok = await launchUrl(uri);
      return ok ? ActionResult.ok : ActionResult.failed;
    } catch (_) {
      return ActionResult.failed;
    }
  }

  // ------------------------------------------------------------------ maps
  static Future<ActionResult> openMaps(
    double lat,
    double lng, {
    String? query,
  }) async {
    final String q = query == null || query.isEmpty ? '$lat,$lng' : query;
    final Uri uri = Uri.parse('geo:$lat,$lng?q=${Uri.encodeComponent(q)}');
    try {
      if (!await canLaunchUrl(uri)) return ActionResult.notSupported;
      final bool ok = await launchUrl(uri);
      return ok ? ActionResult.ok : ActionResult.failed;
    } catch (_) {
      return ActionResult.failed;
    }
  }

  // ------------------------------------------------------------------ intents
  static Future<ActionResult> addCalendarEvent({
    String summary = '',
    String location = '',
    String description = '',
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.INSERT',
        data: 'content://com.android.calendar/events',
        arguments: <String, dynamic>{
          'title': summary,
          'eventLocation': location,
          'description': description,
          if (start != null) 'beginTime': start.millisecondsSinceEpoch,
          if (end != null) 'endTime': end.millisecondsSinceEpoch,
        },
      );
      if (await intent.canResolveActivity() != true) return ActionResult.notSupported;
      await intent.launch();
      return ActionResult.ok;
    } catch (_) {
      return ActionResult.failed;
    }
  }

  static Future<ActionResult> addContact({
    String name = '',
    String phone = '',
    String email = '',
    String org = '',
  }) async {
    try {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.INSERT',
        data: 'content://com.android.contacts/contacts',
        arguments: <String, dynamic>{
          'name': name,
          'phone': phone,
          'email': email,
          'company': org,
        },
      );
      if (await intent.canResolveActivity() != true) return ActionResult.notSupported;
      await intent.launch();
      return ActionResult.ok;
    } catch (_) {
      return ActionResult.failed;
    }
  }

  /// Wi-Fi connect, implemented as documented in the README: Android 11+
  /// one-tap add via WifiNetworkSuggestion needs a dedicated platform
  /// channel and varies by OEM, so we open Wi-Fi settings and let the caller
  /// copy the password to the clipboard (snackbar explains).
  static Future<ActionResult> openWifiSettings() async {
    try {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.WIFI_SETTINGS',
      );
      if (await intent.canResolveActivity() != true) return ActionResult.notSupported;
      await intent.launch();
      return ActionResult.ok;
    } catch (_) {
      return ActionResult.failed;
    }
  }

  // ------------------------------------------------------------------ share
  static Future<ActionResult> copyText(BuildContext context, String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return ActionResult.ok;
    } catch (_) {
      return ActionResult.failed;
    }
  }

  static Future<ActionResult> shareText(String text) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text));
      return ActionResult.ok;
    } catch (_) {
      return ActionResult.failed;
    }
  }

  static Future<ActionResult> shareFile(XFile file, {String? text}) async {
    try {
      await SharePlus.instance.share(ShareParams(files: <XFile>[file], text: text));
      return ActionResult.ok;
    } catch (_) {
      return ActionResult.failed;
    }
  }
}

/// Short confirmation beep via the native ToneGenerator. Silent no-op when
/// the platform side is unavailable.
class BoltBeep {
  const BoltBeep._();

  static const MethodChannel _channel =
      MethodChannel('com.afzal.boltscan/beep');

  static Future<void> play() async {
    try {
      await _channel.invokeMethod<void>('beep');
    } catch (_) {
      // Beep is best-effort only.
    }
  }
}
