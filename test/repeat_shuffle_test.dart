import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/app_state.dart';
import 'package:newtube/state/playback_session.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:newtube/ui/widgets/player_view.dart';

import 'fakes.dart';

const _playlist = PlaylistInfo(
  id: 'pl1',
  title: 'Test playlist',
  author: 'Channel One',
  videoCount: 2,
  videos: testVideos,
);

void main() {
  test('repeat mode and shuffle notify listeners', () {
    final session = PlaybackSession();
    var notified = 0;
    session.addListener(() => notified++);

    session.repeatMode = RepeatMode.one;
    expect(session.repeatMode, RepeatMode.one);
    expect(notified, 1);
    session.repeatMode = RepeatMode.one;
    expect(notified, 1);

    session.shuffle = true;
    expect(session.shuffle, isTrue);
    expect(notified, 2);
    session.shuffle = true;
    expect(notified, 2);
  });

  testWidgets('repeat all wraps around to the start of a playlist', (
    tester,
  ) async {
    final player = FakePlayerController();
    final state = await testState(api: FakeYouTubeApi(), player: player);
    state.playback.repeatMode = RepeatMode.all;
    await pumpPage(
      tester,
      state,
      WatchPage(video: testVideos[1], playlist: _playlist, index: 1),
    );
    await tester.pumpAndSettle();

    player.emitCompleted();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.text('Test playlist · 1/2'), findsOneWidget);
    expect(player.opened, hasLength(2));
  });

  testWidgets('repeat one replays the current video', (tester) async {
    final player = FakePlayerController()
      ..duration = const Duration(minutes: 3)
      ..position = const Duration(minutes: 3);
    final state = await testState(api: FakeYouTubeApi(), player: player);
    state.playback.repeatMode = RepeatMode.one;
    await pumpPage(
      tester,
      state,
      WatchPage(video: testVideos.first, playlist: _playlist, index: 0),
    );
    await tester.pumpAndSettle();

    player.emitCompleted();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(player.lastSeek, Duration.zero);
    expect(player.paused, isFalse);
    expect(player.opened, hasLength(1));
  });

  testWidgets('shuffle picks a different playlist index', (tester) async {
    final player = FakePlayerController();
    final state = await testState(api: FakeYouTubeApi(), player: player);
    state.playback.shuffle = true;
    await pumpPage(
      tester,
      state,
      WatchPage(video: testVideos[0], playlist: _playlist, index: 0),
    );
    await tester.pumpAndSettle();

    player.emitCompleted();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.text('Test playlist · 2/2'), findsOneWidget);
    expect(player.opened, hasLength(2));
  });

  testWidgets('playlist header toggles repeat mode and shuffle', (
    tester,
  ) async {
    final player = FakePlayerController();
    final state = await testState(api: FakeYouTubeApi(), player: player);
    await pumpPage(
      tester,
      state,
      WatchPage(video: testVideos[0], playlist: _playlist, index: 0),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byIcon(Icons.repeat));
    await tester.tap(find.byIcon(Icons.repeat));
    await tester.pump();
    expect(state.playback.repeatMode, RepeatMode.all);
    expect(find.byIcon(Icons.repeat_on), findsOneWidget);

    await tester.tap(find.byIcon(Icons.repeat_on));
    await tester.pump();
    expect(state.playback.repeatMode, RepeatMode.one);
    expect(find.byIcon(Icons.repeat_one_on), findsOneWidget);

    await tester.tap(find.byIcon(Icons.shuffle));
    await tester.pump();
    expect(state.playback.shuffle, isTrue);
    expect(find.byIcon(Icons.shuffle_on), findsOneWidget);
  });

  testWidgets('player settings menu sets repeat mode and shuffle', (
    tester,
  ) async {
    final player = FakePlayerController();
    final state = await testState();
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: PlayerView(
              player: player,
              streams: testStreams,
              current: testStreams[1],
              onQualitySelected: (_) {},
              onAudioSelected: (_) {},
              onToggleFullscreen: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Repeat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('One'));
    await tester.pumpAndSettle();
    expect(state.playback.repeatMode, RepeatMode.one);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shuffle'));
    await tester.pumpAndSettle();
    expect(state.playback.shuffle, isTrue);
  });
}
