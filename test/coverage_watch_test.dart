import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/innertube_api.dart';
import 'package:newtube/services/sponsor_block.dart';
import 'package:newtube/state/downloads_store.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/pages/download_player_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:newtube/ui/widgets/player_view.dart';
import 'package:newtube/ui/widgets/mini_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  testWidgets('watch page playability errors', (tester) async {
    final api = FakeYouTubeApi()
      ..error = const PlayabilityException('LOGIN_REQUIRED', 'age check');
    final state = await testState(api: api);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(find.text('This video is age-restricted'), findsOneWidget);
  });

  testWidgets('members-only video pops with a snackbar', (tester) async {
    final api = FakeYouTubeApi()
      ..error = const PlayabilityException(
        'LOGIN_REQUIRED',
        'Join this channel to get access to members-only content like this '
            'video, and other exclusive perks.',
      );
    final state = await testState(api: api);
    await pumpPage(
      tester,
      state,
      Builder(
        builder: (context) => FilledButton(
          onPressed: () => openWatchPage(context, testVideos.first),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(WatchPage), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('This video is for channel members only'), findsOneWidget);
  });

  testWidgets('members-only error stays inline on root route', (tester) async {
    final api = FakeYouTubeApi()
      ..error = const PlayabilityException(
        'UNPLAYABLE',
        'This video is available to this channel\'s members',
      );
    final state = await testState(api: api);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(find.byType(WatchPage), findsOneWidget);
    expect(find.text('This video is for channel members only'), findsOneWidget);
  });

  testWidgets('player keyboard shortcuts', (tester) async {
    final player = FakePlayerController()
      ..duration = const Duration(minutes: 10);
    var nexts = 0, prevs = 0, pips = 0;
    final state = await testState();
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: SizedBox(
          width: 800,
          height: 450,
          child: PlayerView(
            player: player,
            streams: const [],
            current: const PlayableStream(url: 'u', quality: 'q'),
            onNext: () => nexts++,
            onPrevious: () => prevs++,
            onPip: () => pips++,
            onQualitySelected: (_) {},
            onAudioSelected: (_) {},
            onToggleFullscreen: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    await tester.pumpAndSettle();
    expect(nexts, 1);
    expect(prevs, 1);
    expect(pips, 1);
    expect(player.seeks.last, const Duration(minutes: 5));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(find.textContaining('shortcuts', findRichText: true), findsWidgets);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('jump to highlight button seeks', (tester) async {
    final player = FakePlayerController();
    final skipper = SegmentSkipper(
      player: player,
      segments: const [
        SponsorSegment(
          category: 'poi_highlight',
          start: Duration(seconds: 30),
          end: Duration(seconds: 30),
        ),
      ],
    );
    final state = await testState();
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: SizedBox(
          width: 800,
          height: 450,
          child: PlayerView(
            player: player,
            streams: const [],
            current: const PlayableStream(url: 'u', quality: 'q'),
            segmentSkipper: skipper,
            onQualitySelected: (_) {},
            onAudioSelected: (_) {},
            onToggleFullscreen: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jump to highlight'));
    await tester.pump();
    expect(player.seeks.last, const Duration(seconds: 30));
  });

  testWidgets('data saver caps stream pick', (tester) async {
    final state = await testState(settings: SettingsStore(dataSaver: true));
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerView), findsWidgets);
  });

  testWidgets('download player page renders', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      DownloadPlayerPage(
        entry: DownloadEntry(video: testVideos.first, path: '/tmp/x.mp4'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PlayerView), findsOneWidget);
  });

  testWidgets('watch page shows unavailable for ERROR', (tester) async {
    final api = FakeYouTubeApi()
      ..error = const PlayabilityException('ERROR', 'gone');
    final state = await testState(api: api);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(find.text('This video is unavailable'), findsOneWidget);
  });

  testWidgets('watch page download audio and failure', (tester) async {
    final state = await testState(downloads: FailDownloads());
    await pumpPage(
      tester,
      state,
      WatchPage(video: testVideos.first),
      size: const Size(800, 1200),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Download'));
    await tester.tap(find.byTooltip('Download'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download audio only'));
    await tester.pumpAndSettle();
    expect(find.text('Download failed'), findsOneWidget);
  });

  testWidgets('mini player swipe dismiss and previous', (tester) async {
    final state = await testState();
    final session = state.playback;
    session.attach(
      FakePlayerController(),
      testVideos.first,
      stream: testStreams.first,
    );
    await pumpPage(
      tester,
      state,
      MiniPlayer(session: session, onExpand: () {}),
    );
    session.release(session.player!);
    await tester.pump();
    await tester.fling(
      find.byKey(const Key('mini_player')),
      const Offset(500, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(session.video, isNull);

    session.attach(
      FakePlayerController(),
      testVideos.first,
      stream: testStreams.first,
    );
    session.release(session.player!);
    session.enqueue(testVideos.last);
    session.takeNext();
    await tester.pump();
    expect(session.hasPrevious, isTrue);
    await tester.tap(find.byIcon(Icons.skip_previous));
    await tester.pump();
    expect(state.watchRequest?.id, 'v1');
  });

  testWidgets('mini player audio-only artwork', (tester) async {
    final state = await testState();
    final session = state.playback;
    session.audioOnly = true;
    session.attach(
      FakePlayerController(),
      testVideos.first,
      stream: testStreams.first,
    );
    await pumpPage(
      tester,
      state,
      MiniPlayer(session: session, onExpand: () {}),
    );
    session.release(session.player!);
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('player shift shortcuts and drag-down scale', (tester) async {
    final player = FakePlayerController()
      ..duration = const Duration(minutes: 10);
    var nexts = 0, prevs = 0;
    final state = await testState();
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: SizedBox(
          width: 800,
          height: 450,
          child: PlayerView(
            player: player,
            streams: const [],
            current: const PlayableStream(url: 'u', quality: 'q'),
            onNext: () => nexts++,
            onPrevious: () => prevs++,
            onQualitySelected: (_) {},
            onAudioSelected: (_) {},
            onToggleFullscreen: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(nexts, 1);
    expect(prevs, 1);

    final center = tester.getCenter(find.byType(PlayerView));
    await tester.dragFrom(center, const Offset(0, 200));
    await tester.pump();
  });

  testWidgets('watch page key shortcuts route to session', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      WatchPage(video: testVideos.first),
      size: const Size(800, 1200),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
    await tester.pumpAndSettle();
  });
  testWidgets('data saver clamps preferred quality', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = await SettingsStore.load(prefs);
    await settings.setDataSaver(true, prefs);
    await settings.setPreferredQuality(1080, prefs);
    final state = await testState(settings: settings);
    await pumpPage(
      tester,
      state,
      WatchPage(video: testVideos.first),
      size: const Size(800, 1200),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PlayerView), findsOneWidget);
  });

  testWidgets('playability error shows reason', (tester) async {
    final api = FakeYouTubeApi()
      ..error = const PlayabilityException('INTERNAL_ERROR', 'server exploded');
    final state = await testState(api: api);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(find.text('server exploded'), findsOneWidget);
  });

  testWidgets('watch page up-next reorder', (tester) async {
    final state = await testState();
    state.playback
      ..enqueue(testVideos.first)
      ..enqueue(testVideos.last);
    await pumpPage(
      tester,
      state,
      WatchPage(video: testVideos.first),
      size: const Size(800, 1600),
    );
    await tester.pumpAndSettle();
    final tile = find.text(testVideos.last.title).last;
    await tester.longPress(tile);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.drag(tile, const Offset(0, -80));
    await tester.pumpAndSettle();
  });

  testWidgets('download player quality callback', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      DownloadPlayerPage(
        entry: DownloadEntry(video: testVideos.first, path: '/tmp/x.mp4'),
      ),
    );
    await tester.pumpAndSettle();
    final view = tester.widget<PlayerView>(find.byType(PlayerView));
    view.onQualitySelected(const PlayableStream(url: 'u', quality: 'q'));
    view.onAudioSelected(const PlayableStream(url: 'a', quality: 'a'));
    view.onToggleFullscreen();
  });

  testWidgets('watch page up-next drag reorders', (tester) async {
    final state = await testState();
    state.playback
      ..enqueue(testVideos.first)
      ..enqueue(testVideos.last);
    await pumpPage(
      tester,
      state,
      WatchPage(video: testVideos.first),
      size: const Size(800, 1600),
    );
    await tester.pumpAndSettle();
    final tile = tester.getCenter(find.text(testVideos.last.title).last);
    final hold = await tester.startGesture(tile);
    await tester.pump(const Duration(milliseconds: 600));
    await hold.moveBy(const Offset(0, -80));
    await tester.pump(const Duration(milliseconds: 300));
    await hold.up();
    await tester.pumpAndSettle();
  });

  testWidgets('player drag down scales video', (tester) async {
    final player = FakePlayerController();
    final state = await testState();
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: SizedBox(
          width: 800,
          height: 450,
          child: PlayerView(
            player: player,
            streams: const [],
            current: const PlayableStream(url: 'u', quality: 'q'),
            onQualitySelected: (_) {},
            onAudioSelected: (_) {},
            onToggleFullscreen: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final center = tester.getCenter(find.byType(PlayerView));
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(0, 30));
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  });
  testWidgets('watch page queue reorder callback', (tester) async {
    final state = await testState();
    state.playback
      ..enqueue(testVideos.first)
      ..enqueue(testVideos.last);
    await pumpPage(
      tester,
      state,
      WatchPage(video: testVideos.first),
      size: const Size(800, 1600),
    );
    await tester.pumpAndSettle();
    final view = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    view.onReorderItem?.call(0, 1);
    await tester.pumpAndSettle();
  });
}
