import 'package:newtube/models/search_filter.dart';
import 'package:newtube/models/youtube_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/home_feed.dart';
import 'package:newtube/services/youtube_api.dart';
import 'package:newtube/state/history_store.dart';
import 'package:newtube/state/search_history_store.dart';
import 'package:newtube/state/subscriptions_store.dart';
import 'package:newtube/state/watch_later_store.dart';

VideoInfo vid(
  String id, {
  String title = 'a video',
  String author = 'someone',
  String channelId = 'ch',
  int views = 1000,
}) => VideoInfo(
  id: id,
  title: title,
  author: author,
  channelId: channelId,
  viewCount: views,
);

class _FeedApi implements YouTubeApi {
  List<VideoInfo> feed = const [];
  Map<String, List<VideoInfo>> relatedById = const {};
  Map<String, List<VideoInfo>> uploadsByChannel = const {};
  Map<String, SearchResults> searches = const {};
  Object? feedError;
  Set<String> failingRelated = const {};
  Set<String> failingChannels = const {};
  Set<String> failingQueries = const {};
  final calls = <String>[];

  @override
  Future<List<VideoInfo>> homeFeed() async {
    calls.add('feed');
    if (feedError != null) throw feedError!;
    return feed;
  }

  @override
  Future<List<VideoInfo>> trending() async => feed;

  @override
  @override
  Future<List<String>> searchSuggestions(String query) async => const [];

  @override
  Future<List<VideoInfo>> relatedVideos(String videoId) async {
    calls.add('related:$videoId');
    if (failingRelated.contains(videoId)) throw StateError('related down');
    return relatedById[videoId] ?? const [];
  }

  @override
  Future<List<VideoInfo>> channelVideos(String channelId) async {
    calls.add('channel:$channelId');
    if (failingChannels.contains(channelId)) throw StateError('channel down');
    return uploadsByChannel[channelId] ?? const [];
  }

  @override
  @override
  Future<YouTubeRoute?> resolveUrl(String url) async => null;

  @override
  Future<SearchResults> search(String query, {SearchFilter? filter}) async {
    calls.add('search:$query');
    if (failingQueries.contains(query)) throw StateError('search down');
    return searches[query] ?? const SearchResults();
  }

  @override
  Future<VideoDetails> videoDetails(String videoId) =>
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
  Future<PlaylistInfo> playlist(String playlistId) =>
      throw UnimplementedError();

  @override
  Future<String?> resolveChannel(String url) => throw UnimplementedError();

  @override
  Future<List<CaptionCue>> captions(CaptionTrack track) =>
      throw UnimplementedError();
}

HomeFeed _feedFor(
  _FeedApi api, {
  HistoryStore? history,
  SubscriptionsStore? subscriptions,
  SearchHistoryStore? searchHistory,
  WatchLaterStore? watchLater,
}) => HomeFeed(
  api: api,
  history: history ?? HistoryStore(),
  subscriptions: subscriptions ?? SubscriptionsStore(),
  searchHistory: searchHistory ?? SearchHistoryStore(),
  watchLater: watchLater ?? WatchLaterStore(),
);

void main() {
  test('cold start returns the api feed untouched', () async {
    final api = _FeedApi()..feed = [vid('a'), vid('b')];
    final videos = await _feedFor(api).fetch();
    expect(videos.map((v) => v.id), ['a', 'b']);
    expect(api.calls, ['feed']);
  });

  test('cold start propagates feed errors', () async {
    final api = _FeedApi()..feedError = StateError('nope');
    await expectLater(_feedFor(api).fetch(), throwsStateError);
  });

  test(
    'expands candidates from history seeds and ranks matches first',
    () async {
      final api = _FeedApi()
        ..feed = [
          vid('g1', title: 'cooking show', channelId: 'cg'),
          vid('g2', title: 'gardening tips', channelId: 'cg'),
        ]
        ..relatedById = {
          'w1': [
            vid(
              'r1',
              title: 'flutter widget testing',
              channelId: 'cx',
              author: 'Dev Channel',
            ),
          ],
        };
      final feed = _feedFor(
        api,
        history: HistoryStore([
          vid(
            'w1',
            title: 'flutter widgets deep dive',
            channelId: 'ca',
            author: 'ChanA',
          ),
        ]),
      );
      final videos = await feed.fetch();
      expect(api.calls, containsAll(['feed', 'related:w1', 'channel:ca']));
      expect(videos.first.id, 'r1');
      expect(videos.map((v) => v.id), containsAll(['g1', 'g2', 'r1']));
    },
  );

  test('filters watched videos, empty ids and duplicates', () async {
    final api = _FeedApi()
      ..feed = [vid('g1'), vid('g1')]
      ..relatedById = {
        'w1': [vid('w1'), vid(''), vid('g1'), vid('r1')],
      };
    final feed = _feedFor(
      api,
      history: HistoryStore([vid('w1', channelId: 'ca')]),
    );
    final videos = await feed.fetch();
    expect(videos.map((v) => v.id), containsAll(['g1', 'r1']));
    expect(videos.map((v) => v.id).toSet().length, videos.length);
    expect(videos.any((v) => v.id == 'w1'), isFalse);
  });

  test('subscribed channel uploads are fetched and boosted', () async {
    final api = _FeedApi()
      ..feed = [vid('g1'), vid('g2')]
      ..uploadsByChannel = {
        'cb': [vid('u1', channelId: 'cb', author: 'ChanB')],
      };
    final feed = _feedFor(
      api,
      subscriptions: SubscriptionsStore({
        'cb': const ChannelInfo(id: 'cb', name: 'ChanB'),
      }),
    );
    final videos = await feed.fetch();
    expect(api.calls, contains('channel:cb'));
    expect(videos.first.id, 'u1');
  });

  test('search queries become candidates through topic matching', () async {
    final api = _FeedApi()
      ..feed = [vid('g1')]
      ..searches = {
        'rust programming': SearchResults(
          videos: [vid('s1', title: 'rust programming basics')],
        ),
      };
    final feed = _feedFor(
      api,
      searchHistory: SearchHistoryStore(['rust programming']),
    );
    final videos = await feed.fetch();
    expect(api.calls, contains('search:rust programming'));
    expect(videos.first.id, 's1');
  });

  test('failing sources are tolerated', () async {
    final api = _FeedApi()
      ..feed = [vid('g1')]
      ..failingRelated = {'w1'}
      ..failingChannels = {'cb'}
      ..failingQueries = {'q1'};
    final feed = _feedFor(
      api,
      history: HistoryStore([vid('w1', channelId: 'ca')]),
      subscriptions: SubscriptionsStore({
        'cb': const ChannelInfo(id: 'cb', name: 'ChanB'),
      }),
      searchHistory: SearchHistoryStore(['q1']),
    );
    final videos = await feed.fetch();
    expect(videos.map((v) => v.id), ['g1']);
  });

  test('feed error propagates when nothing else yields videos', () async {
    final error = StateError('feed down');
    final api = _FeedApi()
      ..feedError = error
      ..failingRelated = {'w1'};
    final feed = _feedFor(api, history: HistoryStore([vid('w1')]));
    await expectLater(feed.fetch(), throwsA(same(error)));
  });

  test('feed error is ignored when candidates exist', () async {
    final api = _FeedApi()
      ..feedError = StateError('feed down')
      ..relatedById = {
        'w1': [vid('r1')],
      };
    final feed = _feedFor(api, history: HistoryStore([vid('w1')]));
    final videos = await feed.fetch();
    expect(videos.map((v) => v.id), ['r1']);
  });

  test('all candidates watched returns empty without error', () async {
    final api = _FeedApi()
      ..relatedById = {
        'w1': [vid('w1')],
      };
    final feed = _feedFor(api, history: HistoryStore([vid('w1')]));
    expect(await feed.fetch(), isEmpty);
  });

  test('diversification interleaves channels', () async {
    final api = _FeedApi()
      ..uploadsByChannel = {
        'ca': [
          vid('a1', channelId: 'ca'),
          vid('a2', channelId: 'ca'),
          vid('a3', channelId: 'ca'),
        ],
        'cb': [vid('b1', channelId: 'cb')],
      };
    final feed = _feedFor(
      api,
      subscriptions: SubscriptionsStore({
        'ca': const ChannelInfo(id: 'ca', name: 'ChanA'),
        'cb': const ChannelInfo(id: 'cb', name: 'ChanB'),
      }),
    );
    final videos = await feed.fetch();
    expect(videos.length, 4);
    expect(videos.take(2).map((v) => v.channelId).toSet(), {'ca', 'cb'});
  });

  test('watch later videos contribute to the profile', () async {
    final api = _FeedApi()
      ..uploadsByChannel = {
        'cw': [vid('u1', channelId: 'cw')],
      };
    final feed = _feedFor(
      api,
      watchLater: WatchLaterStore({'s1': vid('s1', channelId: 'cw')}),
    );
    final videos = await feed.fetch();
    expect(api.calls, contains('channel:cw'));
    expect(videos.map((v) => v.id), ['u1']);
  });

  test(
    'videos without channel or author still rank and are not grouped',
    () async {
      final api = _FeedApi()
        ..feed = [
          vid('n1', title: 'piano practice', channelId: '', author: ''),
          vid('n2', title: 'piano practice', channelId: '', author: ''),
        ]
        ..relatedById = {
          'w1': [vid('r1', title: 'unrelated stuff')],
        };
      final feed = _feedFor(
        api,
        history: HistoryStore([
          const VideoInfo(
            id: 'w1',
            title: '2024 !!!',
            author: '',
            channelId: '',
          ),
        ]),
      );
      final videos = await feed.fetch();
      expect(videos.map((v) => v.id), containsAll(['n1', 'n2', 'r1']));
    },
  );
}
