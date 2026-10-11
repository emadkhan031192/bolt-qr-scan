// Loads/saves settings with shared_preferences. Read lazily in the
// background after the first frame so the camera is never blocked.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_model.dart';

class SettingsRepository extends Notifier<SettingsModel> {
  SharedPreferences? _prefs;

  @override
  SettingsModel build() {
    _loadAsync();
    return const SettingsModel();
  }

  Future<void> _loadAsync() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final SharedPreferences p = _prefs!;
      state = SettingsModel(
        vibrateOnScan: p.getBool(SettingsKeys.vibrateOnScan) ?? true,
        beepOnScan: p.getBool(SettingsKeys.beepOnScan) ?? false,
        continuousScan: p.getBool(SettingsKeys.continuousScan) ?? false,
        defaultMode: p.getString(SettingsKeys.defaultMode) ?? 'qr',
        flashOnDefault: p.getBool(SettingsKeys.flashOnDefault) ?? false,
        hapticStrength: p.getString(SettingsKeys.hapticStrength) ?? 'medium',
        autoOpenLinks: p.getBool(SettingsKeys.autoOpenLinks) ?? false,
        showFullUrl: p.getBool(SettingsKeys.showFullUrl) ?? true,
        warnSuspicious: p.getBool(SettingsKeys.warnSuspicious) ?? true,
        autoCopy: p.getBool(SettingsKeys.autoCopy) ?? false,
        saveHistory: p.getBool(SettingsKeys.saveHistory) ?? true,
        historyLimit: p.getInt(SettingsKeys.historyLimit) ?? 500,
        keepDuplicates: p.getBool(SettingsKeys.keepDuplicates) ?? false,
        themeMode: p.getString(SettingsKeys.themeMode) ?? 'system',
        language: p.getString(SettingsKeys.language) ?? 'en',
        ecLevel: p.getString(SettingsKeys.ecLevel) ?? 'M',
        defaultQrColor: p.getString(SettingsKeys.defaultQrColor) ?? 'ink',
      );
    } catch (_) {
      // Keep defaults on storage failure.
    }
  }

  Future<void> _saveBool(String key, bool value) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setBool(key, value);
    } catch (_) {}
  }

  Future<void> _saveString(String key, String value) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(key, value);
    } catch (_) {}
  }

  Future<void> _saveInt(String key, int value) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setInt(key, value);
    } catch (_) {}
  }

  Future<void> setVibrateOnScan(bool v) async {
    state = state.copyWith(vibrateOnScan: v);
    await _saveBool(SettingsKeys.vibrateOnScan, v);
  }

  Future<void> setBeepOnScan(bool v) async {
    state = state.copyWith(beepOnScan: v);
    await _saveBool(SettingsKeys.beepOnScan, v);
  }

  Future<void> setContinuousScan(bool v) async {
    state = state.copyWith(continuousScan: v);
    await _saveBool(SettingsKeys.continuousScan, v);
  }

  Future<void> setDefaultMode(String v) async {
    state = state.copyWith(defaultMode: v);
    await _saveString(SettingsKeys.defaultMode, v);
  }

  Future<void> setFlashOnDefault(bool v) async {
    state = state.copyWith(flashOnDefault: v);
    await _saveBool(SettingsKeys.flashOnDefault, v);
  }

  Future<void> setHapticStrength(String v) async {
    state = state.copyWith(hapticStrength: v);
    await _saveString(SettingsKeys.hapticStrength, v);
  }

  Future<void> setAutoOpenLinks(bool v) async {
    state = state.copyWith(autoOpenLinks: v);
    await _saveBool(SettingsKeys.autoOpenLinks, v);
  }

  Future<void> setShowFullUrl(bool v) async {
    state = state.copyWith(showFullUrl: v);
    await _saveBool(SettingsKeys.showFullUrl, v);
  }

  Future<void> setWarnSuspicious(bool v) async {
    state = state.copyWith(warnSuspicious: v);
    await _saveBool(SettingsKeys.warnSuspicious, v);
  }

  Future<void> setAutoCopy(bool v) async {
    state = state.copyWith(autoCopy: v);
    await _saveBool(SettingsKeys.autoCopy, v);
  }

  Future<void> setSaveHistory(bool v) async {
    state = state.copyWith(saveHistory: v);
    await _saveBool(SettingsKeys.saveHistory, v);
  }

  Future<void> setHistoryLimit(int v) async {
    state = state.copyWith(historyLimit: v);
    await _saveInt(SettingsKeys.historyLimit, v);
  }

  Future<void> setKeepDuplicates(bool v) async {
    state = state.copyWith(keepDuplicates: v);
    await _saveBool(SettingsKeys.keepDuplicates, v);
  }

  Future<void> setThemeMode(String v) async {
    state = state.copyWith(themeMode: v);
    await _saveString(SettingsKeys.themeMode, v);
  }

  Future<void> setLanguage(String v) async {
    state = state.copyWith(language: v);
    await _saveString(SettingsKeys.language, v);
  }

  Future<void> setEcLevel(String v) async {
    state = state.copyWith(ecLevel: v);
    await _saveString(SettingsKeys.ecLevel, v);
  }

  Future<void> setDefaultQrColor(String v) async {
    state = state.copyWith(defaultQrColor: v);
    await _saveString(SettingsKeys.defaultQrColor, v);
  }
}
