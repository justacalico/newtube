import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/pages/watch_page.dart';

import 'fakes.dart';

Future<void> _openSettings(WidgetTester tester, String entry) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(entry));
  await tester.pumpAndSettle();
}

class _RelatedFailApi extends FakeYouTubeApi {
  @override
  Future<List<VideoInfo>> relatedVideos(String videoId) async =>
      throw StateError('nope');
}

class _ChannelFailApi extends FakeYouTubeApi {
  @override
  Future<ChannelInfo> channel(String channelId) async =>
      throw StateError('nope');
}

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  testWidgets('plays video, shows details and related', (tester) async {
    final player = FakePlayerController();
    final api = FakeYouTubeApi(
      related: [testVideos[1]],
      details: const VideoDetails(
        info: VideoInfo(
          id: 'v1',
          title: 'First video',
          author: 'Channel One',
          channelId: 'c1',
          viewCount: 12345,
        ),
        description: 'A video description',
        streams: testStreams,
      ),
    );
    final state = await testState(api: api, player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    expect(player.opened, isNotEmpty);
    expect(state.history.entries.first.id, 'v1');

    expect(find.text('First video'), findsWidgets);
    expect(find.text('A video description'), findsOneWidget);
    expect(find.text('12.3K views'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is NetworkImage &&
            (w.image as NetworkImage).url == testChannel.thumbnailUrl,
      ),
      findsOneWidget,
    );
    expect(find.text('Related videos'), findsOneWidget);
    expect(find.text('Second video'), findsOneWidget);

    await tester.ensureVisible(find.text('Second video'));
    await tester.tap(find.text('Second video'));
    await tester.pumpAndSettle();
  });

  testWidgets('respects autoplay off', (tester) async {
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(),
      player: player,
      settings: SettingsStore(autoplay: false),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.paused, isTrue);
  });

  testWidgets('autoplay off shows an end screen on completion', (tester) async {
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(related: [testVideos[1]]),
      player: player,
      settings: SettingsStore(autoplay: false),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    player.emitCompleted();
    await tester.pumpAndSettle();

    expect(find.text('Replay'), findsOneWidget);
    expect(find.text('Next video'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is NetworkImage &&
            (w.image as NetworkImage).url == testVideos.first.thumbnailUrl,
      ),
      findsOneWidget,
    );
    expect(player.opened, hasLength(1));
  });

  testWidgets('end screen replay restarts the video', (tester) async {
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(),
      player: player,
      settings: SettingsStore(autoplay: false),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    player.position = const Duration(minutes: 3);
    player.emitCompleted();
    await tester.pumpAndSettle();
    expect(find.text('Replay'), findsOneWidget);

    await tester.tap(find.text('Replay'));
    await tester.pump();
    expect(player.lastSeek, Duration.zero);
    expect(player.playing, isTrue);

    player.emitPlaying(true);
    await tester.pump();
    expect(find.text('Replay'), findsNothing);
  });

  testWidgets('end screen next opens the related video', (tester) async {
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(related: [testVideos[1]]),
      player: player,
      settings: SettingsStore(autoplay: false),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    player.emitCompleted();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next video'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Second video'),
      ),
      findsOneWidget,
    );
    expect(player.opened, hasLength(2));
    expect(find.text('Replay'), findsNothing);
  });

  testWidgets('end screen next is disabled without a next video', (
    tester,
  ) async {
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(),
      player: player,
      settings: SettingsStore(autoplay: false),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    player.emitCompleted();
    await tester.pumpAndSettle();

    expect(find.text('Replay'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.skip_next))
          .onPressed,
      isNull,
    );
  });

  testWidgets('autoplay on advances to the related video', (tester) async {
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(related: [testVideos[1]]),
      player: player,
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    player.emitCompleted();
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Second video'),
      ),
      findsOneWidget,
    );
    expect(player.opened, hasLength(2));
  });

  testWidgets('autoplay stays put without a next video', (tester) async {
    final player = FakePlayerController();
    final state = await testState(api: FakeYouTubeApi(), player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    player.emitCompleted();
    await tester.pumpAndSettle();

    expect(player.opened, hasLength(1));
    expect(find.text('Replay'), findsOneWidget);
  });

  testWidgets('autoplay advances to the next playlist video', (tester) async {
    const playlist = PlaylistInfo(
      id: 'pl1',
      title: 'Test playlist',
      author: 'Channel One',
      videoCount: 2,
      videos: testVideos,
    );
    final player = FakePlayerController();
    final state = await testState(api: FakeYouTubeApi(), player: player);
    await pumpPage(
      tester,
      state,
      WatchPage(video: testVideos[0], playlist: playlist, index: 0),
    );
    await tester.pumpAndSettle();

    player.emitCompleted();
    await tester.pumpAndSettle();

    expect(find.text('Test playlist · 2/2'), findsOneWidget);
    expect(player.opened, hasLength(2));
  });

  testWidgets('end screen next from fullscreen returns to the page', (
    tester,
  ) async {
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(related: [testVideos[1]]),
      player: player,
      settings: SettingsStore(autoplay: false),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Fullscreen'));
    await tester.pumpAndSettle();

    player.emitCompleted();
    await tester.pumpAndSettle();
    expect(find.text('Replay'), findsOneWidget);

    await tester.tap(find.text('Next video'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Second video'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('error state shows retry', (tester) async {
    final api = FakeYouTubeApi()..error = 'offline';
    final state = await testState(api: api);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);

    api.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('A video description'), findsOneWidget);
  });

  testWidgets('quality menu reopens a different stream', (tester) async {
    final player = FakePlayerController();
    final state = await testState(api: FakeYouTubeApi(), player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.opened.single, isNotEmpty);

    await _openSettings(tester, 'Quality');
    await tester.tap(find.text('360p').last);
    await tester.pumpAndSettle();
    expect(player.opened.last, contains('360'));
  });

  testWidgets('quality switch pairs audio from the same container', (
    tester,
  ) async {
    const streams = [
      PlayableStream(
        url: 'https://video.example.com/360',
        quality: '360p',
        container: 'mp4',
      ),
      PlayableStream(
        url: 'https://video.example.com/1080',
        quality: '1080p',
        hasAudio: false,
        container: 'mp4',
      ),
      PlayableStream(
        url: 'https://audio.example.com/webm',
        quality: 'audio 136kbps',
        hasVideo: false,
        container: 'webm',
      ),
      PlayableStream(
        url: 'https://audio.example.com/mp4',
        quality: 'audio 130kbps',
        hasVideo: false,
        container: 'mp4',
      ),
    ];
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(
        details: const VideoDetails(
          info: VideoInfo(
            id: 'v1',
            title: 'First video',
            author: 'A',
            channelId: 'c',
          ),
          description: '',
          streams: streams,
        ),
      ),
      player: player,
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.opened.single, 'https://video.example.com/360');

    await _openSettings(tester, 'Quality');
    await tester.tap(find.text('1080p'));
    await tester.pumpAndSettle();
    expect(
      player.opened.last,
      'https://video.example.com/1080+https://audio.example.com/mp4',
    );
  });

  testWidgets('stream switch keeps playback position', (tester) async {
    final player = FakePlayerController();
    final state = await testState(api: FakeYouTubeApi(), player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    player.position = const Duration(seconds: 30);
    await _openSettings(tester, 'Quality');
    await tester.tap(find.text('360p').last);
    await tester.pumpAndSettle();

    expect(player.opened.last, contains('360'));
    expect(player.lastSeek, const Duration(seconds: 30));
    expect(player.playing, isTrue);
  });

  testWidgets('stream switch keeps paused state', (tester) async {
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(),
      player: player,
      settings: SettingsStore(autoplay: false),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.playing, isFalse);

    player.position = const Duration(seconds: 10);
    await _openSettings(tester, 'Quality');
    await tester.tap(find.text('360p').last);
    await tester.pumpAndSettle();

    expect(player.opened.last, contains('360'));
    expect(player.lastSeek, const Duration(seconds: 10));
    expect(player.playing, isFalse);
  });

  testWidgets('superseded stream switch does not restore position', (
    tester,
  ) async {
    final player = FakePlayerController();
    final state = await testState(api: FakeYouTubeApi(), player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    player.position = const Duration(seconds: 30);
    player.openGate = Completer<void>();

    await _openSettings(tester, 'Quality');
    await tester.tap(find.text('360p').last);
    await tester.pump();

    await _openSettings(tester, 'Quality');
    await tester.tap(find.text('720p'));
    await tester.pump();

    player.openGate!.complete();
    await tester.pumpAndSettle();

    expect(player.opened, hasLength(3));
    expect(player.seeks, [Duration.zero]);
  });

  testWidgets('stream switch keeps the playback rate', (tester) async {
    final player = FakePlayerController();
    final state = await testState(api: FakeYouTubeApi(), player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    await _openSettings(tester, 'Playback speed');
    await tester.tap(find.text('1.5x'));
    await tester.pumpAndSettle();
    expect(player.rate, 1.5);

    await _openSettings(tester, 'Quality');
    await tester.tap(find.text('360p').last);
    await tester.pumpAndSettle();

    expect(player.opened.last, contains('360'));
    expect(player.rate, 1.5);
  });

  testWidgets('description timestamps show chapter title on the seek bar', (
    tester,
  ) async {
    final player = FakePlayerController()
      ..duration = const Duration(minutes: 2);
    final api = FakeYouTubeApi(
      details: const VideoDetails(
        info: VideoInfo(
          id: 'v1',
          title: 'First video',
          author: 'Channel One',
          channelId: 'c1',
        ),
        description: '0:00 Intro\n1:00 The good part',
        streams: testStreams,
      ),
    );
    final state = await testState(api: api, player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    expect(find.text('Intro'), findsOneWidget);

    player.position = const Duration(seconds: 75);
    player.emitPosition(const Duration(seconds: 75));
    await tester.pump();
    await tester.pump();
    expect(find.text('The good part'), findsOneWidget);
  });

  testWidgets('failed stream switch keeps playing the old stream', (
    tester,
  ) async {
    final player = FakePlayerController();
    final state = await testState(api: FakeYouTubeApi(), player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    player.openError = StateError('nope');
    await _openSettings(tester, 'Quality');
    await tester.tap(find.text('360p').last);
    await tester.pumpAndSettle();

    expect(player.opened, hasLength(1));
    expect(player.playing, isTrue);
  });

  testWidgets('audio menu switches the audio track', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    const streams = [
      PlayableStream(
        url: 'https://video.example.com/720',
        quality: '720p',
        hasAudio: false,
      ),
      PlayableStream(url: 'https://video.example.com/360', quality: '360p'),
      PlayableStream(
        url: 'https://audio.example.com/en',
        quality: 'audio 128kbps',
        hasVideo: false,
        audioLanguage: 'en',
        audioTrackName: 'English original',
      ),
      PlayableStream(
        url: 'https://audio.example.com/es',
        quality: 'audio 128kbps',
        hasVideo: false,
        audioLanguage: 'es',
        audioTrackName: 'Español',
        isDefaultAudio: false,
      ),
    ];
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(
        details: const VideoDetails(
          info: VideoInfo(
            id: 'v1',
            title: 'First video',
            author: 'A',
            channelId: 'c',
          ),
          description: '',
          streams: streams,
        ),
      ),
      player: player,
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.opened.single, endsWith('+https://audio.example.com/en'));

    await _openSettings(tester, 'Audio');
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(player.opened.last, endsWith('+https://audio.example.com/es'));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('audio select on muxed stream pairs a video-only stream', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const streams = [
      PlayableStream(url: 'https://video.example.com/360', quality: '360p'),
      PlayableStream(
        url: 'https://video.example.com/360v',
        quality: '360p',
        hasAudio: false,
      ),
      PlayableStream(
        url: 'https://audio.example.com/es',
        quality: 'audio 128kbps',
        hasVideo: false,
        audioLanguage: 'es',
        audioTrackName: 'Español',
        isDefaultAudio: false,
      ),
    ];
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(
        details: const VideoDetails(
          info: VideoInfo(
            id: 'v1',
            title: 'First video',
            author: 'A',
            channelId: 'c',
          ),
          description: '',
          streams: streams,
        ),
      ),
      player: player,
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.opened.single, 'https://video.example.com/360');

    await _openSettings(tester, 'Audio');
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(
      player.opened.last,
      'https://video.example.com/360v+https://audio.example.com/es',
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('audio select does nothing without a video-only stream', (
    tester,
  ) async {
    const streams = [
      PlayableStream(url: 'https://video.example.com/360', quality: '360p'),
      PlayableStream(
        url: 'https://audio.example.com/en',
        quality: 'audio 128kbps',
        hasVideo: false,
        audioTrackName: 'English original',
      ),
    ];
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(
        details: const VideoDetails(
          info: VideoInfo(
            id: 'v1',
            title: 'First video',
            author: 'A',
            channelId: 'c',
          ),
          description: '',
          streams: streams,
        ),
      ),
      player: player,
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.opened.single, 'https://video.example.com/360');

    await _openSettings(tester, 'Audio');
    await tester.tap(find.text('English original'));
    await tester.pumpAndSettle();
    expect(player.opened, hasLength(1));
  });

  testWidgets('audio-only playback switches tracks', (tester) async {
    const streams = [
      PlayableStream(
        url: 'https://audio.example.com/en',
        quality: 'audio 128kbps',
        hasVideo: false,
        audioTrackName: 'English original',
      ),
      PlayableStream(
        url: 'https://audio.example.com/es',
        quality: 'audio 128kbps',
        hasVideo: false,
        audioTrackName: 'Español',
        isDefaultAudio: false,
      ),
    ];
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(
        details: const VideoDetails(
          info: VideoInfo(
            id: 'v1',
            title: 'First video',
            author: 'A',
            channelId: 'c',
          ),
          description: '',
          streams: streams,
        ),
      ),
      player: player,
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.opened.single, 'https://audio.example.com/en');

    player.position = const Duration(seconds: 7);
    await _openSettings(tester, 'Audio');
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(player.opened.last, 'https://audio.example.com/es');
    expect(player.lastSeek, const Duration(seconds: 7));
  });

  testWidgets('fullscreen hides everything else and back exits', (
    tester,
  ) async {
    final state = await testState(api: FakeYouTubeApi());
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Fullscreen'));
    await tester.pumpAndSettle();
    expect(find.text('A video description'), findsNothing);
    expect(find.byIcon(Icons.fullscreen), findsNothing);

    await tester.tap(find.byIcon(Icons.fullscreen_exit));
    await tester.pumpAndSettle();
    expect(find.text('A video description'), findsOneWidget);
  });

  testWidgets('quality change works in fullscreen', (tester) async {
    final player = FakePlayerController();
    final state = await testState(api: FakeYouTubeApi(), player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Fullscreen'));
    await tester.pumpAndSettle();
    await _openSettings(tester, 'Quality');
    await tester.tap(find.text('360p').last);
    await tester.pumpAndSettle();

    expect(player.opened.last, contains('360'));

    await tester.tap(find.byIcon(Icons.fullscreen_exit));
    await tester.pumpAndSettle();
    expect(find.text('A video description'), findsOneWidget);
  });

  testWidgets('audio change works in fullscreen', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final player = FakePlayerController();
    final state = await testState(api: FakeYouTubeApi(), player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Fullscreen'));
    await tester.pumpAndSettle();
    await _openSettings(tester, 'Audio');
    await tester.tap(find.text('audio 128kbps'));
    await tester.pumpAndSettle();

    expect(player.opened.last, endsWith('+https://audio.example.com/128'));

    await tester.tap(find.byIcon(Icons.fullscreen_exit));
    await tester.pumpAndSettle();
    expect(find.text('A video description'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('channel name opens channel page', (tester) async {
    final api = FakeYouTubeApi(uploads: testVideos);
    final state = await testState(api: api);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Channel One'));
    await tester.pumpAndSettle();
    expect(find.text('54.3K subscribers'), findsOneWidget);
  });

  testWidgets('subscribes from watch page', (tester) async {
    final state = await testState(api: FakeYouTubeApi());
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subscribe'));
    await tester.pump();
    expect(state.subscriptions.isSubscribed('c1'), isTrue);
  });

  testWidgets('channel lookup failure still plays', (tester) async {
    final player = FakePlayerController();
    final state = await testState(api: _ChannelFailApi(), player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.opened, isNotEmpty);
    expect(find.text('A video description'), findsOneWidget);

    await tester.tap(find.text('Subscribe'));
    await tester.pump();
    expect(state.subscriptions.isSubscribed('c1'), isTrue);
  });

  testWidgets('background audio session attaches and detaches', (tester) async {
    final controls = FakeMediaControls();
    final state = await testState(
      api: FakeYouTubeApi(),
      player: FakePlayerController(),
      mediaControls: controls,
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    expect(controls.attaches, 1);
    expect(controls.lastTitle, 'First video');
    expect(controls.lastArtist, 'Channel One');
    expect(controls.lastArtwork, 'https://img.example.com/v1.jpg');

    await pumpPage(tester, state, const SizedBox());
    await tester.pumpAndSettle();
    expect(controls.detaches, 0);

    await state.playback.stop();
    expect(controls.detaches, 1);
  });

  testWidgets('stream open failure disposes the player', (tester) async {
    final player = FakePlayerController()..openError = 'dead';
    final state = await testState(api: FakeYouTubeApi(), player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.disposed, isTrue);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('media controls failure does not break playback', (tester) async {
    final controls = FakeMediaControls()..attachThrows = true;
    final state = await testState(
      api: FakeYouTubeApi(),
      player: FakePlayerController(),
      mediaControls: controls,
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(find.text('A video description'), findsOneWidget);
  });

  testWidgets('picture-in-picture button enters and exits pip', (tester) async {
    final pip = FakePipActions();
    final state = await testState(
      api: FakeYouTubeApi(),
      player: FakePlayerController(),
      pipActions: pip,
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    final icon = find.byIcon(Icons.picture_in_picture_alt_outlined);
    expect(icon, findsOneWidget);
    await tester.tap(icon);
    expect(pip.enters, 1);

    await pumpPage(tester, state, const SizedBox());
    await tester.pumpAndSettle();
    expect(pip.exits, 1);
  });

  testWidgets('pip mode shows only the video', (tester) async {
    final pip = FakePipActions();
    final state = await testState(
      api: FakeYouTubeApi(),
      player: FakePlayerController(),
      pipActions: pip,
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(find.text('A video description'), findsOneWidget);

    pip.pipMode.value = true;
    await tester.pumpAndSettle();
    expect(find.text('A video description'), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byTooltip('Picture in picture'), findsNothing);

    pip.pipMode.value = false;
    await tester.pumpAndSettle();
    expect(find.text('A video description'), findsOneWidget);
  });

  testWidgets('pip mode while fullscreen shows only the video', (tester) async {
    final pip = FakePipActions();
    final state = await testState(
      api: FakeYouTubeApi(),
      player: FakePlayerController(),
      pipActions: pip,
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Fullscreen'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);

    pip.pipMode.value = true;
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.fullscreen_exit), findsNothing);
    expect(find.byType(AppBar), findsNothing);

    pip.pipMode.value = false;
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
  });

  testWidgets('pip actions track the current stream', (tester) async {
    final pip = FakePipActions();
    final state = await testState(
      api: FakeYouTubeApi(),
      player: FakePlayerController(),
      pipActions: pip,
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(pip.lastUrl, 'https://video.example.com/360');
    expect(pip.lastAudioUrl, isNull);

    await _openSettings(tester, 'Quality');
    await tester.tap(find.text('720p').last);
    await tester.pumpAndSettle();
    expect(pip.lastUrl, 'https://video.example.com/720');
    expect(pip.lastAudioUrl, 'https://audio.example.com/128');
  });

  testWidgets('leaving the app during playback enters pip', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final pip = FakePipActions();
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(),
      player: player,
      pipActions: pip,
    );
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.playing, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(pip.enters, 1);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('leaving the app while paused does not enter pip', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final pip = FakePipActions();
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(),
      player: player,
      pipActions: pip,
    );
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    await player.pause();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(pip.enters, 0);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('leaving the app on desktop does not enter pip', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final pip = FakePipActions();
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(),
      player: player,
      pipActions: pip,
    );
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(pip.enters, 0);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('pip mode before the player loads stays black', (tester) async {
    final pip = FakePipActions();
    final api = FakeYouTubeApi()..detailsGate = Completer<VideoDetails>();
    final state = await testState(api: api, pipActions: pip);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pump();

    pip.pipMode.value = true;
    await tester.pump();
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('related videos failure still plays', (tester) async {
    final player = FakePlayerController();
    final state = await testState(api: _RelatedFailApi(), player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.opened, isNotEmpty);
    expect(find.text('A video description'), findsOneWidget);
  });

  testWidgets('backgrounding keeps audio playing without the video track', (
    tester,
  ) async {
    final player = FakePlayerController();
    final state = await testState(api: FakeYouTubeApi(), player: player);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.playing, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(player.videoEnabled, isFalse);
    expect(player.paused, isFalse);
    expect(player.playing, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(player.videoEnabled, isTrue);
    expect(player.playing, isTrue);
  });

  testWidgets('lifecycle change before load is ignored', (tester) async {
    final api = FakeYouTubeApi()..detailsGate = Completer<VideoDetails>();
    final state = await testState(api: api);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    api.detailsGate!.complete(
      VideoDetails(info: testVideos.first, description: '', streams: const []),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('First video'), findsWidgets);
  });

  testWidgets('opening a video while backgrounded stays audio-only', (
    tester,
  ) async {
    final player = FakePlayerController();
    final api = FakeYouTubeApi()..detailsGate = Completer<VideoDetails>();
    final state = await testState(api: api, player: player);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    api.detailsGate!.complete(
      VideoDetails(
        info: testVideos.first,
        description: '',
        streams: testStreams,
      ),
    );
    await tester.pumpAndSettle();

    expect(player.videoEnabled, isFalse);
    expect(player.playing, isTrue);
  });

  testWidgets('video without streams still shows info', (tester) async {
    final player = FakePlayerController();
    final api = FakeYouTubeApi(
      details: const VideoDetails(
        info: VideoInfo(
          id: 'v1',
          title: 'First video',
          author: 'A',
          channelId: 'c',
        ),
        description: '',
        streams: [],
      ),
    );
    final state = await testState(api: api, player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.opened, isEmpty);
    expect(find.text('Description'), findsNothing);
  });
}
