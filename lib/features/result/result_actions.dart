// Primary per-kind actions for scan results, shared by the result sheet
// and the full result screen. The mapping: url -> Open (with a suspicious-
// link confirmation), wifi -> Connect (password copied, Wi-Fi settings
// opened), contact -> Add contact, email -> Compose, phone -> Call (dial),
// sms -> Message, geo -> Open in Maps, event -> Add to calendar,
// product/text -> Web search.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/models/parsed_result.dart';
import '../../services/actions.dart';
import '../settings/settings_model.dart';

/// First non-empty value for any of [keys] in [fields], or ''.
String firstField(Map<String, String> fields, List<String> keys) {
  for (final String key in keys) {
    final String? value = fields[key];
    if (value != null && value.trim().isNotEmpty) return value;
  }
  return '';
}

/// Localized label for the primary action of [kind].
String primaryLabelFor(AppStrings s, ResultKind kind) => switch (kind) {
      ResultKind.url => s.actionOpen,
      ResultKind.wifi => s.actionConnect,
      ResultKind.contact => s.actionAddContact,
      ResultKind.email => s.actionCompose,
      ResultKind.phone => s.actionCall,
      ResultKind.sms => s.actionMessage,
      ResultKind.geo => s.actionOpenInMaps,
      ResultKind.event => s.actionAddToCalendar,
      ResultKind.product || ResultKind.text => s.actionSearch,
    };

/// Icon for the primary action of [kind].
IconData primaryIconFor(ResultKind kind) => switch (kind) {
      ResultKind.url => Icons.open_in_new,
      ResultKind.wifi => Icons.wifi,
      ResultKind.contact => Icons.person_add,
      ResultKind.email => Icons.edit_outlined,
      ResultKind.phone => Icons.call_outlined,
      ResultKind.sms => Icons.message_outlined,
      ResultKind.geo => Icons.map_outlined,
      ResultKind.event => Icons.event_outlined,
      ResultKind.product || ResultKind.text => Icons.search,
    };

/// Run the primary action for [result]. Shows a suspicious-link confirmation
/// for flagged URLs (when the warnSuspicious setting is on) and snackbars
/// for unsupported/failed actions.
Future<void> primaryActionFor(
  BuildContext context,
  WidgetRef ref,
  ParsedResult result,
) async {
  final AppStrings s = ref.read(appStringsProvider);
  final SettingsModel settings = ref.read(settingsProvider);
  final ActionResult outcome;
  switch (result.kind) {
    case ResultKind.url:
      if (settings.warnSuspicious && result.safetyFlags.isNotEmpty) {
        final bool? proceed = await _confirmSuspicious(context, s);
        if (proceed != true) return;
      }
      outcome = await BoltActions.openUrl(result.rawValue);
    case ResultKind.wifi:
      outcome = await _connectWifi(context, s, result);
    case ResultKind.contact:
      outcome = await BoltActions.addContact(
        name: firstField(result.fields, const <String>['name', 'n']),
        phone: firstField(result.fields, const <String>['phone', 'tel', 'number']),
        email: firstField(result.fields, const <String>['email']),
        org: firstField(result.fields, const <String>['org', 'organization', 'company']),
      );
    case ResultKind.email:
      final String to = firstField(
            result.fields,
            const <String>['to', 'address', 'email'],
          );
      outcome = await BoltActions.composeEmail(
        to.isEmpty ? result.rawValue : to,
        subject: firstField(result.fields, const <String>['subject', 'subj']),
        body: firstField(result.fields, const <String>['body', 'text', 'message']),
      );
    case ResultKind.phone:
      final String number = firstField(
        result.fields,
        const <String>['number', 'phone', 'tel'],
      );
      outcome = await BoltActions.dial(
        number.isEmpty ? result.rawValue : number,
      );
    case ResultKind.sms:
      outcome = await BoltActions.sendSms(
        firstField(result.fields, const <String>['number', 'phone', 'to']),
        firstField(result.fields, const <String>['body', 'text', 'message']),
      );
    case ResultKind.geo:
      final double? lat = double.tryParse(
        firstField(result.fields, const <String>['lat', 'latitude']),
      );
      final double? lng = double.tryParse(
        firstField(result.fields, const <String>['lng', 'lon', 'longitude']),
      );
      if (lat == null || lng == null) {
        outcome = ActionResult.failed;
      } else {
        outcome = await BoltActions.openMaps(
          lat,
          lng,
          query: firstField(result.fields, const <String>['query', 'q', 'label']),
        );
      }
    case ResultKind.event:
      outcome = await BoltActions.addCalendarEvent(
        summary: firstField(result.fields, const <String>['summary', 'title', 'name']),
        location: firstField(result.fields, const <String>['location', 'place']),
        description: firstField(result.fields, const <String>['description', 'desc']),
        start: _parseDate(firstField(result.fields, const <String>['start', 'dtstart', 'begin'])),
        end: _parseDate(firstField(result.fields, const <String>['end', 'dtend', 'finish'])),
      );
    case ResultKind.product:
    case ResultKind.text:
      outcome = await BoltActions.openWebSearch(result.rawValue);
  }
  if (!context.mounted) return;
  _announceOutcome(context, s, outcome);
}

/// Suspicious-link confirmation dialog. Returns true when the user proceeds.
Future<bool?> _confirmSuspicious(BuildContext context, AppStrings s) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext c) => AlertDialog(
      title: Text(s.suspiciousLinkTitle),
      content: Text(s.suspiciousLinkBody),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(c).pop(false),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(c).pop(true),
          child: Text(s.openAnyway),
        ),
      ],
    ),
  );
}

/// Wi-Fi connect: copy the password to the clipboard, then open Wi-Fi
/// settings so the user can paste it. The caller explains via snackbar.
Future<ActionResult> _connectWifi(
  BuildContext context,
  AppStrings s,
  ParsedResult result,
) async {
  final String password = firstField(
    result.fields,
    const <String>['password', 'pass', 'key'],
  );
  if (password.isNotEmpty) {
    await BoltActions.copyText(context, password);
  }
  final ActionResult outcome = await BoltActions.openWifiSettings();
  if (outcome == ActionResult.ok && password.isNotEmpty && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.passwordCopiedWifi)),
    );
  }
  return outcome;
}

/// Snackbar feedback for unsupported / failed actions.
void _announceOutcome(BuildContext context, AppStrings s, ActionResult r) {
  final String? message = switch (r) {
    ActionResult.ok => null,
    ActionResult.notSupported => s.actionNotSupported,
    ActionResult.failed => s.actionFailed,
  };
  if (message != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// Parse an event start/end value (ISO-8601 or ms epoch), or null.
DateTime? _parseDate(String value) {
  if (value.isEmpty) return null;
  final DateTime? iso = DateTime.tryParse(value);
  if (iso != null) return iso;
  final int? ms = int.tryParse(value);
  return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
}
