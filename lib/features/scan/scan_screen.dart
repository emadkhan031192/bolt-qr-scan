// Scan screen: full-screen camera, viewfinder overlay, mode selector,
// single/batch detection handling, gallery fallback, batch list panel.
// Always dark (AppColors.cameraBlack) regardless of app theme.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

import '../../core/l10n/strings.dart';
import '../../core/models/parsed_result.dart';
import '../../core/parsers/result_parser.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/scan_mode.dart';
import '../../services/actions.dart';
import '../../widgets/segmented_control.dart';
import '../../widgets/viewfinder_overlay.dart';
import '../history/history_repository.dart';
import '../result/result_screen.dart';
import '../settings/settings_model.dart';
import '../settings/settings_screen.dart';
import 'batch_sheet.dart';
import 'scan_result_sheet.dart';

/// Formats decoded per scan mode (speed optimization).
List<BarcodeFormat> _formatsFor(ScanMode mode) => switch (mode) {
      ScanMode.qr => const <BarcodeFormat>[
          BarcodeFormat.qrCode,
          BarcodeFormat.aztec,
          BarcodeFormat.dataMatrix,
          BarcodeFormat.pdf417,
          BarcodeFormat.microQrCode,
        ],
      ScanMode.barcode => const <BarcodeFormat>[
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.code93,
          BarcodeFormat.itf14,
          BarcodeFormat.codabar,
        ],
      ScanMode.batch => const <BarcodeFormat>[
          BarcodeFormat.qrCode,
          BarcodeFormat.aztec,
          BarcodeFormat.dataMatrix,
          BarcodeFormat.pdf417,
          BarcodeFormat.microQrCode,
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.code93,
          BarcodeFormat.itf14,
          BarcodeFormat.codabar,
        ],
    };

/// Camera gate state for the scan screen.
enum _CameraGate {
  checking,
  granted,
  denied,
  noCamera,
  cameraInUse,
}

/// Status-pill content: text plus whether the dot pulses.
class _PillData {
  const _PillData({required this.text, required this.pulsing});

  final String text;
  final bool pulsing;
}

/// Full-screen camera scan screen (always dark).
///
/// [onOpenHistory] switches to the History tab; [onOpenCreate] is reserved
/// for the Create tab (kept for the AppShell contract).
class ScanScreen extends ConsumerStatefulWidget {
  /// Creates the scan screen.
  const ScanScreen({
    super.key,
    required this.onOpenHistory,
    required this.onOpenCreate,
  });

  /// Called when the user taps the history button.
  final VoidCallback onOpenHistory;

  /// Called to open the Create tab (reserved for future use).
  final VoidCallback onOpenCreate;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  _CameraGate _gate = _CameraGate.checking;
  bool _permanentlyDenied = false;

  MobileScannerController? _controller;
  late ScanMode _mode;

  final Stopwatch _sessionStopwatch = Stopwatch();

  String? _lastValue;
  DateTime? _lastTime;
  bool _sheetOpen = false;
  bool _fullScreenOpen = false;
  bool _stoppedForSheet = false;

  final ValueNotifier<_PillData> _pill =
      ValueNotifier<_PillData>(const _PillData(text: '', pulsing: true));
  final ValueNotifier<List<DetectedRing>> _rings =
      ValueNotifier<List<DetectedRing>>(const <DetectedRing>[]);
  List<Barcode> _ringBarcodes = const <Barcode>[];
  final ValueNotifier<List<ParsedResult>> _batchScans =
      ValueNotifier<List<ParsedResult>>(const <ParsedResult>[]);
  final Set<String> _batchSeen = <String>{};

  Rect? _scanRect;
  Size? _previewSize;
  Size? _lastWindowSize;
  ScanMode? _lastWindowMode;

  double _zoom = 0.0;
  double _pinchBase = 0.0;
  int _zoomIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
    _mode = ScanModeX.fromKey(ref.read(settingsProvider).defaultMode);
    _pill.value = _PillData(
      text: ref.read(appStringsProvider).lookingForCode,
      pulsing: true,
    );
    _checkPermission();
  }

  @override
  void dispose() {
    _pill.dispose();
    _rings.dispose();
    _batchScans.dispose();
    final MobileScannerController? controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    _sessionStopwatch.stop();
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  // ------------------------------------------------------------ permission
  Future<void> _checkPermission() async {
    final PermissionStatus status = await Permission.camera.status;
    if (!mounted) {
      return;
    }
    if (status.isGranted || status.isLimited) {
      _createController();
    } else {
      setState(() {
        _gate = _CameraGate.denied;
        _permanentlyDenied = status.isPermanentlyDenied;
      });
    }
  }

  Future<void> _requestPermission() async {
    final PermissionStatus status = await Permission.camera.request();
    if (!mounted) {
      return;
    }
    if (status.isGranted || status.isLimited) {
      _createController();
    } else {
      setState(() {
        _gate = _CameraGate.denied;
        _permanentlyDenied = status.isPermanentlyDenied;
      });
    }
  }

  // ------------------------------------------------------------ controller
  void _createController() {
    final SettingsModel settings = ref.read(settingsProvider);
    final MobileScannerController controller = MobileScannerController(
      cameraResolution: const Size(1280, 720),
      detectionSpeed: DetectionSpeed.noDuplicates,
      detectionTimeoutMs: 250,
      formats: _formatsFor(_mode),
      torchEnabled: settings.flashOnDefault,
    );
    _controller = controller;
    _sessionStopwatch
      ..reset()
      ..start();
    _lastWindowSize = null;
    _lastWindowMode = null;
    _zoom = 0.0;
    _zoomIndex = 0;
    setState(() {
      _gate = _CameraGate.granted;
    });
    unawaited(_safeStart(controller));
  }

  Future<void> _safeStart(MobileScannerController? controller) async {
    if (controller == null) {
      return;
    }
    try {
      await controller.start();
    } catch (_) {
      // Camera errors surface through MobileScanner.errorBuilder.
    }
  }

  Future<void> _changeMode(ScanMode mode) async {
    if (mode == _mode || _gate != _CameraGate.granted) {
      return;
    }
    final MobileScannerController? old = _controller;
    final SettingsModel settings = ref.read(settingsProvider);
    final MobileScannerController controller = MobileScannerController(
      cameraResolution: const Size(1280, 720),
      detectionSpeed: DetectionSpeed.noDuplicates,
      detectionTimeoutMs: 250,
      formats: _formatsFor(mode),
      torchEnabled: settings.flashOnDefault,
    );
    _controller = controller;
    _rings.value = const <DetectedRing>[];
    _ringBarcodes = const <Barcode>[];
    _batchScans.value = const <ParsedResult>[];
    _batchSeen.clear();
    _lastValue = null;
    _lastTime = null;
    _zoom = 0.0;
    _zoomIndex = 0;
    _lastWindowSize = null;
    _lastWindowMode = null;
    _sessionStopwatch
      ..reset()
      ..start();
    _pill.value = _PillData(
      text: ref.read(appStringsProvider).lookingForCode,
      pulsing: true,
    );
    setState(() {
      _mode = mode;
    });
    if (old != null) {
      // Dispose after the frame so the unmounting MobileScanner widget
      // releases it first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(old.dispose());
      });
    }
    unawaited(_safeStart(controller));
  }

  void _retryCamera() {
    setState(() {
      _gate = _CameraGate.checking;
    });
    _createController();
  }

  // ------------------------------------------------------------ scan window
  void _maybeUpdateScanWindow(Size size) {
    _previewSize = size;
    final MobileScannerController? controller = _controller;
    if (controller == null) {
      return;
    }
    final Size box =
        _mode == ScanMode.barcode ? const Size(300, 170) : const Size(264, 264);
    final double w =
        box.width > size.width - 32 ? size.width - 32 : box.width;
    final double h =
        box.height > size.height - 32 ? size.height - 32 : box.height;
    _scanRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: w,
      height: h,
    );
    if (_lastWindowSize == size && _lastWindowMode == _mode) {
      return;
    }
    _lastWindowSize = size;
    _lastWindowMode = _mode;
    final Rect rect = _scanRect!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(controller.updateScanWindow(rect));
    });
  }

  // ------------------------------------------------------------ detection
  void _onDetect(BarcodeCapture capture) {
    if (_sheetOpen || _fullScreenOpen || !mounted) {
      return;
    }
    if (capture.barcodes.isEmpty) {
      return;
    }
    if (_mode == ScanMode.batch) {
      _handleBatch(capture);
      return;
    }
    if (capture.barcodes.length > 1) {
      _showRings(capture);
      return;
    }
    unawaited(
      _handleBarcode(
        capture.barcodes.first,
        detectionMs: _sessionStopwatch.elapsedMilliseconds,
      ),
    );
  }

  /// Multi-code capture: draw tappable rings instead of auto-opening.
  void _showRings(BarcodeCapture capture) {
    final Size? widgetSize = _previewSize;
    final Size img = capture.size;
    final AppStrings s = ref.read(appStringsProvider);
    if (widgetSize == null || img.width <= 0 || img.height <= 0) {
      unawaited(
        _handleBarcode(
          capture.barcodes.first,
          detectionMs: _sessionStopwatch.elapsedMilliseconds,
        ),
      );
      return;
    }
    // BoxFit.cover mapping from image coords to widget coords.
    final double scale = math.max(
      widgetSize.width / img.width,
      widgetSize.height / img.height,
    );
    final double dx = (widgetSize.width - img.width * scale) / 2;
    final double dy = (widgetSize.height - img.height * scale) / 2;
    final List<DetectedRing> rings = <DetectedRing>[];
    final List<Barcode> barcodes = <Barcode>[];
    for (final Barcode b in capture.barcodes) {
      if (b.corners.isEmpty) {
        continue;
      }
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = -double.infinity;
      double maxY = -double.infinity;
      for (final Offset p in b.corners) {
        final double x = p.dx * scale + dx;
        final double y = p.dy * scale + dy;
        if (x < minX) {
          minX = x;
        }
        if (y < minY) {
          minY = y;
        }
        if (x > maxX) {
          maxX = x;
        }
        if (y > maxY) {
          maxY = y;
        }
      }
      rings.add(
        DetectedRing(
          index: barcodes.length,
          rect: Rect.fromLTRB(minX - 6, minY - 6, maxX + 6, maxY + 6),
        ),
      );
      barcodes.add(b);
    }
    if (rings.isEmpty) {
      unawaited(
        _handleBarcode(
          capture.barcodes.first,
          detectionMs: _sessionStopwatch.elapsedMilliseconds,
        ),
      );
      return;
    }
    _ringBarcodes = barcodes;
    _rings.value = rings;
    _pill.value = _PillData(text: s.tapToSelectCode, pulsing: false);
  }

  void _onRingTap(int index) {
    if (index < 0 || index >= _ringBarcodes.length) {
      return;
    }
    final Barcode barcode = _ringBarcodes[index];
    _rings.value = const <DetectedRing>[];
    _ringBarcodes = const <Barcode>[];
    unawaited(
      _handleBarcode(
        barcode,
        detectionMs: _sessionStopwatch.elapsedMilliseconds,
      ),
    );
  }

  void _handleBatch(BarcodeCapture capture) {
    bool added = false;
    for (final Barcode b in capture.barcodes) {
      final String? raw = b.rawValue;
      if (raw == null || raw.isEmpty || _batchSeen.contains(raw)) {
        continue;
      }
      _batchSeen.add(raw);
      final int ms = _sessionStopwatch.elapsedMilliseconds;
      _feedback();
      final ParsedResult parsed = parseResult(
        raw,
        formatLabel: b.format.name,
        detectionMs: ms,
      );
      _batchScans.value = <ParsedResult>[..._batchScans.value, parsed];
      unawaited(
        ref.read(historyRepositoryProvider.notifier).saveScan(parsed),
      );
      added = true;
    }
    if (added && mounted) {
      final AppStrings s = ref.read(appStringsProvider);
      _pill.value = _PillData(
        text: s.batchModeCount(_batchScans.value.length),
        pulsing: false,
      );
    }
  }

  Future<void> _handleBarcode(
    Barcode barcode, {
    required int detectionMs,
  }) async {
    final String? raw = barcode.rawValue;
    if (raw == null || raw.isEmpty || !mounted) {
      return;
    }
    final DateTime now = DateTime.now();
    if (_lastValue == raw &&
        _lastTime != null &&
        now.difference(_lastTime!).inMilliseconds < 1500) {
      return;
    }
    _lastValue = raw;
    _lastTime = now;

    final SettingsModel settings = ref.read(settingsProvider);
    final AppStrings s = ref.read(appStringsProvider);

    _feedback();

    final ParsedResult parsed = parseResult(
      raw,
      formatLabel: barcode.format.name,
      detectionMs: detectionMs,
    );
    unawaited(
      ref.read(historyRepositoryProvider.notifier).saveScan(parsed),
    );
    if (settings.autoCopy) {
      await BoltActions.copyText(context, parsed.rawValue);
      if (mounted) {
        _snack(s.copiedToClipboard);
      }
    }

    _pill.value = _PillData(
      text: s.detectedIn((detectionMs / 1000).toStringAsFixed(2)),
      pulsing: false,
    );
    _rings.value = const <DetectedRing>[];
    _ringBarcodes = const <Barcode>[];

    if (parsed.kind == ResultKind.url &&
        settings.autoOpenLinks &&
        (parsed.safetyFlags.isEmpty || !settings.warnSuspicious)) {
      final ActionResult r = await BoltActions.openUrl(parsed.rawValue);
      if (!mounted) {
        return;
      }
      if (r != ActionResult.ok) {
        _snack(
          r == ActionResult.notSupported ? s.actionNotSupported : s.actionFailed,
        );
      }
    }

    bool stopped = false;
    final MobileScannerController? controller = _controller;
    if (!settings.continuousScan &&
        controller != null &&
        controller.value.isRunning) {
      try {
        await controller.stop();
        stopped = true;
      } catch (_) {
        // Camera already stopped or unavailable.
      }
    }
    if (!mounted) {
      return;
    }
    _stoppedForSheet = stopped;
    _sheetOpen = true;
    await showScanResultSheet(
      context,
      ref,
      parsed,
      onScanAgain: () {
        // Sheet already popped; resume is handled below.
      },
      onOpenFull: () {
        Navigator.of(context).pop();
        _fullScreenOpen = true;
        unawaited(
          Navigator.of(context)
              .push(
                MaterialPageRoute<void>(
                  builder: (_) => ResultScreen(
                    entry: HistoryEntry(
                      kind: parsed.kind,
                      rawValue: parsed.rawValue,
                      formatLabel: parsed.formatLabel,
                      detectionMs: parsed.detectionMs,
                      scannedAt: parsed.scannedAt,
                      title: parsed.title,
                      fields: parsed.fields,
                      safetyFlags: parsed.safetyFlags,
                    ),
                  ),
                ),
              )
              .then((_) {
            _fullScreenOpen = false;
            if (!mounted) {
              return;
            }
            _sessionStopwatch
              ..reset()
              ..start();
            _pill.value = _PillData(
              text: ref.read(appStringsProvider).lookingForCode,
              pulsing: true,
            );
            _lastValue = null;
            if (_stoppedForSheet) {
              unawaited(_safeStart(_controller));
            }
          }),
        );
      },
    );
    _sheetOpen = false;
    if (!mounted) {
      return;
    }
    if (_fullScreenOpen) {
      // ResultScreen handles the resume when it closes.
      return;
    }
    _sessionStopwatch
      ..reset()
      ..start();
    _pill.value = _PillData(text: s.lookingForCode, pulsing: true);
    _lastValue = null;
    if (stopped) {
      unawaited(_safeStart(controller));
    }
  }

  // ------------------------------------------------------------ feedback
  void _feedback() {
    final SettingsModel settings = ref.read(settingsProvider);
    if (settings.vibrateOnScan) {
      try {
        switch (settings.hapticStrength) {
          case 'light':
            unawaited(Vibration.vibrate(duration: 20, amplitude: 64));
          case 'heavy':
            unawaited(Vibration.vibrate(duration: 40, amplitude: 255));
          default:
            unawaited(Vibration.vibrate());
        }
      } catch (_) {
        // Vibration is best-effort.
      }
    }
    if (settings.beepOnScan) {
      unawaited(BoltBeep.play());
    }
  }

  // ------------------------------------------------------------ gallery
  Future<void> _scanFromGallery() async {
    final AppStrings s = ref.read(appStringsProvider);
    try {
      final XFile? file =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) {
        return;
      }
      MobileScannerController? temp;
      final MobileScannerController controller =
          _controller ?? (temp = MobileScannerController(
                formats: _formatsFor(_mode),
                autoStart: false,
              ));
      BarcodeCapture? capture;
      try {
        capture = await controller.analyzeImage(
          file.path,
          formats: _formatsFor(_mode),
        );
      } finally {
        if (temp != null) {
          unawaited(temp.dispose());
        }
      }
      if (!mounted) {
        return;
      }
      final List<Barcode> codes = capture?.barcodes ?? const <Barcode>[];
      if (codes.isEmpty) {
        _snack(s.noCodeInImage);
        return;
      }
      await _handleBarcode(codes.first, detectionMs: 0);
    } catch (_) {
      if (mounted) {
        _snack(s.noCodeInImage);
      }
    }
  }

  // ------------------------------------------------------------ batch panel
  Future<void> _exportBatchCsv() async {
    final AppStrings s = ref.read(appStringsProvider);
    final List<ParsedResult> scans = _batchScans.value;
    if (scans.isEmpty) {
      return;
    }
    try {
      final List<List<dynamic>> rows = <List<dynamic>>[
        <dynamic>['time', 'kind', 'format', 'value'],
        for (final ParsedResult p in scans)
          <dynamic>[
            p.scannedAt.toIso8601String(),
            p.kind.name,
            p.formatLabel,
            p.rawValue,
          ],
      ];
      // csv 8.x API: Csv().encode(rows) (ListToCsvConverter was removed).
      final String csvText = Csv().encode(rows);
      final Directory dir = await getTemporaryDirectory();
      final String path =
          '${dir.path}/bolt-batch-${DateTime.now().millisecondsSinceEpoch}.csv';
      await File(path).writeAsString(csvText);
      if (!mounted) {
        return;
      }
      final ActionResult r = await BoltActions.shareFile(
        XFile(path),
        text: s.batchSheetTitle,
      );
      if (!mounted) {
        return;
      }
      if (r != ActionResult.ok) {
        _snack(
          r == ActionResult.notSupported ? s.actionNotSupported : s.actionFailed,
        );
      }
    } catch (_) {
      if (mounted) {
        _snack(s.actionFailed);
      }
    }
  }

  void _clearBatch() {
    _batchScans.value = const <ParsedResult>[];
    _batchSeen.clear();
    final AppStrings s = ref.read(appStringsProvider);
    _pill.value = _PillData(text: s.lookingForCode, pulsing: true);
  }

  // ------------------------------------------------------------ zoom
  void _setZoomIndex(int index) {
    setState(() {
      _zoomIndex = index;
    });
    _zoom = index == 0 ? 0.0 : 0.5;
    unawaited(_controller?.setZoomScale(_zoom));
  }

  void _onPinchStart(ScaleStartDetails details) {
    _pinchBase = _zoom;
  }

  void _onPinchUpdate(ScaleUpdateDetails details) {
    final double z = (_pinchBase + (details.scale - 1) * 0.5).clamp(0.0, 1.0);
    if ((z - _zoom).abs() > 0.01) {
      _zoom = z;
      unawaited(_controller?.setZoomScale(z));
    }
  }

  // ------------------------------------------------------------ camera error
  Widget _cameraError(BuildContext context, MobileScannerException error) {
    final String msg = error.toString().toLowerCase();
    final bool inUse =
        msg.contains('in use') || msg.contains('inuse') || msg.contains('busy');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _gate =
            inUse ? _CameraGate.cameraInUse : _CameraGate.noCamera;
      });
    });
    return const SizedBox.shrink();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    final AppStrings s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: AppColors.cameraBlack,
      body: switch (_gate) {
        _CameraGate.checking => const Center(
            child: CircularProgressIndicator(color: AppColors.voltYellow),
          ),
        _CameraGate.denied => _permissionScreen(s),
        _CameraGate.noCamera => _errorScreen(
            s,
            title: s.noCameraTitle,
            body: s.noCameraBody,
          ),
        _CameraGate.cameraInUse => _errorScreen(
            s,
            title: s.cameraInUseTitle,
            body: s.cameraInUseBody,
          ),
        _CameraGate.granted => _cameraView(s),
      },
    );
  }

  /// Friendly camera-permission explanation with gallery fallback.
  Widget _permissionScreen(AppStrings s) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.voltYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_off_outlined,
                color: AppColors.ink,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              s.allowCameraTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.allowCameraBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: AppColors.darkMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _requestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.voltYellow,
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(48, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  s.allowCameraButton,
                  semanticsLabel: s.allowCameraButton,
                ),
              ),
            ),
            if (_permanentlyDenied) ...<Widget>[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => unawaited(openAppSettings()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 52),
                    side: const BorderSide(color: AppColors.darkLine),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(s.openSettingsButton),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: _scanFromGallery,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                minimumSize: const Size(48, 48),
              ),
              child: Text(s.scanFromGallery),
            ),
          ],
        ),
      ),
    );
  }

  /// Camera unavailable / in-use error screen with retry + gallery fallback.
  Widget _errorScreen(
    AppStrings s, {
    required String title,
    required String body,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.darkCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.no_photography_outlined,
                color: AppColors.darkMuted,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: AppColors.darkMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _retryCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.voltYellow,
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(48, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(s.retry),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _scanFromGallery,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                minimumSize: const Size(48, 48),
              ),
              child: Text(s.scanFromGallery),
            ),
          ],
        ),
      ),
    );
  }

  /// Live camera stack: preview, overlay, top bar, pill, modes, batch, row.
  Widget _cameraView(AppStrings s) {
    final MobileScannerController? controller = _controller;
    if (controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.voltYellow),
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = constraints.biggest;
        _maybeUpdateScanWindow(size);
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                onScaleStart: _onPinchStart,
                onScaleUpdate: _onPinchUpdate,
                child: MobileScanner(
                  key: ValueKey<String>('scanner-${_mode.key}'),
                  controller: controller,
                  onDetect: _onDetect,
                  scanWindow: _scanRect,
                  useAppLifecycleState: true,
                  fit: BoxFit.cover,
                  errorBuilder: _cameraError,
                ),
              ),
            ),
            Positioned.fill(
              child: ValueListenableBuilder<List<DetectedRing>>(
                valueListenable: _rings,
                builder: (
                  BuildContext context,
                  List<DetectedRing> rings,
                  Widget? _,
                ) =>
                    ViewfinderOverlay(
                  mode: _mode,
                  rings: rings,
                  onRingTap: _onRingTap,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: _topBar(s, controller)),
            ),
            _statusPillPosition(size),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ValueListenableBuilder<List<ParsedResult>>(
                      valueListenable: _batchScans,
                      builder: (
                        BuildContext context,
                        List<ParsedResult> scans,
                        Widget? _,
                      ) {
                        if (_mode != ScanMode.batch || scans.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: BatchSheet(
                            scans: scans,
                            onExportCsv: _exportBatchCsv,
                            onClear: _clearBatch,
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: BoltSegmentedControl<ScanMode>(
                        options: <SegmentedOption<ScanMode>>[
                          SegmentedOption<ScanMode>(
                            value: ScanMode.qr,
                            label: s.modeQr,
                          ),
                          SegmentedOption<ScanMode>(
                            value: ScanMode.barcode,
                            label: s.modeBarcode,
                          ),
                          SegmentedOption<ScanMode>(
                            value: ScanMode.batch,
                            label: s.modeBatch,
                          ),
                        ],
                        value: _mode,
                        onChanged: _changeMode,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _bottomRow(s),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Status pill positioned just under the viewfinder box.
  Widget _statusPillPosition(Size size) {
    final double boxH = _mode == ScanMode.barcode ? 170 : 264;
    final double bh =
        boxH > size.height - 32 ? size.height - 32 : boxH;
    return Positioned(
      top: size.height / 2 + bh / 2 + 14,
      left: 0,
      right: 0,
      child: Center(
        child: ValueListenableBuilder<_PillData>(
          valueListenable: _pill,
          builder: (BuildContext context, _PillData pill, Widget? _) =>
              _StatusPill(text: pill.text, pulsing: pill.pulsing),
        ),
      ),
    );
  }

  /// Top bar: logo chip, flash toggle, settings.
  Widget _topBar(AppStrings s, MobileScannerController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.bolt,
                  color: AppColors.voltYellow,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  s.appName,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (
              BuildContext context,
              MobileScannerState state,
              Widget? _,
            ) {
              final bool on = state.torchState == TorchState.on;
              final bool available =
                  state.torchState != TorchState.unavailable;
              return IconButton(
                icon: Icon(
                  on ? Icons.flash_on : Icons.flash_off,
                  color: on ? AppColors.voltYellow : Colors.white,
                ),
                tooltip: on ? s.flashOff : s.flashOn,
                onPressed: available
                    ? () => unawaited(controller.toggleTorch())
                    : null,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  minimumSize: const Size(48, 48),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: s.settingsTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom row: gallery, zoom 1x/2x, history.
  Widget _bottomRow(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon:
                const Icon(Icons.photo_library_outlined, color: Colors.white),
            tooltip: s.gallery,
            onPressed: _scanFromGallery,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              minimumSize: const Size(48, 48),
            ),
          ),
          SizedBox(
            width: 148,
            child: BoltSegmentedControl<int>(
              options: const <SegmentedOption<int>>[
                SegmentedOption<int>(value: 0, label: '1x'),
                SegmentedOption<int>(value: 1, label: '2x'),
              ],
              value: _zoomIndex,
              onChanged: _setZoomIndex,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: s.historyTab,
            onPressed: widget.onOpenHistory,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status pill: dark rounded pill with a pulsing yellow dot and text.
/// The pulse uses an AnimationController unless reduce-motion is on.
class _StatusPill extends StatefulWidget {
  const _StatusPill({required this.text, required this.pulsing});

  final String text;
  final bool pulsing;

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _StatusPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulsing != widget.pulsing) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    if (widget.pulsing && !reduceMotion) {
      if (!_pulse.isAnimating) {
        _pulse.repeat(reverse: true);
      }
    } else {
      _pulse.stop();
      _pulse.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget dot = Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.voltYellow,
        shape: BoxShape.circle,
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.pulsing)
            FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.25).animate(_pulse),
              child: dot,
            )
          else
            dot,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
