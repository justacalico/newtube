import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/app_update.dart';
import 'package:newtube/services/version_checker.dart';
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

  testWidgets('toggles autoplay and shows about section', (tester) async {
    final state = await testState();
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(state.settings.autoplay, isFalse);

    expect(find.text('About'), findsOneWidget);
    expect(find.text('Version 1.2.3'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Check for updates'), 200);
    expect(find.text('Check for updates'), findsOneWidget);
  });

  testWidgets('shows version and up-to-date result', (tester) async {
    final state = await testState();
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    expect(find.text('Version 1.2.3'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Check for updates'), 200);
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.text('You are up to date'), findsOneWidget);
  });

  testWidgets('shows update available with release link', (tester) async {
    final launched = <Uri>[];
    final checker = FakeVersionChecker(
      result: const AppUpdate(
        currentVersion: '1.2.3',
        latestVersion: '2.0.0',
        updateAvailable: true,
        releaseUrl:
            'https://gitlab.com/HttpAnimations/newtube/-/releases/v2.0.0',
      ),
    );
    final state = await testState(versionChecker: checker, launched: launched);
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Check for updates'), 200);
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.text('New version available: 2.0.0'), findsOneWidget);

    await tester.tap(find.text('View release'));
    expect(launched.single.toString(), endsWith('/releases/v2.0.0'));
  });

  testWidgets('shows failure feedback', (tester) async {
    final state = await testState(
      versionChecker: FakeVersionChecker(fail: true),
    );
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Check for updates'), 200);
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.text('Could not check for updates'), findsOneWidget);
  });

  testWidgets('launches releases, source and licence links', (tester) async {
    final launched = <Uri>[];
    final state = await testState(launched: launched);
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('All releases'), 200);
    await tester.tap(find.text('All releases'));
    await tester.tap(find.text('Source code'));
    await tester.scrollUntilVisible(find.text('Licence'), 200);
    await tester.tap(find.text('Licence'));
    await tester.pump();
    expect(launched.map((u) => u.toString()), [
      VersionChecker.releasesUrl,
      'https://gitlab.com/HttpAnimations/newtube',
      'https://www.gnu.org/licenses/agpl-3.0.html',
    ]);
  });
}
