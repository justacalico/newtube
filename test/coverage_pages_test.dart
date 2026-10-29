import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/history_store.dart';
import 'package:newtube/state/hidden_store.dart';
import 'package:newtube/state/subscriptions_store.dart';
import 'package:newtube/state/playlists_store.dart';
import 'package:newtube/state/watch_later_store.dart';
import 'package:newtube/ui/pages/channel_page.dart';
import 'package:newtube/ui/pages/history_page.dart';
import 'package:newtube/ui/pages/local_playlist_page.dart';
import 'package:newtube/ui/pages/subscriptions_page.dart';
import 'package:newtube/ui/pages/playlist_page.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:newtube/ui/pages/watch_later_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:newtube/ui/widgets/video_card.dart';
import 'package:newtube/ui/widgets/thumbnail.dart';
import 'package:newtube/ui/widgets/video_grid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  testWidgets('video menu hides and shares', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final hidden = await HiddenStore.load(
      await SharedPreferences.getInstance(),
    );
    final shares = <String>[];
    final state = await testState(
      hidden: hidden,
      share: RecordingShare(shares),
    );
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: VideoCard(video: testVideos.first, onTap: () {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(VideoCard));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ListTile, 'Not interested'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Not interested'));
    await tester.pumpAndSettle();
    expect(hidden.videos.contains('v1'), isTrue);

    await tester.longPress(find.byType(VideoCard));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(ListTile, "Don't recommend channel"),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, "Don't recommend channel"));
    await tester.pumpAndSettle();
    expect(hidden.channels.contains('c1'), isTrue);

    await tester.longPress(find.byType(VideoCard));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ListTile, 'Share'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Share'));
    await tester.pumpAndSettle();
    expect(shares.single, contains('youtube.com'));

    await tester.longPress(find.byType(VideoCard));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ListTile, 'Watch later'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Watch later'));
    await tester.pumpAndSettle();
    expect(state.watchLater.contains('v1'), isTrue);

    await tester.longPress(find.byType(VideoCard));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ListTile, 'Play next'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Play next'));
    await tester.pumpAndSettle();
    expect(state.playback.queue.first.id, 'v1');

    await tester.longPress(find.byType(VideoCard));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ListTile, 'Add to queue'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Add to queue'));
    await tester.pumpAndSettle();
    expect(state.playback.queue.last.id, 'v1');
  });

  testWidgets('settings hidden items dialog unhides', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final hidden = await HiddenStore.load(prefs);
    await hidden.hideVideo('v9', prefs);
    await hidden.hideChannel('c9', prefs);
    final state = await testState(hidden: hidden);
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Hidden videos and channels'),
      300,
      scrollable: find
          .descendant(
            of: find
                .byWidgetPredicate(
                  (w) => w is ListView && w.scrollDirection == Axis.vertical,
                )
                .first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text('Hidden videos and channels'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hidden videos and channels'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
    await tester.pump();
    expect(hidden.videos, isEmpty);
    expect(hidden.channels, isEmpty);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('backup import failure shows snackbar', (tester) async {
    final state = await testState(openFile: () async => '{broken');
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Import backup'),
      300,
      scrollable: find
          .descendant(
            of: find
                .byWidgetPredicate(
                  (w) => w is ListView && w.scrollDirection == Axis.vertical,
                )
                .first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text('Import backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();
    expect(find.text('Could not import the backup'), findsOneWidget);
  });

  testWidgets('feed layout and codec dropdowns and data saver', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      const SettingsPage(),
      size: const Size(800, 3000),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Feed layout'));
    await tester.tap(find.byType(DropdownButton<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compact grid').last);
    await tester.pumpAndSettle();
    expect(state.settings.feedDensity, 2);

    await tester.ensureVisible(find.text('Preferred codec'));
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Preferred codec'),
        matching: find.byType(DropdownButton<int>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('VP9').last);
    await tester.pumpAndSettle();
    expect(state.settings.preferredCodec, 2);

    await tester.ensureVisible(find.text('Data saver'));
    await tester.tap(find.text('Data saver'));
    await tester.pumpAndSettle();
    expect(state.settings.dataSaver, isTrue);
  });

  testWidgets('history tile shows progress', (tester) async {
    final state = await testState(
      initialPrefs: {
        'history': '[{"id":"v1","title":"First video","author":"Chan","channelId":"c1","duration":200}]',
        'history_positions': '{"v1":100}',
      },
    );
    await pumpPage(tester, state, const HistoryPage());
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('1:40 / 3:20'), findsOneWidget);
  });

  testWidgets('watch later sorts by newest and longest', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = await WatchLaterStore.load(prefs);
    await store.toggle(
      const VideoInfo(
        id: 'old',
        title: 'Old one',
        author: 'a',
        channelId: 'c',
        uploaded: '3 weeks ago',
        duration: Duration(minutes: 5),
      ),
      prefs,
    );
    await store.toggle(
      const VideoInfo(
        id: 'new',
        title: 'New one',
        author: 'a',
        channelId: 'c',
        uploaded: '1 hour ago',
        duration: Duration(hours: 2),
      ),
      prefs,
    );
    final state = await testState(watchLater: store);
    await pumpPage(tester, state, const WatchLaterPage());
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate((w) => w is DropdownButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Newest').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate((w) => w is DropdownButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Longest').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('New one'));
    await tester.pumpAndSettle();
    expect(find.text('New one'), findsWidgets);
  });

  testWidgets('playlist page loads more on scroll', (tester) async {
    final api = FakeYouTubeApi(
      playlistInfo: PlaylistInfo(
        id: 'pl1',
        title: 'Mix',
        author: 'a',
        videoCount: 4,
        videos: testVideos,
        continuation: 'N',
      ),
    );
    final state = await testState(api: api);
    await pumpPage(
      tester,
      state,
      const PlaylistPage(playlistId: 'pl1'),
      size: const Size(500, 400),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
    await tester.pumpAndSettle();
  });

  testWidgets('channel about tab empty and filled', (tester) async {
    final api = FakeYouTubeApi()..uploads = testVideos;
    api.channelAboutInfo = const ChannelAbout(
      description: 'hello',
      joinedText: 'Joined 2019',
      videoCountText: '9 videos',
      subscriberCountText: '1M subs',
    );
    final state = await testState(api: api);
    await pumpPage(tester, state, const ChannelPage(channelId: 'UC1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('video grid cors notice and refresh', (tester) async {
    final state = await testState(isWeb: true);
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: FeedStateView(
          loading: false,
          videos: const [],
          error: StateError('x'),
          onRetry: () {},
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    tester
        .widget<TextButton>(
          find.widgetWithText(TextButton, 'Videos are blocked in the browser'),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsWidgets);
  });
  testWidgets('watch later reorders and opens video', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = await WatchLaterStore.load(prefs);
    await store.toggle(testVideos.first, prefs);
    await store.toggle(testVideos.last, prefs);
    final state = await testState(watchLater: store);
    await pumpPage(tester, state, const WatchLaterPage());
    await tester.pumpAndSettle();
    await tester.drag(find.text(testVideos.first.title), const Offset(0, 200));
    await tester.pumpAndSettle();
    await tester.tap(find.text(testVideos.first.title));
    await tester.pumpAndSettle();
    expect(find.byType(WatchPage), findsOneWidget);
  });

  testWidgets('local playlist rename cancel and reorder', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = await PlaylistsStore.load(prefs);
    final playlist = await store.create('List A', prefs);
    await store.addVideo(playlist.id, testVideos.first, prefs);
    await store.addVideo(playlist.id, testVideos.last, prefs);
    final state = await testState(playlists: store);
    await pumpPage(tester, state, LocalPlaylistPage(playlistId: playlist.id));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Rename playlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.playlists.first.title, 'List A');
    await tester.drag(find.text(testVideos.first.title), const Offset(0, 150));
    await tester.pumpAndSettle();
  });

  testWidgets('channel playlist tap opens playlist page', (tester) async {
    final api = FakeYouTubeApi()
      ..uploads = testVideos
      ..channelPlaylistList = [
        const PlaylistInfo(id: 'pl9', title: 'Open me', videos: []),
      ];
    final state = await testState(api: api);
    await pumpPage(tester, state, const ChannelPage(channelId: 'UC1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Playlists'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open me'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaylistPage), findsOneWidget);
  });

  testWidgets('channel about empty state', (tester) async {
    final api = FakeYouTubeApi()..uploads = testVideos;
    final state = await testState(api: api);
    await pumpPage(tester, state, const ChannelPage(channelId: 'UC1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('No channel info'), findsOneWidget);
  });

  testWidgets('subscription group chips row', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = await SubscriptionsStore.load(prefs);
    await store.subscribe(testChannel, prefs);
    await store.setGroup('c1', 'Fav', prefs);
    final state = await testState(subscriptions: store);
    await pumpPage(tester, state, const SubscriptionsPage());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fav'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All channels'));
    await tester.pumpAndSettle();
  });

  testWidgets('feed state view refresh and cors button', (tester) async {
    final state = await testState(isWeb: true);
    var refreshed = false;
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: FeedStateView(
          loading: false,
          videos: testVideos,
          error: null,
          onRetry: () {},
          onRefresh: () async => refreshed = true,
          child: ListView(children: const [SizedBox(height: 800)]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RefreshIndicator), findsWidgets);
    await tester.fling(find.byType(Scrollable), const Offset(0, 400), 800);
    await tester.pumpAndSettle();
    expect(refreshed, isTrue);
  });

  testWidgets('settings hide watched toggle', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      const SettingsPage(),
      size: const Size(800, 3000),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Hide watched'));
    await tester.tap(find.text('Hide watched'));
    await tester.pumpAndSettle();
    expect(state.settings.hideWatched, isTrue);
  });

  testWidgets('manage groups dialog closes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = await SubscriptionsStore.load(prefs);
    await store.subscribe(testChannel, prefs);
    await store.setGroup('c1', 'G1', prefs);
    final state = await testState(subscriptions: store);
    await pumpPage(
      tester,
      state,
      const SettingsPage(),
      size: const Size(800, 3000),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Subscription groups'));
    await tester.tap(find.text('Subscription groups'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('playlist load more keeps going after error', (tester) async {
    final api = PagingApi();
    final state = await testState(api: api);
    await pumpPage(
      tester,
      state,
      const PlaylistPage(playlistId: 'pl1'),
      size: const Size(500, 400),
    );
    await tester.pumpAndSettle();
    api.fail = true;
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
    await tester.pumpAndSettle();
    api.fail = false;
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.text('Second video'), findsWidgets);
  });

  testWidgets('history page empty state', (tester) async {
    final state = await testState();
    await pumpPage(tester, state, const HistoryPage());
    await tester.pumpAndSettle();
    expect(find.text('Nothing watched yet'), findsOneWidget);
  });

  testWidgets('history filter no-match shows no results', (tester) async {
    final state = await testState(
      initialPrefs: {
        'history': '[{"id":"v1","title":"First video","author":"Chan","channelId":"c1","duration":200}]',
      },
    );
    await pumpPage(tester, state, const HistoryPage());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzzzz');
    await tester.pumpAndSettle();
    expect(find.text('No results'), findsOneWidget);
  });

  testWidgets('watch later reorder and progress', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = await WatchLaterStore.load(prefs);
    final history = await HistoryStore.load(prefs);
    await store.toggle(testVideos.first, prefs);
    await store.toggle(testVideos.last, prefs);
    await history.savePosition('v1', const Duration(seconds: 60), prefs);
    final state = await testState(watchLater: store, history: history);
    await pumpPage(tester, state, const WatchLaterPage());
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsWidgets);
    await tester.longPress(find.text(testVideos.first.title));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.drag(find.text(testVideos.first.title), const Offset(0, 120));
    await tester.pumpAndSettle();
  });

  testWidgets('card icon menu hides video and channel', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final hidden = await HiddenStore.load(prefs);
    final state = await testState(hidden: hidden);
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: VideoCard(video: testVideos.first, onTap: () {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not interested'));
    await tester.pumpAndSettle();
    expect(hidden.videos.contains('v1'), isTrue);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Don't recommend channel"));
    await tester.pumpAndSettle();
    expect(hidden.channels.contains('c1'), isTrue);
  });

  testWidgets('sheet add to playlist opens picker', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = await PlaylistsStore.load(prefs);
    await store.create('List A', prefs);
    final state = await testState(playlists: store);
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: VideoCard(video: testVideos.first, onTap: () {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(VideoCard));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(ListTile, 'Add to playlist'),
    );
    await tester.tap(find.widgetWithText(ListTile, 'Add to playlist'));
    await tester.pumpAndSettle();
    expect(find.text('List A'), findsOneWidget);
  });

  testWidgets('local playlist reorder moves video', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = await PlaylistsStore.load(prefs);
    final playlist = await store.create('List A', prefs);
    await store.addVideo(playlist.id, testVideos.first, prefs);
    await store.addVideo(playlist.id, testVideos.last, prefs);
    final state = await testState(playlists: store);
    await pumpPage(tester, state, LocalPlaylistPage(playlistId: playlist.id));
    await tester.pumpAndSettle();
    final tile = find.text(testVideos.first.title);
    await tester.longPress(tile);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.drag(tile, const Offset(0, 150));
    await tester.pumpAndSettle();
  });

  testWidgets('feed error with refresh wraps indicator', (tester) async {
    final state = await testState(isWeb: true);
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: FeedStateView(
          loading: false,
          videos: const [],
          error: StateError('x'),
          onRetry: () {},
          onRefresh: () async {},
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RefreshIndicator), findsWidgets);
    await tester.tap(find.text('Videos are blocked in the browser').first);
    await tester.pumpAndSettle();
  });

  testWidgets('subscription long-press group cancel', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = await SubscriptionsStore.load(prefs);
    await store.subscribe(testChannel, prefs);
    final state = await testState(subscriptions: store);
    await pumpPage(tester, state, const SubscriptionsPage());
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Channel One'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('watch later drag reorders entries', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = await WatchLaterStore.load(prefs);
    await store.toggle(testVideos.first, prefs);
    await store.toggle(testVideos.last, prefs);
    final state = await testState(watchLater: store);
    await pumpPage(tester, state, const WatchLaterPage());
    await tester.pumpAndSettle();
    final tile = tester.getCenter(find.text(testVideos.first.title));
    final hold = await tester.startGesture(tile);
    await tester.pump(const Duration(milliseconds: 600));
    await hold.moveBy(const Offset(0, 100));
    await tester.pump(const Duration(milliseconds: 300));
    await hold.up();
    await tester.pumpAndSettle();
    expect(store.videos, hasLength(2));
  });

  testWidgets('local playlist drag reorders videos', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = await PlaylistsStore.load(prefs);
    final playlist = await store.create('List A', prefs);
    await store.addVideo(playlist.id, testVideos.first, prefs);
    await store.addVideo(playlist.id, testVideos.last, prefs);
    final state = await testState(playlists: store);
    await pumpPage(tester, state, LocalPlaylistPage(playlistId: playlist.id));
    await tester.pumpAndSettle();
    final tile = tester.getCenter(find.text(testVideos.first.title));
    final hold = await tester.startGesture(tile);
    await tester.pump(const Duration(milliseconds: 600));
    await hold.moveBy(const Offset(0, 100));
    await tester.pump(const Duration(milliseconds: 300));
    await hold.up();
    await tester.pumpAndSettle();
  });

  testWidgets('playlist load more failure recovers', (tester) async {
    final api = PagingApi()..fail = true;
    final state = await testState(api: api);
    await pumpPage(
      tester,
      state,
      const PlaylistPage(playlistId: 'pl1'),
      size: const Size(500, 400),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    api.fail = false;
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('Second video'), findsWidgets);
  });

  testWidgets('feed error refresh branch shows cors button', (tester) async {
    final state = await testState(isWeb: true);
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: FeedStateView(
          loading: false,
          videos: const [],
          error: StateError('x'),
          onRetry: () {},
          onRefresh: () async {},
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Videos are blocked in the browser').last);
    await tester.pumpAndSettle();
  });

  testWidgets('reorder callbacks move items', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = await WatchLaterStore.load(prefs);
    await store.toggle(testVideos.first, prefs);
    await store.toggle(testVideos.last, prefs);
    final state = await testState(watchLater: store);
    await pumpPage(tester, state, const WatchLaterPage());
    await tester.pumpAndSettle();
    final view = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    view.onReorderItem?.call(0, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('local playlist reorder callback moves video', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = await PlaylistsStore.load(prefs);
    final playlist = await store.create('List A', prefs);
    await store.addVideo(playlist.id, testVideos.first, prefs);
    await store.addVideo(playlist.id, testVideos.last, prefs);
    final state = await testState(playlists: store);
    await pumpPage(tester, state, LocalPlaylistPage(playlistId: playlist.id));
    await tester.pumpAndSettle();
    final list = tester.widget<SliverReorderableList>(
      find.byType(SliverReorderableList),
    );
    list.onReorderItem?.call(0, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('feed error refresh callbacks', (tester) async {
    var ran = false;
    final state = await testState(isWeb: true);
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: FeedStateView(
          loading: false,
          videos: const [],
          error: StateError('x'),
          onRetry: () {},
          onRefresh: () async => ran = true,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    tester
        .widget<TextButton>(
          find.widgetWithText(TextButton, 'Videos are blocked in the browser'),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    expect(ran, isTrue);
  });

  testWidgets('video card shows history watch progress', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final history = HistoryStore();
    await history.savePosition('v1', const Duration(minutes: 1), prefs);
    final state = await testState(history: history);
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: VideoCard(video: testVideos.first, onTap: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('thumbnail renders image without an app scope', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: VideoThumbnail(url: 'https://img.youtube.com/x.jpg'),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
  });
}
