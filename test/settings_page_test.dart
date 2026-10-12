import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/pages/settings_page.dart';

import 'fakes.dart';

void main() {
  testWidgets('changes theme', (tester) async {
    final state = await testState();
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    Future<void> pick(String label) async {
      final tile = find.ancestor(
        of: find.text('Theme'),
        matching: find.byType(ListTile),
      );
      await tester.tap(
        find.descendant(
          of: tile,
          matching: find.byType(DropdownButton<AppTheme>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    await pick('OLED');
    expect(state.settings.theme, AppTheme.oled);
    await pick('Dark');
    expect(state.settings.theme, AppTheme.dark);
    await pick('Light');
    expect(state.settings.theme, AppTheme.light);
    await pick('System');
    expect(state.settings.theme, AppTheme.system);
  });

  testWidgets('selects each language', (tester) async {
    final state = await testState();
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    Future<void> pick(String label) async {
      final tile = find.ancestor(
        of: find.text('Language'),
        matching: find.byType(ListTile),
      );
      await tester.tap(
        find.descendant(
          of: tile,
          matching: find.byType(DropdownButton<String>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    await pick('简体中文');
    expect(state.settings.locale, const Locale('zh', 'Hans'));
    await pick('Русский');
    expect(state.settings.locale, const Locale('ru'));
    await pick('Gaeilge');
    expect(state.settings.locale, const Locale('ga'));
    await pick('Traditional English');
    expect(state.settings.locale, const Locale('en', 'GB'));
    await pick('System');
    expect(state.settings.locale, isNull);
  });

  testWidgets('toggles autoplay and opens about', (tester) async {
    final state = await testState();
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(state.settings.autoplay, isFalse);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('Check for updates'), findsOneWidget);
  });
}
