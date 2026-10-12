// Smoke tests for the History and Create screens: pump each at a phone
// form factor and fail on any layout overflow or build exception.
// The history list provider is overridden with canned entries so no real
// database I/O happens inside the widget test zone.
import 'package:boltscan/core/models/parsed_result.dart';
import 'package:boltscan/core/theme/app_theme.dart';
import 'package:boltscan/features/create/create_screen.dart';
import 'package:boltscan/features/history/history_repository.dart';
import 'package:boltscan/features/history/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> setPhoneSize(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('History screen renders header, chips and rows', (tester) async {
    await setPhoneSize(tester);
    final DateTime now = DateTime.now();
    final List<HistoryEntry> entries = <HistoryEntry>[
      HistoryEntry(
        id: 1,
        kind: ResultKind.url,
        rawValue: 'https://example.com/menu',
        scannedAt: now,
      ),
      HistoryEntry(
        id: 2,
        kind: ResultKind.product,
        rawValue: '9691234567899',
        formatLabel: 'EAN-13',
        scannedAt: now,
        favorite: true,
      ),
      HistoryEntry(
        id: 3,
        kind: ResultKind.text,
        rawValue: 'Order #4471 delivered',
        scannedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyListProvider.overrideWith((Ref ref) async => entries),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: HistoryScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('YESTERDAY'), findsOneWidget);
    // Filter chip switches the query without errors.
    await tester.tap(find.text('Links'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Create screen renders and switches types', (tester) async {
    await setPhoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: CreateScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Create'), findsOneWidget);
    // Switch to the Wi-Fi form; the SSID field label appears in caps.
    await tester.tap(find.text('Wi-Fi'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('NETWORK NAME'), findsOneWidget);
  });
}
