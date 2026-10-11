// App shell: Scan (no bottom bar — full-screen camera) / History / Create.
// The bottom tab bar appears on every non-scan screen, with a yellow pill
// behind the active icon.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/strings.dart';
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
    final AppStrings s = ref.watch(appStringsProvider);
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
          : NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (int i) =>
                  ref.read(mainTabProvider.notifier).setTab(i),
              destinations: <NavigationDestination>[
                NavigationDestination(
                  icon: const Icon(Icons.qr_code_scanner_outlined),
                  selectedIcon: const Icon(Icons.qr_code_scanner),
                  label: s.scanTab,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.history_outlined),
                  selectedIcon: const Icon(Icons.history),
                  label: s.historyTab,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.add_box_outlined),
                  selectedIcon: const Icon(Icons.add_box),
                  label: s.createTab,
                ),
              ],
            ),
    );
  }
}
