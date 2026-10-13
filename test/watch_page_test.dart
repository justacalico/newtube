import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/pages/watch_page.dart';

import 'fakes.dart';

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

    await tester.tap(find.byTooltip('Quality'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('360p').last);
    await tester.pumpAndSettle();
    expect(player.opened.last, contains('360'));
  });

  testWidgets('stream switch keeps playback position', (tester) async {
    final player = FakePlayerController();
    final state = await testState(api: FakeYouTubeApi(), player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    player.position = const Duration(seconds: 30);
    await tester.tap(find.byTooltip('Quality'));
    await tester.pumpAndSettle();
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
    await tester.tap(find.byTooltip('Quality'));
    await tester.pumpAndSettle();
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

    await tester.tap(find.byTooltip('Quality'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('360p').last);
    await tester.pump();

    await tester.tap(find.byTooltip('Quality'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('720p'));
    await tester.pump();

    player.openGate!.complete();
    await tester.pumpAndSettle();

    expect(player.opened, hasLength(3));
    expect(player.seeks, [Duration.zero]);
  });

  testWidgets('failed stream switch keeps playing the old stream', (
    tester,
  ) async {
    final player = FakePlayerController();
    final state = await testState(api: FakeYouTubeApi(), player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    player.openError = StateError('nope');
    await tester.tap(find.byTooltip('Quality'));
    await tester.pumpAndSettle();
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

    await tester.tap(find.byTooltip('Audio'));
    await tester.pumpAndSettle();
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

    await tester.tap(find.byTooltip('Audio'));
    await tester.pumpAndSettle();
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

    await tester.tap(find.byTooltip('Audio'));
    await tester.pumpAndSettle();
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
    await tester.tap(find.byTooltip('Audio'));
    await tester.pumpAndSettle();
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
    await tester.tap(find.byTooltip('Quality'));
    await tester.pumpAndSettle();
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
    await tester.tap(find.byTooltip('Audio'));
    await tester.pumpAndSettle();
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

  testWidgets('related videos failure still plays', (tester) async {
    final player = FakePlayerController();
    final state = await testState(api: _RelatedFailApi(), player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.opened, isNotEmpty);
    expect(find.text('A video description'), findsOneWidget);
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
