import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/ui/shell/app_shell.dart';

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

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('NewTube'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(state.tabIndex, 2);
    expect(find.text('Nothing watched yet'), findsOneWidget);

    await tester.tap(find.text('Subscriptions'));
    await tester.pumpAndSettle();
    expect(state.tabIndex, 1);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('narrow layout uses bottom navigation', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final state = await testState();
    await pumpPage(tester, state, const AppShell(), size: const Size(400, 800));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(state.tabIndex, 3);
    expect(find.text('Theme'), findsOneWidget);
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

  testWidgets('title bar present on desktop', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final state = await testState(windowActions: FakeWindowActions());
    await pumpPage(
      tester,
      state,
      const AppShell(),
      size: const Size(1200, 800),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('titlebar.close')), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('search pushes results page', (tester) async {
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

    await tester.enterText(find.byType(TextField).first, 'kittens');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Results: kittens'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
