import 'dart:convert';

import 'package:flutter/foundation.dart';
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

    await tester.tap(find.widgetWithText(SwitchListTile, 'Autoplay videos'));
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
    await tester.ensureVisible(find.text('Check for updates'));
    await tester.pumpAndSettle();
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
    await tester.ensureVisible(find.text('Check for updates'));
    await tester.pumpAndSettle();
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
    await tester.ensureVisible(find.text('Check for updates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.text('Could not check for updates'), findsOneWidget);
  });

  testWidgets('toggles search history', (tester) async {
    final state = await testState();
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Search history'));
    await tester.pump();
    expect(state.settings.searchHistoryEnabled, isFalse);
    expect(state.prefs.getBool('search_history_enabled'), isFalse);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Search history'));
    await tester.pump();
    expect(state.settings.searchHistoryEnabled, isTrue);
    expect(state.prefs.getBool('search_history_enabled'), isTrue);
  });

  testWidgets('clears watch and search history', (tester) async {
    final state = await testState(
      initialPrefs: {
        'history': '[{"id":"v1","title":"First video","author":"Channel One","channelId":"c1","duration":201}]',
        'search_history': '["cats","dogs"]',
      },
    );
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(state.history.entries, isEmpty);
    expect(state.searchHistory.entries, isEmpty);
    expect(state.prefs.getString('history'), '[]');
    expect(state.prefs.getString('search_history'), '[]');
  });

  testWidgets('keeps history when clear is cancelled', (tester) async {
    final state = await testState(
      initialPrefs: {
        'history': '[{"id":"v1","title":"First video","author":"Channel One","channelId":"c1","duration":201}]',
        'search_history': '["cats","dogs"]',
      },
    );
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(state.history.entries, isNotEmpty);
    expect(state.searchHistory.entries, isNotEmpty);
  });

  testWidgets('launches releases, source and licence links', (tester) async {
    final launched = <Uri>[];
    final state = await testState(launched: launched);
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('All releases'), 200);
    await tester.tap(find.text('All releases'));
    await tester.scrollUntilVisible(find.text('Source code'), 200);
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

  testWidgets('toggles the MCP server', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final fake = FakeMcpServer();
    final state = await testState(
      createMcpServer: ({required api, required version, onPlayVideo}) => fake,
    );
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    final tile = find.widgetWithText(SwitchListTile, 'MCP server');
    expect(tile, findsOneWidget);
    expect(
      find.text('Allow AI tools to search and play videos'),
      findsOneWidget,
    );
    expect(find.text('Export server file'), findsNothing);

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(state.settings.mcpEnabled, isTrue);
    expect(fake.running, isTrue);
    expect(find.text('http://127.0.0.1:8642/mcp'), findsOneWidget);
    expect(find.text('Export server file'), findsOneWidget);

    await tester.tap(find.text('Export server file'));
    await tester.pumpAndSettle();

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(state.settings.mcpEnabled, isFalse);
    expect(fake.running, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('shows an error when the MCP server fails to start', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final state = await testState(
      settings: SettingsStore(mcpEnabled: true),
      createMcpServer: ({required api, required version, onPlayVideo}) =>
          FakeMcpServer()..startError = 'port busy',
    );
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    expect(find.text('Could not start the MCP server'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('exports the server file', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final saved = <String>[];
    final state = await testState(
      settings: SettingsStore(mcpEnabled: true),
      createMcpServer: ({required api, required version, onPlayVideo}) =>
          FakeMcpServer()..running = true,
      saveTextFile: (name, contents) async {
        saved.addAll([name, contents]);
        return '/home/u/Downloads/$name';
      },
    );
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export server file'));
    await tester.pumpAndSettle();

    expect(saved.first, 'newtube.mcpb');
    final doc = jsonDecode(saved[1]) as Map<String, Object?>;
    expect(doc, {
      'mcpServers': {
        'newtube': {'type': 'http', 'url': 'http://127.0.0.1:8642/mcp'},
      },
    });
    expect(
      find.text('Saved to /home/u/Downloads/newtube.mcpb'),
      findsOneWidget,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('reports a failed export', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final state = await testState(
      settings: SettingsStore(mcpEnabled: true),
      saveTextFile: (name, contents) async => null,
    );
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export server file'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save the export'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
