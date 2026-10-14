import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/search_filter.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/models/youtube_route.dart';
import 'package:newtube/services/backup.dart';
import 'package:newtube/services/dearrow_api.dart';
import 'package:newtube/services/fallback_api.dart';
import 'package:newtube/services/network_proxy_io.dart';
import 'package:newtube/services/dearrow.dart';
import 'package:newtube/services/downloads.dart';
import 'package:newtube/services/innertube_api.dart';
import 'package:newtube/services/share.dart';
import 'package:newtube/services/sponsor_block.dart';
import 'package:newtube/services/youtube_api.dart';
import 'package:newtube/state/downloads_store.dart';
import 'package:newtube/state/history_store.dart';
import 'package:newtube/state/playback_session.dart';
import 'package:newtube/state/hidden_store.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/state/subscriptions_store.dart';
import 'package:newtube/state/playlists_store.dart';
import 'package:newtube/state/watch_later_store.dart';
import 'package:newtube/ui/pages/channel_page.dart';
import 'package:newtube/ui/pages/download_player_page.dart';
import 'package:newtube/ui/pages/history_page.dart';
import 'package:newtube/ui/pages/local_playlist_page.dart';
import 'package:newtube/ui/pages/subscriptions_page.dart';
import 'package:newtube/ui/pages/playlist_page.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:newtube/ui/pages/watch_later_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:newtube/ui/widgets/player_view.dart';
import 'package:newtube/ui/widgets/video_card.dart';
import 'package:newtube/ui/widgets/mini_player.dart';
import 'package:newtube/ui/widgets/video_grid.dart';
import 'package:newtube/utils/relative_date.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

class _BareApi extends YouTubeApi {
  final List<VideoInfo> uploads;
  _BareApi([this.uploads = const []]);

  @override
  Future<List<VideoInfo>> homeFeed() => throw UnimplementedError();
  @override
  Future<List<VideoInfo>> trending() => throw UnimplementedError();
  @override
  Future<SearchResults> search(String query, {SearchFilter? filter}) =>
      throw UnimplementedError();
  @override
  Future<YouTubeRoute?> resolveUrl(String url) => throw UnimplementedError();
  @override
  Future<List<String>> searchSuggestions(String query) =>
      throw UnimplementedError();
  @override
  Future<VideoDetails> videoDetails(String videoId) =>
      throw UnimplementedError();
  @override
  Future<List<VideoInfo>> relatedVideos(String videoId) =>
      throw UnimplementedError();
  @override
  Future<CommentsResult> comments(
    String videoId, {
    String? continuation,
    CommentSort? sort,
  }) => throw UnimplementedError();
  @override
  Future<ChannelInfo> channel(String channelId) => throw UnimplementedError();
  @override
  Future<PlaylistInfo> playlist(String playlistId, {String? continuation}) =>
      throw UnimplementedError();
  @override
  Future<String?> resolveChannel(String url) => throw UnimplementedError();
  @override
  Future<List<VideoInfo>> channelVideos(String channelId) async => uploads;
  @override
  Future<List<CaptionCue>> captions(CaptionTrack track) =>
      throw UnimplementedError();
}

void main() {
  test('youtube api default channel methods', () async {
    final api = _BareApi(const [
      VideoInfo(
        id: 's1',
        title: 'Short clip',
        author: 'a',
        channelId: 'c',
        isShort: true,
      ),
      VideoInfo(id: 'v1', title: 'Normal', author: 'a', channelId: 'c'),
    ]);
    expect((await api.channelShorts('c')).single.id, 's1');
    expect(await api.channelPlaylists('c'), isEmpty);
    expect((await api.channelAbout('c')).description, '');
    expect((await api.channelSearch('c', 'short')).single.id, 's1');
    expect(await api.channelSearch('c', 'zzz'), isEmpty);
  });

  test('hidden store hides and unhides', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = await HiddenStore.load(prefs);
    await store.hideVideo('v1', prefs);
    await store.hideChannel('c1', prefs);
    expect(store.videos.contains('v1'), isTrue);
    expect(store.channels.contains('c1'), isTrue);
    await store.unhideVideo('v1', prefs);
    await store.unhideChannel('c1', prefs);
    expect(store.videos, isEmpty);
    expect(store.channels, isEmpty);
  });

  test('playback session takePrevious and takeNextFrom', () {
    const a = VideoInfo(id: 'a', title: 'A', author: '', channelId: '');
    const b = VideoInfo(id: 'b', title: 'B', author: '', channelId: '');
    const c = VideoInfo(id: 'c', title: 'C', author: '', channelId: '');
    final session = PlaybackSession();
    session.attach(FakePlayerController(), a);
    session
      ..enqueue(b)
      ..enqueue(c);
    expect(session.hasNext, isTrue);
    expect(session.takeNext()!.id, 'b');
    expect(session.takePrevious()!.id, 'a');
    expect(session.hasPrevious, isFalse);
    expect(session.takeNextFrom(0)!.id, 'a');
    expect(session.takeNextFrom(5), isNull);
  });

  test('dearrow api delegates channel methods', () async {
    final fake = FakeYouTubeApi();
    final api = DeArrowApi(
      settings: SettingsStore(),
      client: DeArrowClient(),
      inner: fake,
    );
    expect(await api.channelShorts('c1'), isEmpty);
    expect(await api.channelPlaylists('c1'), isEmpty);
    expect((await api.channelAbout('c1')).description, '');
    expect(await api.channelSearch('c1', 'x'), isEmpty);
  });

  test('downloads store tolerates corrupt entries', () async {
    SharedPreferences.setMockInitialValues({'downloads': '{bad'});
    final prefs = await SharedPreferences.getInstance();
    final store = await DownloadsStore.load(prefs);
    expect(store.entries, isEmpty);
    SharedPreferences.setMockInitialValues({
      'downloads': '[{"id":"v1","title":"t","author":"a","channelId":"c","duration":10,"path":"/x"}]',
    });
    final store2 = await DownloadsStore.load(
      await SharedPreferences.getInstance(),
    );
    expect(store2.entries.single.video.id, 'v1');
  });

  test('proxyHttpClient builds io client for rules', () {
    expect(proxyHttpClient(''), isNull);
    expect(proxyHttpClient('  '), isNull);
  });

  test('parseRelativeDate units', () {
    final now = DateTime(2024, 6, 1);
    expect(
      parseRelativeDate('1 second ago', now),
      now.subtract(const Duration(seconds: 1)),
    );
    expect(
      parseRelativeDate('2 minutes ago', now),
      now.subtract(const Duration(minutes: 2)),
    );
    expect(parseRelativeDate('1 year ago', now)!.year, now.year - 1);
    expect(parseRelativeDate('3 decades ago', now), isNull);
    expect(parseRelativeDate('bogus', now), isNull);
  });

  test('importBackup rejects bad json', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(() => importBackup('{not json', prefs), throwsA(anything));
    expect(() => importBackup('{"other":{}}', prefs), throwsA(anything));
  });

  testWidgets('video menu hides and shares', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final hidden = await HiddenStore.load(
      await SharedPreferences.getInstance(),
    );
    final shares = <String>[];
    final state = await testState(hidden: hidden, share: _Share(shares));
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

  testWidgets('watch page playability errors', (tester) async {
    final api = FakeYouTubeApi()
      ..error = const PlayabilityException('LOGIN_REQUIRED', 'age check');
    final state = await testState(api: api);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(find.text('This video is age-restricted'), findsOneWidget);
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
    await tester.pumpAndSettle();
    await tester.tap(find.text('Videos are blocked in the browser').first);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });
  test('playability exception classification', () {
    const e = PlayabilityException('ERROR', 'gone');
    expect(e.isPrivate, isTrue);
    expect(e.isUnavailable, isTrue);
    expect(e.isAgeGate, isFalse);
    expect(const PlayabilityException('UNPLAYABLE', 'x').isUnavailable, isTrue);
    expect(
      const PlayabilityException('LIVE_STREAM_OFFLINE', 'x').isUnavailable,
      isTrue,
    );
    expect(e.toString(), contains('gone'));
  });

  test('fallback api covers channel videos and captions', () async {
    final api = FallbackApi(FakeYouTubeApi(), FakeYouTubeApi());
    expect(await api.channelVideos('c1'), isEmpty);
    expect(
      await api.captions(
        const CaptionTrack(languageCode: 'en', name: 'en', url: 'u'),
      ),
      isEmpty,
    );
  });

  test('importBackup restores each pref type', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final text = jsonEncode({
      'prefs': {
        'flag': true,
        'count': 3,
        'ratio': 1.5,
        'name': 'x',
        'tags': ['a', 'b'],
        'nested': {'no': 'way'},
      },
    });
    final count = await importBackup(text, prefs);
    expect(count, 5);
    expect(prefs.getDouble('ratio'), 1.5);
    expect(prefs.getStringList('tags'), ['a', 'b']);
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
    final state = await testState(downloads: _FailDownloads());
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
    final api = _PagingApi();
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
    await tester.timedDrag(
      find.text(testVideos.first.title),
      const Offset(0, 140),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate((w) => w is DropdownButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Longest').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(testVideos.first.title));
    await tester.pumpAndSettle();
    expect(find.byType(WatchPage), findsOneWidget);
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
    await tester.timedDrag(
      find.text(testVideos.first.title),
      const Offset(0, 140),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
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
    await tester.timedDrag(
      find.text(testVideos.last.title).last,
      const Offset(0, -80),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('playlist load more failure recovers', (tester) async {
    final api = _PagingApi()..fail = true;
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
    await tester.tap(find.byType(TextButton));
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
}

class _Share implements ShareActions {
  final List<String> out;
  _Share(this.out);
  @override
  Future<void> share(String text) async => out.add(text);
}

class _PagingApi extends FakeYouTubeApi {
  bool fail = false;
  _PagingApi()
    : super(
        playlistInfo: PlaylistInfo(
          id: 'pl1',
          title: 'Mix',
          author: 'a',
          videoCount: 4,
          videos: testVideos,
          continuation: 'N',
        ),
      );

  @override
  Future<PlaylistInfo> playlist(
    String playlistId, {
    String? continuation,
  }) async {
    if (continuation != null && fail) throw StateError('paging');
    if (continuation == 'N') {
      return PlaylistInfo(
        id: 'pl1',
        title: 'Mix',
        author: 'a',
        videos: [
          const VideoInfo(
            id: 'extra',
            title: 'Second video',
            author: 'a',
            channelId: 'c',
          ),
        ],
      );
    }
    return super.playlist(playlistId, continuation: continuation);
  }
}

class _FailDownloads implements DownloadActions {
  @override
  Future<String?> download(String url, String name) async => null;
}
