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
