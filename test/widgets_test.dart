import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/history_store.dart';
import 'package:newtube/state/playlists_store.dart';
import 'package:newtube/ui/widgets/subscribe_button.dart';
import 'package:newtube/ui/widgets/thumbnail.dart';
import 'package:newtube/ui/widgets/video_actions_menu.dart';
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

  testWidgets('VideoCard fits the continue watching strip', (tester) async {
    final state = await testState();
    const video = VideoInfo(
      id: 'x',
      title: 'This Upgrade Proved I am Weak and Other Long Words',
      author: 'Channel One',
      channelId: 'c',
      viewCount: 685000,
      uploaded: '3 days ago',
      duration: Duration(minutes: 12),
    );
    await pumpPage(
      tester,
      state,
      const SizedBox(
        width: 160,
        height: 112,
        child: VideoCard(video: video, onTap: _noop),
      ),
    );
    expect(tester.takeException(), isNull);
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
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    final trailing = tile.trailing! as Row;
    expect(trailing.children.single, isA<VideoActionsMenu>());
  });

  testWidgets('VideoActionsMenu toggles watch later', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      VideoListTile(video: testVideos.first, onTap: () {}),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Watch later'), findsOneWidget);
    expect(find.text('Add to playlist'), findsOneWidget);

    await tester.tap(find.text('Watch later'));
    await tester.pumpAndSettle();
    expect(state.watchLater.contains('v1'), isTrue);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Remove from Watch later'), findsOneWidget);
    await tester.tap(find.text('Remove from Watch later'));
    await tester.pumpAndSettle();
    expect(state.watchLater.contains('v1'), isFalse);
  });

  testWidgets('VideoActionsMenu opens the playlist picker', (tester) async {
    final store = PlaylistsStore([const PlaylistInfo(id: 'p1', title: 'Mix')]);
    final state = await testState(playlists: store);
    await pumpPage(
      tester,
      state,
      SizedBox(
        width: 400,
        height: 400,
        child: VideoCard(video: testVideos.first, onTap: () {}),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to playlist'));
    await tester.pumpAndSettle();
    expect(find.text('Mix'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(store.containsVideo('p1', 'v1'), isTrue);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Add to playlist'), findsNothing);
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
