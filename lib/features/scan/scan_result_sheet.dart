// Bottom-sheet shown after a single scan: type badge, content, info line,
// primary smart action, copy/share, scan-again.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/models/parsed_result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/actions.dart';
import '../../widgets/expandable_text.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/type_badge.dart';
import '../settings/settings_model.dart';

/// First non-empty value for any of [keys] in [fields].
String? _field(Map<String, String> fields, List<String> keys) {
  for (final String key in keys) {
    final String? value = fields[key];
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

/// Shows the scan-result bottom sheet.
///
/// [onScanAgain] runs after the sheet is popped via "Scan again".
/// [onOpenFull] is invoked (without popping) by the open-in-full button;
/// the caller pops the sheet itself before pushing the full screen.
Future<void> showScanResultSheet(
  BuildContext context,
  WidgetRef ref,
  ParsedResult result, {
  required VoidCallback onScanAgain,
  required VoidCallback onOpenFull,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) => _ScanResultSheetContent(
      result: result,
      onScanAgain: onScanAgain,
      onOpenFull: onOpenFull,
    ),
  );
}

class _ScanResultSheetContent extends ConsumerWidget {
  const _ScanResultSheetContent({
    required this.result,
    required this.onScanAgain,
    required this.onOpenFull,
  });

  final ParsedResult result;
  final VoidCallback onScanAgain;
  final VoidCallback onOpenFull;

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Primary smart action for the result kind.
  ///
  /// Every await is followed by a [BuildContext.mounted] check before the
  /// context is used again, so the sheet can be dismissed mid-action.
  Future<void> _primaryAction(BuildContext context, WidgetRef ref) async {
    final SettingsModel settings = ref.read(settingsProvider);
    final AppStrings s = ref.read(appStringsProvider);
    final Map<String, String> fields = result.fields;

    Future<void> report(ActionResult r) async {
      if (r == ActionResult.ok || !context.mounted) {
        return;
      }
      _snack(
        context,
        r == ActionResult.notSupported ? s.actionNotSupported : s.actionFailed,
      );
    }

    switch (result.kind) {
      case ResultKind.url:
        final String url = _field(fields, <String>['url']) ?? result.rawValue;
        if (result.safetyFlags.isNotEmpty && settings.warnSuspicious) {
          final bool? go = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text(s.suspiciousLinkTitle),
              content: Text(s.suspiciousLinkBody),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(s.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(s.openAnyway),
                ),
              ],
            ),
          );
          if (go != true) {
            return;
          }
        }
        if (!context.mounted) {
          return;
        }
        await report(await BoltActions.openUrl(url));
      case ResultKind.wifi:
        final ActionResult wifiResult = await BoltActions.openWifiSettings();
        if (!context.mounted) {
          return;
        }
        final String? password = _field(fields, <String>['password']);
        if (password != null) {
          await BoltActions.copyText(context, password);
          if (!context.mounted) {
            return;
          }
        }
        if (wifiResult == ActionResult.ok) {
          _snack(context, s.passwordCopiedWifi);
        } else {
          _snack(
            context,
            wifiResult == ActionResult.notSupported
                ? s.actionNotSupported
                : s.actionFailed,
          );
        }
      case ResultKind.contact:
        final ActionResult contactResult = await BoltActions.addContact(
          name: _field(fields, <String>['name']) ?? '',
          phone: _field(fields, <String>['phone']) ?? '',
          email: _field(fields, <String>['email']) ?? '',
          org: _field(fields, <String>['org']) ?? '',
        );
        if (!context.mounted) {
          return;
        }
        await report(contactResult);
      case ResultKind.email:
        final ActionResult emailResult = await BoltActions.composeEmail(
          _field(fields, <String>['to', 'email', 'address']) ?? result.rawValue,
          subject: _field(fields, <String>['subject']) ?? '',
          body: _field(fields, <String>['body']) ?? '',
        );
        if (!context.mounted) {
          return;
        }
        await report(emailResult);
      case ResultKind.phone:
        final ActionResult dialResult = await BoltActions.dial(
          _field(fields, <String>['number', 'phone', 'tel']) ?? result.rawValue,
        );
        if (!context.mounted) {
          return;
        }
        await report(dialResult);
      case ResultKind.sms:
        final ActionResult smsResult = await BoltActions.sendSms(
          _field(fields, <String>['number', 'phone', 'tel']) ?? result.rawValue,
          _field(fields, <String>['body', 'message']) ?? '',
        );
        if (!context.mounted) {
          return;
        }
        await report(smsResult);
      case ResultKind.geo:
        final double? lat =
            double.tryParse(_field(fields, <String>['lat', 'latitude']) ?? '');
        final double? lng = double.tryParse(
          _field(fields, <String>['lng', 'lon', 'longitude']) ?? '',
        );
        if (lat == null || lng == null) {
          _snack(context, s.actionFailed);
          return;
        }
        final ActionResult mapsResult = await BoltActions.openMaps(
          lat,
          lng,
          query: _field(fields, <String>['query', 'label']),
        );
        if (!context.mounted) {
          return;
        }
        await report(mapsResult);
      case ResultKind.event:
        final ActionResult eventResult =
            await BoltActions.addCalendarEvent(
          summary: _field(fields, <String>['summary', 'title']) ?? '',
          location: _field(fields, <String>['location']) ?? '',
          description: _field(fields, <String>['description', 'desc']) ?? '',
          start: DateTime.tryParse(
            _field(fields, <String>['start', 'dtstart']) ?? '',
          ),
          end: DateTime.tryParse(
            _field(fields, <String>['end', 'dtend']) ?? '',
          ),
        );
        if (!context.mounted) {
          return;
        }
        await report(eventResult);
      case ResultKind.product:
      case ResultKind.text:
        final ActionResult searchResult =
            await BoltActions.openWebSearch(result.rawValue);
        if (!context.mounted) {
          return;
        }
        await report(searchResult);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = ref.watch(appStringsProvider);
    final SettingsModel settings = ref.watch(settingsProvider);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color muted = dark ? AppColors.darkMuted : AppColors.muted;

    final String displayText =
        result.kind == ResultKind.url && !settings.showFullUrl
            ? (result.title ?? result.rawValue)
            : result.rawValue;

    final (String, IconData) primary = switch (result.kind) {
      ResultKind.url => (s.actionOpen, Icons.open_in_new),
      ResultKind.wifi => (s.actionConnect, Icons.wifi),
      ResultKind.contact => (s.actionAddContact, Icons.person_add_alt),
      ResultKind.email => (s.actionCompose, Icons.email_outlined),
      ResultKind.phone => (s.actionCall, Icons.call_outlined),
      ResultKind.sms => (s.actionMessage, Icons.sms_outlined),
      ResultKind.geo => (s.actionOpenInMaps, Icons.map_outlined),
      ResultKind.event => (s.actionAddToCalendar, Icons.event_outlined),
      ResultKind.product => (s.actionSearch, Icons.search),
      ResultKind.text => (s.actionSearch, Icons.search),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              TypeBadge(kind: result.kind),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.detectedIn(
                    (result.detectionMs / 1000).toStringAsFixed(2),
                  ),
                  style: AppText.mono(context, fontSize: 12, color: muted),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_full),
                tooltip: s.resultTitle,
                onPressed: onOpenFull,
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ExpandableText(
                    text: displayText,
                    style: AppText.mono(context, fontSize: 15),
                  ),
                  _infoLine(context, s, muted),
                  const SizedBox(height: 16),
                  BoltPillButton(
                    label: primary.$1,
                    icon: primary.$2,
                    onPressed: () => unawaited(_primaryAction(context, ref)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: BoltPillButton(
                          label: s.copy,
                          icon: Icons.copy_outlined,
                          primary: false,
                          onPressed: () async {
                            final ActionResult r = await BoltActions.copyText(
                              context,
                              result.rawValue,
                            );
                            if (context.mounted) {
                              _snack(
                                context,
                                r == ActionResult.ok
                                    ? s.copiedToClipboard
                                    : s.actionFailed,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: BoltPillButton(
                          label: s.share,
                          icon: Icons.share_outlined,
                          primary: false,
                          onPressed: () async {
                            final ActionResult r =
                                await BoltActions.shareText(result.rawValue);
                            if (context.mounted && r != ActionResult.ok) {
                              _snack(context, s.actionFailed);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onScanAgain();
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
              ),
              child: Text(s.scanAgain),
            ),
          ),
        ],
      ),
    );
  }

  /// One-line safety or kind-specific info note.
  Widget _infoLine(BuildContext context, AppStrings s, Color muted) {
    String? text;
    IconData icon = Icons.info_outline;
    if (result.safetyFlags.isNotEmpty) {
      text = '${s.safetyNoteTitle}: ${result.safetyFlags.first}';
      icon = Icons.warning_amber_rounded;
    } else {
      switch (result.kind) {
        case ResultKind.product:
          final String? country =
              _field(result.fields, <String>['gs1Country', 'country']);
          if (country != null) {
            text = '${s.gs1CountryRow}: $country';
            icon = Icons.public;
          }
        case ResultKind.wifi:
          final String? ssid =
              _field(result.fields, <String>['ssid']) ?? result.title;
          if (ssid != null) {
            text = '${s.wifiNetworkRow}: $ssid';
            icon = Icons.wifi;
          }
        case ResultKind.url:
          final String? domain = _field(result.fields, <String>['domain']);
          if (domain != null && domain != result.rawValue) {
            text = domain;
            icon = Icons.link;
          }
        case ResultKind.contact:
        case ResultKind.email:
        case ResultKind.phone:
        case ResultKind.sms:
        case ResultKind.geo:
        case ResultKind.event:
        case ResultKind.text:
          break;
      }
    }
    if (text == null) {
      return const SizedBox.shrink();
    }
    final bool warn = result.safetyFlags.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 16,
            color: warn ? AppColors.danger : muted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.mono(context, fontSize: 12, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
