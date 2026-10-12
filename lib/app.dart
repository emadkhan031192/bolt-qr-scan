// App shell: Scan (no bottom bar — full-screen camera) / History / Create.
// The bottom tab bar appears on every non-scan screen, with a yellow pill
// behind the active icon.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/strings.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/create/create_screen.dart';
import 'features/history/history_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/settings/settings_model.dart';

/// Active bottom-tab index. 0 = Scan, 1 = History, 2 = Create.
final mainTabProvider = NotifierProvider<MainTabNotifier, int>(
  MainTabNotifier.new,
);

class MainTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

class BoltApp extends ConsumerWidget {
  const BoltApp({super.key});

  ThemeMode _themeMode(String setting) => switch (setting) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Locale _locale(String language) => switch (language) {
        'ur' => const Locale('ur'),
        'ps' => const Locale('ps'),
        _ => const Locale('en'),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsModel settings = ref.watch(settingsProvider);
    return MaterialApp(
      title: 'Bolt QR Scan and Generator',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: _themeMode(settings.themeMode),
      locale: _locale(settings.language),
      supportedLocales: const <Locale>[
        Locale('en'),
        Locale('ur'),
        Locale('ps'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int tab = ref.watch(mainTabProvider);
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: <Widget>[
          ScanScreen(
            onOpenHistory: () =>
                ref.read(mainTabProvider.notifier).setTab(1),
            onOpenCreate: () =>
                ref.read(mainTabProvider.notifier).setTab(2),
          ),
          const HistoryScreen(),
          const CreateScreen(),
        ],
      ),
      bottomNavigationBar: tab == 0
          ? null
          : _BoltTabBar(
              current: tab,
              onTap: (int i) =>
                  ref.read(mainTabProvider.notifier).setTab(i),
            ),
    );
  }
}

/// Bottom tab bar matching the design: a yellow pill behind the active
/// icon, muted icon + label otherwise.
class _BoltTabBar extends ConsumerWidget {
  const _BoltTabBar({required this.current, required this.onTap});

  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = ref.watch(appStringsProvider);
    final ThemeData theme = Theme.of(context);
    final List<(_TabItem, String)> items = <(_TabItem, String)>[
      (
        const _TabItem(
          icon: Icons.qr_code_scanner_outlined,
          activeIcon: Icons.qr_code_scanner,
        ),
        s.scanTab
      ),
      (
        const _TabItem(
          icon: Icons.history_outlined,
          activeIcon: Icons.history,
        ),
        s.historyTab
      ),
      (
        const _TabItem(
          icon: Icons.add_box_outlined,
          activeIcon: Icons.add_box,
        ),
        s.createTab
      ),
    ];
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: AppColors.line.withValues(alpha: 0.7),
            ),
          ),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: _TabButton(
                  item: items[i].$1,
                  label: items[i].$2,
                  active: current == i,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.activeIcon});

  final IconData icon;
  final IconData activeIcon;
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final _TabItem item;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color fg = active
        ? AppColors.ink
        : theme.colorScheme.onSurface.withValues(alpha: 0.55);
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.voltYellow : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                active ? item.activeIcon : item.icon,
                size: 24,
                color: fg,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: fg,
                fontWeight:
                    active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
