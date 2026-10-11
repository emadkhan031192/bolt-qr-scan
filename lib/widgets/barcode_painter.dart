import 'package:flutter/material.dart';

/// Renders an EAN-13, EAN-8 or UPC-A barcode strip from [digits].
///
/// Bars use the theme's on-surface color on a transparent background, so the
/// strip can sit on any card. Guard bars are drawn longer than data bars.
/// If [digits] contains non-digit characters or has an unsupported length,
/// nothing is drawn.
class BarcodeStrip extends StatelessWidget {
  /// Creates a barcode strip for [digits].
  const BarcodeStrip({
    super.key,
    required this.digits,
    this.height = 72,
  });

  /// Raw digit string (8, 12 or 13 digits).
  final String digits;

  /// Strip height; width stretches to the available space.
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarcodePainter(
          digits: digits,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Encoded modules plus guard-bar ranges (half-open [start, end) indices).
class _BarcodeSpec {
  const _BarcodeSpec(this.modules, this.guardRanges);

  /// '0'/'1' string, one char per module.
  final String modules;

  /// Guard ranges drawn longer than data bars.
  final List<(int, int)> guardRanges;

  /// Empty spec: painter draws nothing.
  static const _BarcodeSpec empty = _BarcodeSpec('', <(int, int)>[]);
}

/// Painter for EAN-13 / EAN-8 / UPC-A bars with extended guard bars.
class _BarcodePainter extends CustomPainter {
  /// Creates a painter; encodes [digits] up front so [paint] allocates once.
  _BarcodePainter({
    required this.digits,
    required this.color,
  }) : _spec = _encode(digits);

  /// Original digit string (used by [shouldRepaint]).
  final String digits;

  /// Bar color.
  final Color color;

  final _BarcodeSpec _spec;

  /// L-code patterns for digits 0-9.
  static const List<String> _lCode = <String>[
    '0001101',
    '0011001',
    '0010011',
    '0111101',
    '0100011',
    '0110001',
    '0101111',
    '0111011',
    '0110111',
    '0001011',
  ];

  /// First-digit parity patterns for EAN-13 left halves.
  static const List<String> _ean13Parity = <String>[
    'LLLLLL',
    'LLGLGG',
    'LLGGLG',
    'LLGGGL',
    'LGLLGG',
    'LGGLLG',
    'LGGGLL',
    'LGLGLG',
    'LGLGGL',
    'LGGLGL',
  ];

  /// Pattern for [digit] in the given set: 'L', 'G' (reversed L) or 'R'
  /// (inverted L).
  static String _pattern(int digit, String set) {
    final String l = _lCode[digit];
    switch (set) {
      case 'G':
        return l.split('').reversed.join();
      case 'R':
        return l
            .split('')
            .map((String c) => c == '1' ? '0' : '1')
            .join();
      default:
        return l;
    }
  }

  /// Encodes [digits] into modules + guard ranges; empty spec on bad input.
  static _BarcodeSpec _encode(String digits) {
    if (digits.length != 8 && digits.length != 12 && digits.length != 13) {
      return _BarcodeSpec.empty;
    }
    final List<int> values = <int>[];
    for (int i = 0; i < digits.length; i++) {
      final int unit = digits.codeUnitAt(i);
      if (unit < 0x30 || unit > 0x39) {
        return _BarcodeSpec.empty;
      }
      values.add(unit - 0x30);
    }

    final StringBuffer left = StringBuffer();
    final StringBuffer right = StringBuffer();
    if (digits.length == 13) {
      final String parity = _ean13Parity[values[0]];
      for (int i = 0; i < 6; i++) {
        left.write(_pattern(values[i + 1], parity[i]));
      }
      for (int i = 7; i < 13; i++) {
        right.write(_pattern(values[i], 'R'));
      }
    } else if (digits.length == 8) {
      for (int i = 0; i < 4; i++) {
        left.write(_pattern(values[i], 'L'));
      }
      for (int i = 4; i < 8; i++) {
        right.write(_pattern(values[i], 'R'));
      }
    } else {
      // UPC-A: 12 digits, all-left L, all-right R.
      for (int i = 0; i < 6; i++) {
        left.write(_pattern(values[i], 'L'));
      }
      for (int i = 6; i < 12; i++) {
        right.write(_pattern(values[i], 'R'));
      }
    }

    final String leftStr = left.toString();
    final String rightStr = right.toString();
    final String modules = '101$leftStr'
        '01010$rightStr'
        '101';
    final int centerStart = 3 + leftStr.length;
    final List<(int, int)> guards = <(int, int)>[
      (0, 3),
      (centerStart, centerStart + 5),
      (modules.length - 3, modules.length),
    ];
    return _BarcodeSpec(modules, guards);
  }

  bool _isGuard(int index) {
    for (final (int, int) range in _spec.guardRanges) {
      if (index >= range.$1 && index < range.$2) {
        return true;
      }
    }
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_spec.modules.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }
    final int count = _spec.modules.length;
    final double moduleWidth = size.width / count;
    // Data bars stop short; guard bars run the full height.
    final double dataHeight = size.height * 0.88;
    final Paint paint = Paint()..color = color;
    final Path path = Path();
    for (int i = 0; i < count; i++) {
      if (_spec.modules[i] == '1') {
        final double barHeight = _isGuard(i) ? size.height : dataHeight;
        path.addRect(
          Rect.fromLTWH(
            i * moduleWidth,
            size.height - barHeight,
            moduleWidth + 0.5,
            barHeight,
          ),
        );
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter oldDelegate) =>
      oldDelegate.digits != digits || oldDelegate.color != color;
}
