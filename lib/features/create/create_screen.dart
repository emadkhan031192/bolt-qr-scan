// Create tab: build QR payloads per type with a live preview, color and
// error-correction controls, save-to-gallery and share actions.
// Every valid new payload is auto-saved to history exactly once.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:boltscan/widgets/design_chip.dart';
import 'package:boltscan/widgets/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/strings.dart';
import '../../core/models/parsed_result.dart';
import '../../core/parsers/payload_builders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/color_utils.dart';
import '../../services/actions.dart';
import '../history/history_repository.dart';
import '../settings/settings_model.dart';

/// QR payload type chosen on the Create tab.
enum _CreateType { text, link, wifi, contact, email, phone, sms, location }

/// Screen for generating QR codes from typed content.
class CreateScreen extends ConsumerStatefulWidget {
  /// Creates the QR generator screen.
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  _CreateType _type = _CreateType.text;

  final TextEditingController _content = TextEditingController();
  final TextEditingController _url = TextEditingController();
  final TextEditingController _ssid = TextEditingController();
  final TextEditingController _wifiPassword = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _contactPhone = TextEditingController();
  final TextEditingController _contactEmail = TextEditingController();
  final TextEditingController _org = TextEditingController();
  final TextEditingController _emailTo = TextEditingController();
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _body = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _smsPhone = TextEditingController();
  final TextEditingController _smsMessage = TextEditingController();
  final TextEditingController _lat = TextEditingController();
  final TextEditingController _lng = TextEditingController();
  final TextEditingController _query = TextEditingController();

  String _wifiAuth = 'WPA';
  bool _hidden = false;

  /// Locally overridden QR color; null means "follow settings".
  String? _colorKey;

  /// Last payload that was auto-saved to history, to save each one once.
  String _lastSavedPayload = '';

  static final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    for (final TextEditingController c in <TextEditingController>[
      _content,
      _url,
      _ssid,
      _wifiPassword,
      _name,
      _contactPhone,
      _contactEmail,
      _org,
      _emailTo,
      _subject,
      _body,
      _phone,
      _smsPhone,
      _smsMessage,
      _lat,
      _lng,
      _query,
    ]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _content,
      _url,
      _ssid,
      _wifiPassword,
      _name,
      _contactPhone,
      _contactEmail,
      _org,
      _emailTo,
      _subject,
      _body,
      _phone,
      _smsPhone,
      _smsMessage,
      _lat,
      _lng,
      _query,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    _maybeAutoSave();
  }

  void _setType(_CreateType t) {
    if (t == _type) return;
    setState(() {
      _type = t;
      _lastSavedPayload = '';
    });
    _maybeAutoSave();
  }

  // ------------------------------------------------------------ validation
  bool _validUrl(String v) {
    final String t = v.trim();
    return t.contains('.') && !t.contains(' ');
  }

  bool _validEmail(String v) => _emailRe.hasMatch(v.trim());

  double? _parseLat(String v) {
    final double? d = double.tryParse(v.trim());
    if (d == null || d < -90 || d > 90) return null;
    return d;
  }

  double? _parseLng(String v) {
    final double? d = double.tryParse(v.trim());
    if (d == null || d < -180 || d > 180) return null;
    return d;
  }

  /// Builds the current payload; empty string means invalid/incomplete.
  String _buildPayload() {
    switch (_type) {
      case _CreateType.text:
        final String t = _content.text.trim();
        return t.isEmpty ? '' : buildTextPayload(t);
      case _CreateType.link:
        final String t = _url.text.trim();
        return _validUrl(t) ? buildLinkPayload(t) : '';
      case _CreateType.wifi:
        final String ssid = _ssid.text.trim();
        if (ssid.isEmpty) return '';
        return buildWifiPayload(
          ssid: ssid,
          password: _wifiPassword.text,
          auth: _wifiAuth,
          hidden: _hidden,
        );
      case _CreateType.contact:
        final String name = _name.text.trim();
        if (name.isEmpty) return '';
        final String email = _contactEmail.text.trim();
        if (email.isNotEmpty && !_validEmail(email)) return '';
        return buildVCard(
          name: name,
          phone: _contactPhone.text.trim(),
          email: email,
          org: _org.text.trim(),
        );
      case _CreateType.email:
        final String to = _emailTo.text.trim();
        if (!_validEmail(to)) return '';
        return buildMailto(
          to: to,
          subject: _subject.text.trim(),
          body: _body.text,
        );
      case _CreateType.phone:
        final String p = _phone.text.trim();
        return p.isEmpty ? '' : buildTel(p);
      case _CreateType.sms:
        final String p = _smsPhone.text.trim();
        return p.isEmpty
            ? ''
            : buildSmsto(number: p, body: _smsMessage.text);
      case _CreateType.location:
        final double? lat = _parseLat(_lat.text);
        final double? lng = _parseLng(_lng.text);
        if (lat == null || lng == null) return '';
        return buildGeo(lat: lat, lng: lng, query: _query.text.trim());
    }
  }

  ResultKind _kindFor(_CreateType t) {
    switch (t) {
      case _CreateType.text:
        return ResultKind.text;
      case _CreateType.link:
        return ResultKind.url;
      case _CreateType.wifi:
        return ResultKind.wifi;
      case _CreateType.contact:
        return ResultKind.contact;
      case _CreateType.email:
        return ResultKind.email;
      case _CreateType.phone:
        return ResultKind.phone;
      case _CreateType.sms:
        return ResultKind.sms;
      case _CreateType.location:
        return ResultKind.geo;
    }
  }

  /// Saves the payload to history once per distinct payload.
  void _maybeAutoSave() {
    final String payload = _buildPayload();
    if (payload.isEmpty || payload == _lastSavedPayload) return;
    _lastSavedPayload = payload;
    unawaited(
      ref.read(historyRepositoryProvider.notifier).saveScan(
            ParsedResult(
              kind: _kindFor(_type),
              rawValue: payload,
              scannedAt: DateTime.now(),
              formatLabel: 'QR',
            ),
            source: 'created',
          ),
    );
  }

  // ---------------------------------------------------------------- helpers
  /// Maps the settings EC-level string to qr_flutter's int level.
  int _ecLevelFor(String s) {
    switch (s) {
      case 'L':
        return QrErrorCorrectLevel.L;
      case 'Q':
        return QrErrorCorrectLevel.Q;
      case 'H':
        return QrErrorCorrectLevel.H;
      case 'M':
      default:
        return QrErrorCorrectLevel.M;
    }
  }

  /// Local contrast warning is provided by worker B's [qrColorWarns].

  static const Map<String, Color> _qrColors = <String, Color>{
    'ink': AppColors.ink,
    'blue': AppColors.electricBlue,
    'green': AppColors.success,
  };

  Color _activeColor(SettingsModel settings) {
    final String key = _colorKey ?? settings.defaultQrColor;
    return _qrColors[key] ?? AppColors.ink;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Renders the QR as a PNG with a white background.
  Future<Uint8List?> _renderPng(String payload, Color color, int ec) async {
    const int size = 2048;
    final QrPainter painter = QrPainter(
      data: payload,
      version: QrVersions.auto,
      errorCorrectionLevel: ec,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: color,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: color,
      ),
    );
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawColor(Colors.white, ui.BlendMode.src);
    painter.paint(canvas, const ui.Size(2048, 2048));
    final ui.Image image =
        await recorder.endRecording().toImage(size, size);
    try {
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> _saveImage(String payload, Color color, int ec) async {
    final AppStrings s = ref.read(appStringsProvider);
    try {
      final Uint8List? bytes = await _renderPng(payload, color, ec);
      if (bytes == null) {
        _snack(s.imageSaveFailed);
        return;
      }
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }
      if (!await Gal.hasAccess()) {
        _snack(s.imageSaveFailed);
        return;
      }
      await Gal.putImageBytes(
        bytes,
        name: 'bolt_qr_${DateTime.now().millisecondsSinceEpoch}',
      );
      _snack(s.imageSaved);
    } catch (_) {
      _snack(s.imageSaveFailed);
    }
  }

  Future<void> _shareImage(String payload, Color color, int ec) async {
    final AppStrings s = ref.read(appStringsProvider);
    try {
      final Uint8List? bytes = await _renderPng(payload, color, ec);
      if (bytes == null) {
        _snack(s.imageSaveFailed);
        return;
      }
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/bolt_qr.png');
      await file.writeAsBytes(bytes);
      final ActionResult r = await BoltActions.shareFile(XFile(file.path));
      if (r != ActionResult.ok) _snack(s.imageSaveFailed);
    } catch (_) {
      _snack(s.imageSaveFailed);
    }
  }

  // ------------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    final AppStrings s = ref.watch(appStringsProvider);
    final SettingsModel settings = ref.watch(settingsProvider);
    final String payload = _buildPayload();
    final Color qrColor = _activeColor(settings);
    final int ec = _ecLevelFor(settings.ecLevel);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: Text(
            s.createTitle,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(
            s.createSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
          ),
        ),
        _TypeChips(
          current: _type,
          onSelect: _setType,
          strings: s,
        ),
        const SizedBox(height: 16),
        _formFor(s),
        const SizedBox(height: 16),
        _PreviewCard(
          payload: payload,
          color: qrColor,
          ec: ec,
        ),
        if (qrColorWarns(qrColor)) ...<Widget>[
          const SizedBox(height: 8),
          _WarningBanner(text: s.contrastWarning),
        ],
        const SizedBox(height: 16),
        _ColorRow(
          selectedKey: _colorKey ?? settings.defaultQrColor,
          strings: s,
          onSelect: (String key) => setState(() => _colorKey = key),
        ),
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(
              flex: 3,
              child: BoltPillButton(
                label: s.saveImage,
                onPressed: payload.isEmpty
                    ? null
                    : () => _saveImage(payload, qrColor, ec),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: BoltPillButton(
                label: s.share,
                primary: false,
                onPressed: payload.isEmpty
                    ? null
                    : () => _shareImage(payload, qrColor, ec),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------------- form
  Widget _formFor(AppStrings s) {
    switch (_type) {
      case _CreateType.text:
        return _field(
          controller: _content,
          label: s.labelContent,
          maxLines: 4,
          error: _content.text.trim().isEmpty ? s.fieldRequired : null,
        );
      case _CreateType.link:
        final String t = _url.text.trim();
        return _field(
          controller: _url,
          label: s.labelWebAddress,
          keyboard: TextInputType.url,
          error: t.isEmpty
              ? s.fieldRequired
              : (_validUrl(t) ? null : s.invalidUrl),
        );
      case _CreateType.wifi:
        return Column(
          children: <Widget>[
            _field(
              controller: _ssid,
              label: s.labelSsid,
              error: _ssid.text.trim().isEmpty ? s.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _wifiPassword,
              label: s.labelPassword,
              obscure: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _wifiAuth,
              decoration: InputDecoration(labelText: s.labelSecurity),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: 'WPA',
                  child: Text(s.securityWpa),
                ),
                DropdownMenuItem<String>(
                  value: 'WEP',
                  child: Text(s.securityWep),
                ),
                DropdownMenuItem<String>(
                  value: 'nopass',
                  child: Text(s.securityNone),
                ),
              ],
              onChanged: (String? v) {
                if (v != null) setState(() => _wifiAuth = v);
              },
            ),
            SwitchListTile(
              title: Text(s.labelHiddenNetwork),
              value: _hidden,
              contentPadding: EdgeInsets.zero,
              onChanged: (bool v) => setState(() => _hidden = v),
            ),
          ],
        );
      case _CreateType.contact:
        final String email = _contactEmail.text.trim();
        return Column(
          children: <Widget>[
            _field(
              controller: _name,
              label: s.labelName,
              error: _name.text.trim().isEmpty ? s.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _contactPhone,
              label: s.labelPhone,
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _contactEmail,
              label: s.labelEmail,
              keyboard: TextInputType.emailAddress,
              error: email.isNotEmpty && !_validEmail(email)
                  ? s.invalidEmail
                  : null,
            ),
            const SizedBox(height: 12),
            _field(controller: _org, label: s.labelOrg),
          ],
        );
      case _CreateType.email:
        final String to = _emailTo.text.trim();
        return Column(
          children: <Widget>[
            _field(
              controller: _emailTo,
              label: s.labelEmail,
              keyboard: TextInputType.emailAddress,
              error: to.isEmpty
                  ? s.fieldRequired
                  : (_validEmail(to) ? null : s.invalidEmail),
            ),
            const SizedBox(height: 12),
            _field(controller: _subject, label: s.labelSubject),
            const SizedBox(height: 12),
            _field(
              controller: _body,
              label: s.labelMessage,
              maxLines: 4,
            ),
          ],
        );
      case _CreateType.phone:
        return _field(
          controller: _phone,
          label: s.labelPhone,
          keyboard: TextInputType.phone,
          error: _phone.text.trim().isEmpty ? s.fieldRequired : null,
        );
      case _CreateType.sms:
        return Column(
          children: <Widget>[
            _field(
              controller: _smsPhone,
              label: s.labelPhone,
              keyboard: TextInputType.phone,
              error: _smsPhone.text.trim().isEmpty ? s.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _smsMessage,
              label: s.labelMessage,
              maxLines: 4,
            ),
          ],
        );
      case _CreateType.location:
        final bool latTouched = _lat.text.trim().isNotEmpty;
        final bool lngTouched = _lng.text.trim().isNotEmpty;
        return Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _field(
                    controller: _lat,
                    label: s.labelLatitude,
                    keyboard: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    error: !latTouched
                        ? s.fieldRequired
                        : (_parseLat(_lat.text) == null
                            ? s.invalidCoords
                            : null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    controller: _lng,
                    label: s.labelLongitude,
                    keyboard: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    error: !lngTouched
                        ? s.fieldRequired
                        : (_parseLng(_lng.text) == null
                            ? s.invalidCoords
                            : null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(controller: _query, label: s.labelMessage),
          ],
        );
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? error,
    TextInputType? keyboard,
    int maxLines = 1,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
          ),
        ),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            errorText: error,
          ),
          keyboardType: keyboard,
          maxLines: maxLines,
          obscureText: obscure,
        ),
      ],
    );
  }
}

/// Horizontal scrollable row of payload-type chips.
class _TypeChips extends StatelessWidget {
  /// Creates the type chip row.
  const _TypeChips({
    required this.current,
    required this.onSelect,
    required this.strings,
  });

  /// Currently selected type.
  final _CreateType current;

  /// Called when a chip is tapped.
  final ValueChanged<_CreateType> onSelect;

  /// Localized strings.
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final List<(_CreateType, String)> types =
        <(_CreateType, String)>[
      (_CreateType.text, strings.typeText),
      (_CreateType.link, strings.typeLink),
      (_CreateType.wifi, strings.typeWifi),
      (_CreateType.contact, strings.typeContact),
      (_CreateType.email, strings.typeEmail),
      (_CreateType.phone, strings.typePhone),
      (_CreateType.sms, strings.typeSms),
      (_CreateType.location, strings.typeLocation),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final (_CreateType, String) t in types) ...<Widget>[
            DesignChip(
              label: t.$2,
              selected: current == t.$1,
              onTap: () => onSelect(t.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// Live QR preview card; shows a placeholder when the payload is empty.
class _PreviewCard extends StatelessWidget {
  /// Creates the preview card.
  const _PreviewCard({
    required this.payload,
    required this.color,
    required this.ec,
  });

  /// Current QR payload; empty means "show placeholder".
  final String payload;

  /// QR module color.
  final Color color;

  /// Error-correction level (qr_flutter int constant).
  final int ec;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: payload.isEmpty
              ? Icon(
                  Icons.qr_code_2,
                  size: 120,
                  color: (dark ? Colors.white : AppColors.ink)
                      .withValues(alpha: 0.18),
                )
              : QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  errorCorrectionLevel: ec,
                  size: 260,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: color,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: color,
                  ),
                  backgroundColor: Colors.white,
                ),
        ),
      ),
    );
  }
}

/// Amber banner shown when the chosen QR color may scan poorly.
class _WarningBanner extends StatelessWidget {
  /// Creates the warning banner.
  const _WarningBanner({required this.text});

  /// Warning message.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.voltYellow.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.voltYellow),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.warning_amber, color: AppColors.ink),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Three QR color swatches (ink / blue / green).
class _ColorRow extends StatelessWidget {
  /// Creates the color swatch row.
  const _ColorRow({
    required this.selectedKey,
    required this.strings,
    required this.onSelect,
  });

  /// Currently selected color key.
  final String selectedKey;

  /// Localized strings.
  final AppStrings strings;

  /// Called with the picked color key.
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<(String, Color, String)> colors = <(String, Color, String)>[
      ('ink', AppColors.ink, strings.colorInk),
      ('blue', AppColors.electricBlue, strings.colorBlue),
      ('green', AppColors.success, strings.colorGreen),
    ];
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            strings.labelColor.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        for (final (String, Color, String) c in colors)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Semantics(
              button: true,
              selected: selectedKey == c.$1,
              label: c.$3,
              child: InkWell(
                onTap: () => onSelect(c.$1),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.$2,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedKey == c.$1
                          ? AppColors.voltYellow
                          : AppColors.line.withValues(alpha: 0.9),
                      width: selectedKey == c.$1 ? 4 : 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
