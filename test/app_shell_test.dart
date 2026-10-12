import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/shell/app_shell.dart';
import 'package:newtube/ui/shell/side_nav.dart';
import 'package:newtube/ui/shell/title_bar.dart';

import 'fakes.dart';

void main() {
  testWidgets('wide layout has rail and switches tabs', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final actions = FakeWindowActions();
    final state = await testState(windowActions: actions);
    await pumpPage(
      tester,
      state,
      const AppShell(),
      size: const Size(1200, 800),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SideNav), findsOneWidget);
    expect(find.text('NewTube'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(state.tabIndex, 3);
    expect(find.text('Nothing watched yet'), findsOneWidget);

    await tester.tap(find.text('Subscriptions'));
    await tester.pumpAndSettle();
    expect(state.tabIndex, 2);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('narrow layout uses bottom navigation', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final state = await testState();
    await pumpPage(tester, state, const AppShell(), size: const Size(400, 800));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(SideNav), findsNothing);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(state.tabIndex, 4);
    expect(find.text('Theme'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('hides history tab when search history is disabled', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final state = await testState(
      settings: SettingsStore(searchHistoryEnabled: false),
      windowActions: FakeWindowActions(),
    );
    await pumpPage(
      tester,
      state,
      const AppShell(),
      size: const Size(1200, 800),
    );
    await tester.pumpAndSettle();

    final nav = find.byType(SideNav);
    expect(
      find.descendant(of: nav, matching: find.text('History')),
      findsNothing,
    );

    await tester.tap(find.descendant(of: nav, matching: find.text('Settings')));
    await tester.pumpAndSettle();
    expect(state.tabIndex, 4);
    expect(find.text('Search history'), findsOneWidget);

    await state.settings.setSearchHistoryEnabled(true, state.prefs);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: nav, matching: find.text('History')),
      findsOneWidget,
    );
    expect(find.text('Search history'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('no title bar on mobile', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final state = await testState();
    await pumpPage(tester, state, const AppShell(), size: const Size(400, 800));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('titlebar.close')), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('window controls live in sidebar on desktop', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final actions = FakeWindowActions();
    final state = await testState(windowActions: actions);
    await pumpPage(
      tester,
      state,
      const AppShell(),
      size: const Size(1200, 800),
    );
    await tester.pumpAndSettle();

    final close = find.byKey(const Key('titlebar.close'));
    expect(
      find.descendant(of: find.byType(SideNav), matching: close),
      findsOneWidget,
    );

    await tester.tap(close);
    expect(actions.closed, 1);

    final dragSpot =
        tester.getTopRight(find.byType(TrafficLights)) + const Offset(40, 6);
    await tester.dragFrom(dragSpot, const Offset(60, 0));
    await tester.pump();
    expect(actions.dragged, greaterThan(0));

    await tester.tapAt(dragSpot);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(dragSpot);
    await tester.pump();
    expect(actions.maximized, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 500));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('wide tablet sidebar has no window controls', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final state = await testState();
    await pumpPage(
      tester,
      state,
      const AppShell(),
      size: const Size(1200, 800),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SideNav), findsOneWidget);
    expect(find.byKey(const Key('titlebar.close')), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('watch page opens inside the shell', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final state = await testState(windowActions: FakeWindowActions());
    await pumpPage(
      tester,
      state,
      const AppShell(),
      size: const Size(1200, 800),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('First video'));
    await tester.pumpAndSettle();

    expect(find.byType(SideNav), findsOneWidget);
    expect(find.text('A video description'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('A video description'), findsNothing);
    expect(find.text('First video'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('switching tabs pops pushed pages', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final player = FakePlayerController();
    final state = await testState(
      windowActions: FakeWindowActions(),
      player: player,
    );
    await pumpPage(
      tester,
      state,
      const AppShell(),
      size: const Size(1200, 800),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('First video'));
    await tester.pumpAndSettle();
    expect(find.text('A video description'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(SideNav),
        matching: find.text('Settings'),
      ),
    );
    await tester.pumpAndSettle();

    expect(state.tabIndex, 4);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('A video description'), findsNothing);
    expect(player.disposed, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('watch page keeps bottom navigation', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final state = await testState();
    await pumpPage(tester, state, const AppShell(), size: const Size(400, 800));
    await tester.pumpAndSettle();

    await tester.tap(find.text('First video'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('A video description'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('search tab shows results', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final api = FakeYouTubeApi(
      searchResults: const SearchResults(videos: testVideos),
    );
    final state = await testState(api: api);
    await pumpPage(
      tester,
      state,
      const AppShell(),
      size: const Size(1200, 800),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: find.byType(SideNav), matching: find.text('Search')),
    );
    await tester.pumpAndSettle();
    expect(state.tabIndex, 1);

    await tester.enterText(find.byType(TextField).first, 'kittens');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Results: kittens'), findsOneWidget);
    expect(find.text('First video'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
