import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/state/app_state.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:newtube/ui/shell/app_shell.dart';
import 'package:newtube/ui/widgets/mini_player.dart';

import 'fakes.dart';

Finder miniBar(String text) =>
    find.descendant(of: find.byType(MiniPlayer), matching: find.text(text));

Future<void> pumpShell(
  WidgetTester tester,
  AppState state, {
  Size size = const Size(1200, 800),
}) {
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  return pumpPage(tester, state, AppShell(), size: size);
}

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  testWidgets('leaving the watch page docks playback in the mini player', (
    tester,
  ) async {
    final player = FakePlayerController();
    final state = await testState(
      windowActions: FakeWindowActions(),
      player: player,
    );
    await pumpShell(tester, state);
    await tester.pumpAndSettle();

    await tester.tap(find.text('First video'));
    await tester.pumpAndSettle();
    expect(find.text('A video description'), findsOneWidget);
    expect(miniBar('First video'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(player.disposed, isFalse);
    expect(player.playing, isTrue);
    expect(miniBar('First video'), findsOneWidget);
    expect(miniBar('Channel One'), findsOneWidget);
    expect(state.playback.minimized, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('tapping the mini player expands the watch page in place', (
    tester,
  ) async {
    final player = FakePlayerController();
    final state = await testState(
      windowActions: FakeWindowActions(),
      player: player,
    );
    await pumpShell(tester, state);
    await tester.pumpAndSettle();

    await tester.tap(find.text('First video'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(miniBar('First video'), findsOneWidget);

    await tester.tap(miniBar('First video'));
    await tester.pumpAndSettle();

    expect(find.byType(WatchPage), findsOneWidget);
    expect(find.text('A video description'), findsOneWidget);
    expect(miniBar('First video'), findsNothing);
    expect(player.opened, hasLength(1));
    expect(player.disposed, isFalse);
    expect(state.playback.minimized, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('mini player pause and resume buttons control playback', (
    tester,
  ) async {
    final player = FakePlayerController();
    final state = await testState(
      windowActions: FakeWindowActions(),
      player: player,
    );
    await pumpShell(tester, state);
    await tester.pumpAndSettle();

    await tester.tap(find.text('First video'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(MiniPlayer),
        matching: find.byIcon(Icons.pause),
      ),
    );
    await tester.pumpAndSettle();
    expect(player.paused, isTrue);

    await tester.tap(
      find.descendant(
        of: find.byType(MiniPlayer),
        matching: find.byIcon(Icons.play_arrow),
      ),
    );
    await tester.pumpAndSettle();
    expect(player.played, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('closing the mini player stops playback', (tester) async {
    final player = FakePlayerController();
    final state = await testState(
      windowActions: FakeWindowActions(),
      player: player,
    );
    await pumpShell(tester, state);
    await tester.pumpAndSettle();

    await tester.tap(find.text('First video'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(miniBar('First video'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(MiniPlayer),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pumpAndSettle();

    expect(player.disposed, isTrue);
    expect(state.playback.player, isNull);
    expect(miniBar('First video'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('mini player shows above the bottom navigation on mobile', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final player = FakePlayerController();
    final state = await testState(player: player);
    await pumpPage(tester, state, const AppShell(), size: const Size(400, 800));
    await tester.pumpAndSettle();

    await tester.tap(find.text('First video'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(miniBar('First video'), findsOneWidget);
    final bar = tester.getBottomLeft(find.byType(MiniPlayer));
    final nav = tester.getTopLeft(find.byType(NavigationBar));
    expect(bar.dy, lessThanOrEqualTo(nav.dy));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('opening a different video replaces the mini player', (
    tester,
  ) async {
    final made = <FakePlayerController>[];
    final state = await testState(
      windowActions: FakeWindowActions(),
      createPlayer: () {
        final p = FakePlayerController();
        made.add(p);
        return p;
      },
    );
    await pumpShell(tester, state);
    await tester.pumpAndSettle();

    await tester.tap(find.text('First video'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(miniBar('First video'), findsOneWidget);

    await tester.tap(find.text('Second video'));
    await tester.pumpAndSettle();

    expect(made, hasLength(2));
    expect(made.first.disposed, isTrue);
    expect(made.last.disposed, isFalse);
    expect(find.byType(WatchPage), findsOneWidget);
    expect(miniBar('Second video'), findsNothing);
    expect(state.playback.video?.id, 'v2');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a covered watch page reloads after its player is replaced', (
    tester,
  ) async {
    final made = <FakePlayerController>[];
    final state = await testState(
      windowActions: FakeWindowActions(),
      api: FakeYouTubeApi(feed: testVideos),
      createPlayer: () {
        final p = FakePlayerController();
        made.add(p);
        return p;
      },
    );
    await pumpShell(tester, state);
    await tester.pumpAndSettle();

    state.requestWatch(testVideos.first);
    await tester.pumpAndSettle();
    expect(find.text('A video description'), findsOneWidget);

    state.requestWatch(testVideos.last);
    await tester.pumpAndSettle();
    expect(made, hasLength(2));
    expect(made.first.disposed, isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(made, hasLength(3));
    expect(made[1].disposed, isTrue);
    expect(find.text('A video description'), findsOneWidget);
    expect(state.playback.video?.id, 'v1');
    expect(miniBar('Second video'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('watch page reloads when the session is stopped', (tester) async {
    final made = <FakePlayerController>[];
    final state = await testState(
      createPlayer: () {
        final p = FakePlayerController();
        made.add(p);
        return p;
      },
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(made, hasLength(1));

    await state.playback.stop();
    await tester.pumpAndSettle();

    expect(made, hasLength(2));
    expect(made.first.disposed, isTrue);
    expect(find.text('A video description'), findsOneWidget);
  });
}
