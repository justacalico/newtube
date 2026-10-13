import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/history_store.dart';
import 'package:newtube/ui/widgets/subscribe_button.dart';
import 'package:newtube/ui/widgets/thumbnail.dart';
import 'package:newtube/ui/widgets/video_card.dart';
import 'package:newtube/ui/widgets/video_grid.dart';
import 'package:newtube/ui/widgets/video_list_tile.dart';

import 'fakes.dart';

void main() {
  testWidgets('VideoThumbnail falls back when url missing', (tester) async {
    final state = await testState();
    await pumpPage(tester, state, const VideoThumbnail(url: null));
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    await pumpPage(tester, state, const VideoThumbnail(url: ''));
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
  });

  testWidgets('VideoThumbnail loads network image', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      const VideoThumbnail(
        url: 'https://img.example.com/x.jpg',
        width: 40,
        height: 40,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('VideoCard shows metadata and handles taps', (tester) async {
    final state = await testState();
    var tapped = 0;
    var channelTapped = 0;
    await pumpPage(
      tester,
      state,
      SizedBox(
        width: 400,
        height: 400,
        child: VideoCard(
          video: testVideos.first,
          onTap: () => tapped++,
          onChannelTap: () => channelTapped++,
        ),
      ),
    );
    expect(find.text('First video'), findsOneWidget);
    expect(find.text('3:21'), findsOneWidget);
    expect(find.text('12.3K views · 2 days ago'), findsOneWidget);

    await tester.tap(find.text('Channel One'));
    expect(channelTapped, 1);
    await tester.tap(find.text('First video'));
    expect(tapped, 1);
  });

  testWidgets('VideoCard hides empty meta', (tester) async {
    final state = await testState();
    const video = VideoInfo(
      id: 'x',
      title: 'Bare',
      author: 'A',
      channelId: 'c',
    );
    await pumpPage(
      tester,
      state,
      SizedBox(
        width: 400,
        height: 400,
        child: VideoCard(video: video, onTap: () {}),
      ),
    );
    expect(find.text('Bare'), findsOneWidget);
    expect(find.textContaining('views'), findsNothing);
  });

  testWidgets('VideoCard badge follows watch history', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      SizedBox(
        width: 400,
        height: 400,
        child: VideoCard(video: testVideos.first, onTap: () {}),
      ),
    );
    expect(find.text('Watched'), findsNothing);

    await state.history.record(testVideos.first, state.prefs);
    await tester.pump();
    expect(find.text('Watched'), findsOneWidget);
  });

  testWidgets('VideoGrid lays out cards', (tester) async {
    final state = await testState();
    var tapped = 0;
    await pumpPage(
      tester,
      state,
      SizedBox(
        width: 700,
        height: 600,
        child: VideoGrid(
          videos: testVideos,
          onVideoTap: (_) => tapped++,
          onChannelTap: (_) {},
        ),
      ),
    );
    expect(find.text('First video'), findsOneWidget);
    await tester.tap(find.text('First video'));
    expect(tapped, 1);
  });

  testWidgets('VideoListTile shows video and handles taps', (tester) async {
    final state = await testState();
    var tapped = 0;
    await pumpPage(
      tester,
      state,
      VideoListTile(video: testVideos.first, onTap: () => tapped++),
    );
    expect(find.text('First video'), findsOneWidget);
    expect(find.text('Channel One'), findsOneWidget);
    expect(find.text('3:21'), findsOneWidget);
    await tester.tap(find.text('First video'));
    expect(tapped, 1);
  });

  testWidgets('VideoListTile shows watched badge', (tester) async {
    final state = await testState(history: HistoryStore([testVideos.first]));
    await pumpPage(
      tester,
      state,
      VideoListTile(video: testVideos.first, onTap: () {}),
    );
    expect(find.text('Watched'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('VideoListTile omits missing duration', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      VideoListTile(video: testVideos[1], onTap: () {}),
    );
    expect(find.text('Second video'), findsOneWidget);
    expect(
      find.byType(ListTile).evaluate().single.widget,
      isA<ListTile>().having((t) => t.trailing, 'trailing', isNull),
    );
  });

  testWidgets('FeedStateView shows each state', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      const FeedStateView(
        loading: true,
        error: null,
        videos: [],
        onRetry: _noop,
        child: Text('content'),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await pumpPage(
      tester,
      state,
      FeedStateView(
        loading: false,
        error: 'bad',
        videos: const [],
        onRetry: () {},
        child: const Text('content'),
      ),
    );
    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Retry'));
  });

  testWidgets('SubscribeButton toggles subscription', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      const Scaffold(body: SubscribeButton(channel: testChannel)),
    );
    expect(find.text('Subscribe'), findsOneWidget);
    await tester.tap(find.text('Subscribe'));
    await tester.pump();
    expect(find.text('Subscribed'), findsOneWidget);
    await tester.tap(find.text('Subscribed'));
    await tester.pump();
    expect(find.text('Subscribe'), findsOneWidget);
  });
}

void _noop() {}
