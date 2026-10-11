// Settings screen: grouped toggles and pickers for scanning, safety,
// history, appearance, create defaults, plus history export/import and
// the about section.
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../services/actions.dart';
import '../history/history_export.dart';
import '../history/history_repository.dart';
import 'settings_model.dart';
import 'settings_repository.dart';

/// Small value/label pair used by the option picker dialog.
class _Option<T> {
  /// Creates an option.
  const _Option(this.value, this.label);

  /// The stored value.
  final T value;

  /// The user-visible label.
  final String label;
}

/// App settings screen.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  // ---------------------------------------------------------------- helpers
  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _refreshHistory(WidgetRef ref) {
    ref.read(historyRepositoryProvider.notifier).refresh();
  }

  Future<void> _pickOption<T>(
    BuildContext context,
    String title,
    List<_Option<T>> options,
    T current,
    ValueChanged<T> onPick,
  ) async {
    final T? v = await showDialog<T>(
      context: context,
      builder: (BuildContext c) => SimpleDialog(
        title: Text(title),
        children: <Widget>[
          for (final _Option<T> o in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(c).pop(o.value),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(o.label)),
                  if (o.value == current)
                    const Icon(Icons.check, color: Colors.green),
                ],
              ),
            ),
        ],
      ),
    );
    if (v != null) onPick(v);
  }

  Widget _header(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.secondary),
      ),
    );
  }

  Widget _dropdownTile<T>({
    required String title,
    required String currentLabel,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(currentLabel),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
      minVerticalPadding: 12,
    );
  }

  Future<void> _showFormatsDialog(BuildContext context, AppStrings s) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: Text(s.scanFormatsTitle),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('QR', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('QR, Aztec, Data Matrix, PDF417, Micro QR'),
              SizedBox(height: 12),
              Text('Barcode', style: TextStyle(fontWeight: FontWeight.w700)),
              Text(
                'EAN-13, EAN-8, UPC-A, UPC-E, Code 128, Code 39, '
                'Code 93, ITF, Codabar',
              ),
              SizedBox(height: 12),
              Text('Batch', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('All of the above'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: Text(s.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    WidgetRef ref,
    AppStrings s,
  ) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: Text(s.clearAllTitle),
        content: Text(s.clearAllBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(s.clearAll),
          ),
        ],
      ),
    );
    if (yes == true) {
      await ref.read(historyRepositoryProvider.notifier).clearAll();
      _refreshHistory(ref);
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final AppStrings s = ref.read(appStringsProvider);
    try {
      final XFile? file = await exportAllCsv(ref);
      if (file != null) {
        await BoltActions.shareFile(file);
      }
    } catch (_) {
      if (context.mounted) _snack(context, s.error);
    }
    _refreshHistory(ref);
  }

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    final AppStrings s = ref.read(appStringsProvider);
    try {
      final XFile? file = await exportAllJson(ref);
      if (file != null) {
        await BoltActions.shareFile(file);
      }
    } catch (_) {
      if (context.mounted) _snack(context, s.error);
    }
    _refreshHistory(ref);
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final AppStrings s = ref.read(appStringsProvider);
    try {
      // file_picker 13.1.0 returns List<PlatformFile> (empty when canceled).
      final List<PlatformFile> picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['json'],
      );
      if (picked.isEmpty) return;
      final String? path = picked.first.path;
      if (path == null) {
        if (context.mounted) _snack(context, s.importFailed);
        return;
      }
      final int n = await importBackupFile(ref, path);
      if (context.mounted) _snack(context, s.importedCount(n));
    } catch (_) {
      if (context.mounted) _snack(context, s.importFailed);
    }
    _refreshHistory(ref);
  }

  // ------------------------------------------------------------------- build
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = ref.watch(appStringsProvider);
    final SettingsModel settings = ref.watch(settingsProvider);
    final SettingsRepository repo = ref.read(settingsProvider.notifier);

    String modeLabel(String v) {
      switch (v) {
        case 'barcode':
          return s.modeBarcode;
        case 'batch':
          return s.modeBatch;
        case 'qr':
        default:
          return s.modeQr;
      }
    }

    String hapticLabel(String v) {
      switch (v) {
        case 'light':
          return s.hapticLight;
        case 'heavy':
          return s.hapticHeavy;
        case 'medium':
        default:
          return s.hapticMedium;
      }
    }

    String limitLabel(int v) => v == 0 ? s.limitUnlimited : '$v';

    String themeLabel(String v) {
      switch (v) {
        case 'light':
          return s.themeLight;
        case 'dark':
          return s.themeDark;
        case 'system':
        default:
          return s.themeSystem;
      }
    }

    String langLabel(String v) {
      switch (v) {
        case 'ur':
          return s.langUrdu;
        case 'ps':
          return s.langPashto;
        case 'en':
        default:
          return s.langEnglish;
      }
    }

    String colorLabel(String v) {
      switch (v) {
        case 'blue':
          return s.colorBlue;
        case 'green':
          return s.colorGreen;
        case 'ink':
        default:
          return s.colorInk;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          _header(context, s.sectionScanning),
          Card(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  title: Text(s.vibrateOnScan),
                  value: settings.vibrateOnScan,
                  onChanged: repo.setVibrateOnScan,
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(s.beepOnScan),
                  value: settings.beepOnScan,
                  onChanged: repo.setBeepOnScan,
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(s.continuousScan),
                  value: settings.continuousScan,
                  onChanged: repo.setContinuousScan,
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(s.flashOnDefault),
                  value: settings.flashOnDefault,
                  onChanged: repo.setFlashOnDefault,
                ),
                const Divider(),
                _dropdownTile<String>(
                  title: s.defaultMode,
                  currentLabel: modeLabel(settings.defaultMode),
                  onTap: () => _pickOption<String>(
                    context,
                    s.defaultMode,
                    <_Option<String>>[
                      _Option<String>('qr', s.modeQr),
                      _Option<String>('barcode', s.modeBarcode),
                      _Option<String>('batch', s.modeBatch),
                    ],
                    settings.defaultMode,
                    repo.setDefaultMode,
                  ),
                ),
                const Divider(),
                _dropdownTile<String>(
                  title: s.hapticStrength,
                  currentLabel: hapticLabel(settings.hapticStrength),
                  onTap: () => _pickOption<String>(
                    context,
                    s.hapticStrength,
                    <_Option<String>>[
                      _Option<String>('light', s.hapticLight),
                      _Option<String>('medium', s.hapticMedium),
                      _Option<String>('heavy', s.hapticHeavy),
                    ],
                    settings.hapticStrength,
                    repo.setHapticStrength,
                  ),
                ),
                const Divider(),
                ListTile(
                  title: Text(s.scanFormatsTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showFormatsDialog(context, s),
                  minVerticalPadding: 12,
                ),
              ],
            ),
          ),
          _header(context, s.sectionSafety),
          Card(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  title: Text(s.autoOpenLinks),
                  value: settings.autoOpenLinks,
                  onChanged: repo.setAutoOpenLinks,
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(s.showFullUrl),
                  value: settings.showFullUrl,
                  onChanged: repo.setShowFullUrl,
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(s.warnSuspicious),
                  value: settings.warnSuspicious,
                  onChanged: repo.setWarnSuspicious,
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(s.autoCopy),
                  value: settings.autoCopy,
                  onChanged: repo.setAutoCopy,
                ),
              ],
            ),
          ),
          _header(context, s.sectionHistory),
          Card(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  title: Text(s.saveHistory),
                  value: settings.saveHistory,
                  onChanged: repo.setSaveHistory,
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(s.keepDuplicates),
                  value: settings.keepDuplicates,
                  onChanged: repo.setKeepDuplicates,
                ),
                const Divider(),
                _dropdownTile<int>(
                  title: s.historyLimit,
                  currentLabel: limitLabel(settings.historyLimit),
                  onTap: () => _pickOption<int>(
                    context,
                    s.historyLimit,
                    <_Option<int>>[
                      const _Option<int>(100, '100'),
                      const _Option<int>(500, '500'),
                      const _Option<int>(1000, '1000'),
                      _Option<int>(0, s.limitUnlimited),
                    ],
                    settings.historyLimit,
                    repo.setHistoryLimit,
                  ),
                ),
                const Divider(),
                ListTile(
                  title: Text(s.exportCsv),
                  leading: const Icon(Icons.table_chart_outlined),
                  onTap: () => _exportCsv(context, ref),
                  minVerticalPadding: 12,
                ),
                const Divider(),
                ListTile(
                  title: Text(s.exportJson),
                  leading: const Icon(Icons.data_object),
                  onTap: () => _exportJson(context, ref),
                  minVerticalPadding: 12,
                ),
                const Divider(),
                ListTile(
                  title: Text(s.importBackup),
                  leading: const Icon(Icons.upload_file_outlined),
                  onTap: () => _importBackup(context, ref),
                  minVerticalPadding: 12,
                ),
                const Divider(),
                ListTile(
                  title: Text(
                    s.clearAll,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onTap: () => _confirmClearAll(context, ref, s),
                  minVerticalPadding: 12,
                ),
              ],
            ),
          ),
          _header(context, s.sectionAppearance),
          Card(
            child: Column(
              children: <Widget>[
                _dropdownTile<String>(
                  title: s.theme,
                  currentLabel: themeLabel(settings.themeMode),
                  onTap: () => _pickOption<String>(
                    context,
                    s.theme,
                    <_Option<String>>[
                      _Option<String>('system', s.themeSystem),
                      _Option<String>('light', s.themeLight),
                      _Option<String>('dark', s.themeDark),
                    ],
                    settings.themeMode,
                    repo.setThemeMode,
                  ),
                ),
                const Divider(),
                _dropdownTile<String>(
                  title: s.language,
                  currentLabel: langLabel(settings.language),
                  onTap: () => _pickOption<String>(
                    context,
                    s.language,
                    <_Option<String>>[
                      _Option<String>('en', s.langEnglish),
                      _Option<String>('ur', s.langUrdu),
                      _Option<String>('ps', s.langPashto),
                    ],
                    settings.language,
                    repo.setLanguage,
                  ),
                ),
              ],
            ),
          ),
          _header(context, s.sectionCreate),
          Card(
            child: Column(
              children: <Widget>[
                _dropdownTile<String>(
                  title: s.defaultEcLevel,
                  currentLabel: settings.ecLevel,
                  onTap: () => _pickOption<String>(
                    context,
                    s.defaultEcLevel,
                    const <_Option<String>>[
                      _Option<String>('L', 'L'),
                      _Option<String>('M', 'M'),
                      _Option<String>('Q', 'Q'),
                      _Option<String>('H', 'H'),
                    ],
                    settings.ecLevel,
                    repo.setEcLevel,
                  ),
                ),
                const Divider(),
                _dropdownTile<String>(
                  title: s.defaultQrColor,
                  currentLabel: colorLabel(settings.defaultQrColor),
                  onTap: () => _pickOption<String>(
                    context,
                    s.defaultQrColor,
                    <_Option<String>>[
                      _Option<String>('ink', s.colorInk),
                      _Option<String>('blue', s.colorBlue),
                      _Option<String>('green', s.colorGreen),
                    ],
                    settings.defaultQrColor,
                    repo.setDefaultQrColor,
                  ),
                ),
              ],
            ),
          ),
          _header(context, s.sectionAbout),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  title: Text(s.versionLabel),
                  trailing: Text(
                    '1.0.0+1',
                    style: AppText.mono(context),
                  ),
                  minVerticalPadding: 12,
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(s.privacyNote),
                ),
                const Divider(),
                ListTile(
                  title: Text(s.licensesTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(context: context),
                  minVerticalPadding: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
