import 'package:boltscan/core/l10n/strings.dart';
import 'package:boltscan/core/theme/app_colors.dart';
import 'package:boltscan/core/theme/app_theme.dart';
import 'package:boltscan/core/utils/scan_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One detected code highlight: its [index] and its [rect] in overlay
/// coordinates.
class DetectedRing {
  /// Creates a detection ring.
  const DetectedRing({
    required this.index,
    required this.rect,
  });

  /// Zero-based code index; shown as [index] + 1 in the badge.
  final int index;

  /// Bounding box of the code, in overlay coordinates.
  final Rect rect;
}

/// Dark scan viewfinder: a centered target box with yellow corner brackets,
/// a sweeping scan line, and tappable numbered rings for multi-code results.
///
/// QR/batch modes use a 264x264 square; barcode mode a 300x170 rectangle.
/// The scan line sweeps over 1400ms (repeat/reverse); it is a static centered
/// line when [MediaQuery.disableAnimations] is true.
class ViewfinderOverlay extends StatefulWidget {
  /// Creates a viewfinder overlay for [mode].
  const ViewfinderOverlay({
    super.key,
    required this.mode,
    this.rings = const <DetectedRing>[],
    this.onRingTap,
  });

  /// Scan mode driving the target box shape.
  final ScanMode mode;

  /// Detected-code highlights, drawn over the full overlay.
  final List<DetectedRing> rings;

  /// Called with the ring index when a ring is tapped.
  final ValueChanged<int>? onRingTap;

  @override
  State<ViewfinderOverlay> createState() => _ViewfinderOverlayState();
}

class _ViewfinderOverlayState extends State<ViewfinderOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion && _controller != null) {
      _controller!.dispose();
      _controller = null;
    } else if (!reduceMotion && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size box = widget.mode == ScanMode.barcode
        ? const Size(300, 170)
        : const Size(264, 264);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width =
            box.width > constraints.maxWidth - 32 ? constraints.maxWidth - 32 : box.width;
        final double height =
            box.height > constraints.maxHeight - 32 ? constraints.maxHeight - 32 : box.height;
        return Stack(
          children: <Widget>[
            Center(
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: <Widget>[
                    const Positioned.fill(
                      child: CustomPaint(painter: _CornerPainter()),
                    ),
                    if (_controller == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: _ScanLine(),
                        ),
                      )
                    else
                      AnimatedBuilder(
                        animation: _controller!,
                        builder: (BuildContext context, Widget? child) {
                          final double top =
                              8 + _controller!.value * (height - 18);
                          return Positioned(
                            top: top,
                            left: 16,
                            right: 16,
                            child: child!,
                          );
                        },
                        child: const _ScanLine(),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.rings.isNotEmpty)
              Positioned.fill(
                child: Consumer(
                  builder:
                      (BuildContext context, WidgetRef ref, Widget? _) {
                    final AppStrings strings =
                        ref.watch(appStringsProvider);
                    return Stack(
                      children: <Widget>[
                        for (final DetectedRing ring in widget.rings)
                          _ring(context, strings, ring),
                      ],
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  /// Tappable highlight ring with a numbered badge.
  Widget _ring(BuildContext context, AppStrings strings, DetectedRing ring) {
    return Positioned.fromRect(
      rect: ring.rect,
      child: Semantics(
        button: true,
        label: '${ring.index + 1}',
        hint: strings.tapToSelectCode,
        onTap: () => widget.onRingTap?.call(ring.index),
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () => widget.onRingTap?.call(ring.index),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              const Positioned.fill(
                child: CustomPaint(painter: _RingPainter()),
              ),
              Positioned(
                top: -12,
                right: -12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.voltYellow,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${ring.index + 1}',
                    style: AppText.mono(
                      context,
                      fontSize: 12,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal 2px volt-yellow gradient scan line.
class _ScanLine extends StatelessWidget {
  const _ScanLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.voltYellow.withValues(alpha: 0),
            AppColors.voltYellow,
            AppColors.voltYellow.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// Four rounded yellow corner brackets around the target box.
class _CornerPainter extends CustomPainter {
  const _CornerPainter();

  static const double _length = 34;
  static const double _radius = 12;
  static const double _stroke = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.voltYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    final double w = size.width;
    final double h = size.height;

    void bracket(Path Function(Path) build) {
      canvas.drawPath(build(Path()), paint);
    }

    // Top-left.
    bracket((Path p) => p
      ..moveTo(_length, 0)
      ..lineTo(_radius, 0)
      ..quadraticBezierTo(0, 0, 0, _radius)
      ..lineTo(0, _length));
    // Top-right.
    bracket((Path p) => p
      ..moveTo(w - _length, 0)
      ..lineTo(w - _radius, 0)
      ..quadraticBezierTo(w, 0, w, _radius)
      ..lineTo(w, _length));
    // Bottom-left.
    bracket((Path p) => p
      ..moveTo(0, h - _length)
      ..lineTo(0, h - _radius)
      ..quadraticBezierTo(0, h, _radius, h)
      ..lineTo(_length, h));
    // Bottom-right.
    bracket((Path p) => p
      ..moveTo(w, h - _length)
      ..lineTo(w, h - _radius)
      ..quadraticBezierTo(w, h, w - _radius, h)
      ..lineTo(w - _length, h));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Rounded-rect outline for a detected code ring.
class _RingPainter extends CustomPainter {
  const _RingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.voltYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(10),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
