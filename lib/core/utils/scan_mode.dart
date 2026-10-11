/// Scan modes supported by the scan screen.
enum ScanMode {
  /// Single QR code scanning.
  qr,

  /// Single 1D barcode scanning (EAN/UPC/Code128...).
  barcode,

  /// Continuous multi-code scanning session.
  batch,
}

/// Key serialization for [ScanMode], used by settings persistence.
extension ScanModeX on ScanMode {
  /// Stable storage key for this mode ('qr', 'barcode' or 'batch').
  String get key => switch (this) {
        ScanMode.qr => 'qr',
        ScanMode.barcode => 'barcode',
        ScanMode.batch => 'batch',
      };

  /// Parses a stored key back into a [ScanMode]; defaults to [ScanMode.qr]
  /// for unknown keys.
  static ScanMode fromKey(String key) => switch (key) {
        'barcode' => ScanMode.barcode,
        'batch' => ScanMode.batch,
        _ => ScanMode.qr,
      };
}
