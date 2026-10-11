// Settings keys + immutable model. Persisted via SettingsRepository
// (shared_preferences) and exposed through settingsProvider.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_repository.dart';

/// All persisted settings keys. Defaults match the spec.
class SettingsKeys {
  const SettingsKeys._();

  // Scanning
  static const String vibrateOnScan = 'vibrate_on_scan';
  static const String beepOnScan = 'beep_on_scan';
  static const String continuousScan = 'continuous_scan';
  static const String defaultMode = 'default_mode'; // 'qr' | 'barcode' | 'batch'
  static const String flashOnDefault = 'flash_on_default';
  static const String hapticStrength = 'haptic_strength'; // light|medium|heavy

  // Safety
  static const String autoOpenLinks = 'auto_open_links';
  static const String showFullUrl = 'show_full_url';
  static const String warnSuspicious = 'warn_suspicious';
  static const String autoCopy = 'auto_copy';

  // History
  static const String saveHistory = 'save_history';
  static const String historyLimit = 'history_limit'; // 100|500|1000|0(unlimited)
  static const String keepDuplicates = 'keep_duplicates';

  // Appearance
  static const String themeMode = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const String language = 'language'; // 'en' | 'ur' | 'ps'

  // Create
  static const String ecLevel = 'ec_level'; // 'L' | 'M' | 'Q' | 'H'
  static const String defaultQrColor = 'default_qr_color'; // 'ink'|'blue'|'green'
}

/// Immutable snapshot of every user setting.
class SettingsModel {
  const SettingsModel({
    this.vibrateOnScan = true,
    this.beepOnScan = false,
    this.continuousScan = false,
    this.defaultMode = 'qr',
    this.flashOnDefault = false,
    this.hapticStrength = 'medium',
    this.autoOpenLinks = false,
    this.showFullUrl = true,
    this.warnSuspicious = true,
    this.autoCopy = false,
    this.saveHistory = true,
    this.historyLimit = 500,
    this.keepDuplicates = false,
    this.themeMode = 'system',
    this.language = 'en',
    this.ecLevel = 'M',
    this.defaultQrColor = 'ink',
  });

  final bool vibrateOnScan;
  final bool beepOnScan;
  final bool continuousScan;
  final String defaultMode;
  final bool flashOnDefault;
  final String hapticStrength;
  final bool autoOpenLinks;
  final bool showFullUrl;
  final bool warnSuspicious;
  final bool autoCopy;
  final bool saveHistory;
  final int historyLimit;
  final bool keepDuplicates;
  final String themeMode;
  final String language;
  final String ecLevel;
  final String defaultQrColor;

  SettingsModel copyWith({
    bool? vibrateOnScan,
    bool? beepOnScan,
    bool? continuousScan,
    String? defaultMode,
    bool? flashOnDefault,
    String? hapticStrength,
    bool? autoOpenLinks,
    bool? showFullUrl,
    bool? warnSuspicious,
    bool? autoCopy,
    bool? saveHistory,
    int? historyLimit,
    bool? keepDuplicates,
    String? themeMode,
    String? language,
    String? ecLevel,
    String? defaultQrColor,
  }) =>
      SettingsModel(
        vibrateOnScan: vibrateOnScan ?? this.vibrateOnScan,
        beepOnScan: beepOnScan ?? this.beepOnScan,
        continuousScan: continuousScan ?? this.continuousScan,
        defaultMode: defaultMode ?? this.defaultMode,
        flashOnDefault: flashOnDefault ?? this.flashOnDefault,
        hapticStrength: hapticStrength ?? this.hapticStrength,
        autoOpenLinks: autoOpenLinks ?? this.autoOpenLinks,
        showFullUrl: showFullUrl ?? this.showFullUrl,
        warnSuspicious: warnSuspicious ?? this.warnSuspicious,
        autoCopy: autoCopy ?? this.autoCopy,
        saveHistory: saveHistory ?? this.saveHistory,
        historyLimit: historyLimit ?? this.historyLimit,
        keepDuplicates: keepDuplicates ?? this.keepDuplicates,
        themeMode: themeMode ?? this.themeMode,
        language: language ?? this.language,
        ecLevel: ecLevel ?? this.ecLevel,
        defaultQrColor: defaultQrColor ?? this.defaultQrColor,
      );
}

/// Riverpod provider for settings. Overridden in tests.
final settingsProvider =
    NotifierProvider<SettingsRepository, SettingsModel>(SettingsRepository.new);
