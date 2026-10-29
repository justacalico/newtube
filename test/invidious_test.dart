import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/fallback_api.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

import 'package:newtube/services/innertube_api.dart';
import 'package:newtube/services/invidious_api.dart';

Map<String, String> _routes() => {
  '/api/v1/trending': '''[{
        "type":"video",
        "videoId":"abc",
        "title":"Trending one",
        "author":"Chan",
        "authorId":"UC1",
        "lengthSeconds":120,
        "viewCount":42,
        "videoThumbnails":[{"quality":"medium","url":"//i.ytimg.com/vi/abc/mqdefault.jpg"}]
      }]''',
  '/api/v1/search': '''[{
        "type":"video","videoId":"v1","title":"Hit","author":"A","authorId":"UC9"
      },{
        "type":"channel","author":"Chan2","authorId":"UC2","subCount":100
      },{
        "type":"playlist","playlistId":"PL1","title":"Pl","author":"A","videoCount":3,"videos":[]
      }]''',
  '/api/v1/videos/v1': '''{
        "title":"Hit","author":"A","authorId":"UC9",
        "lengthSeconds":300,"viewCount":99,"likeCount":5,
        "description":"desc","publishedText":"2 days ago",
        "formatStreams":[{"url":"https://v1","type":"video/mp4; codecs=\\"avc1\\"","qualityLabel":"720p"}],
        "adaptiveFormats":[{"url":"https://a1","type":"audio/mp4; codecs=\\"mp4a\\"","bitrate":"128000","size":"1280x720"}],
        "captions":[{"label":"English","languageCode":"en"}],
        "recommendedVideos":[{"videoId":"r1","title":"Rel","author":"B","authorId":"UC2"}]
      }''',
  '/api/v1/comments/v1': '''{
        "comments":[{"commentId":"c1","author":"u","content":"nice","likeCount":3,"publishedText":"1 day ago","replies":{"replyCount":2}}],
        "continuation":"next"
      }''',
  '/api/v1/channels/UC1': '''{
        "author":"Chan","authorThumbnails":[{"url":"https://t/1.png"}],
        "subCount":55,"description":"about","totalViews":9000,"joined":1600000000
      }''',
  '/api/v1/channels/UC1/videos':
      '''[{"videoId":"x1","title":"Up1","author":"Chan","authorId":"UC1"}]''',
  '/api/v1/channels/UC1/shorts': '''[{"type":"shortVideo","videoId":"sh1","title":"#short clip","author":"Chan","authorId":"UC1","lengthSeconds":30}]''',
  '/caps': '''WEBVTT

00:00:00.000 --> 00:00:02.000
hello
''',
  '/api/v1/channels/UC1/playlists': '''{"playlists":[{"playlistId":"PL9","title":"P","author":"Chan","videoCount":2}]}''',
  '/api/v1/playlists/PL1': '''{"title":"P","author":"Chan","videoCount":120,"videos":[{"videoId":"v9","title":"a","author":"x","authorId":"UC3"}]}''',
  '/api/v1/channels/UC9/videos': '''[{
        "type":"video","videoId":"sh9","title":"#mini clip","author":"A","authorId":"UC9","lengthSeconds":45,
        "videoThumbnails":[{"quality":"high","url":"//i.ytimg.com/vi/sh9/hq.jpg"}]
      }]''',
  '/api/v1/search/suggestions': '{"suggestions":["cats","cats and dogs"]}',
};

InvidiousApi _api(Map<String, List<http.Response>> Function(String)? unused) {
  final routes = _routes();
  return InvidiousApi(
    instance: 'https://inv.test',
    client: MockClient((req) async {
      final body = routes[req.url.path] ?? '[]';
      return http.Response(body, 200);
    }),
  );
}

void main() {
  late InvidiousApi api;
  setUp(() => api = _api((_) => {}));

  test('trending maps videos', () async {
    final videos = await api.trending();
    expect(videos.single.id, 'abc');
    expect(videos.single.title, 'Trending one');
    expect(
      videos.single.thumbnailUrl,
      'https://i.ytimg.com/vi/abc/mqdefault.jpg',
    );
    expect(videos.single.duration, const Duration(minutes: 2));
  });

  test('search splits videos/channels/playlists', () async {
    final r = await api.search('q');
    expect(r.videos.single.id, 'v1');
    expect(r.channels.single.id, 'UC2');
    expect(r.playlists.single.id, 'PL1');
  });

  test('videoDetails maps streams, captions, related', () async {
    final d = await api.videoDetails('v1');
    expect(d.info.title, 'Hit');
    expect(d.streams.length, 2);
    expect(d.streams.last.hasAudio, isTrue);
    expect(d.captions.single.name, 'English');
    expect(d.captions.single.url, contains('inv.test'));
  });

  test('related + comments + suggestions', () async {
    final rel = await api.relatedVideos('v1');
    expect(rel.single.id, 'r1');
    final c = await api.comments('v1');
    expect(c.comments.single.author, 'u');
    expect(c.continuation, 'next');
    expect(await api.searchSuggestions('cat'), ['cats', 'cats and dogs']);
  });

  test('channel endpoints', () async {
    final ch = await api.channel('UC1');
    expect(ch.name, 'Chan');
    expect(ch.subscribers, 55);
    final about = await api.channelAbout('UC1');
    expect(about.description, 'about');
    final vids = await api.channelVideos('UC1');
    expect(vids.single.title, 'Up1');
    final pls = await api.channelPlaylists('UC1');
    expect(pls.single.id, 'PL9');
  });

  test('playlist reports continuation while more pages exist', () async {
    final p = await api.playlist('PL1');
    expect(p.continuation, '2');
    expect(p.videos.single.id, 'v9');
  });

  test('errors surface on non-200', () async {
    final api = InvidiousApi(
      instance: 'https://inv.test',
      client: MockClient((_) async => http.Response('oops', 500)),
    );
    expect(() => api.trending(), throwsA(isA<InvidiousException>()));
  });

  test('fallback api retries on secondary', () async {
    final primary = InnertubeApi(
      httpClient: MockClient((_) async => http.Response('broken', 500)),
    );
    final combined = FallbackApi(primary, api);
    final videos = await combined.trending();
    expect(videos.single.id, 'abc');
  });

  test('settings persist fallback backend', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = await SettingsStore.load(prefs);
    expect(settings.fallbackBackend, '');
    await settings.setFallbackBackend(' https://inv.example ', prefs);
    expect(settings.fallbackBackend, 'https://inv.example');
    final reloaded = await SettingsStore.load(prefs);
    expect(reloaded.fallbackBackend, 'https://inv.example');
  });

  testWidgets('fallback backend field in settings', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      const SettingsPage(),
      size: const Size(800, 3000),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'https://yewtu.be',
      ),
      'https://inv.example',
    );
    await tester.pump();
    expect(state.settings.fallbackBackend, 'https://inv.example');
  });

  test('fallback delegates every call to primary then secondary', () async {
    var fail = true;
    final fake = FakeYouTubeApi(
      feed: [testVideos.first],
      trendingFeed: [testVideos.first],
    );
    final probe = _CountingApi(fake, () => fail);
    final api = FallbackApi(probe, fake);
    expect((await api.homeFeed()).single.id, 'v1');
    expect((await api.trending()).single.id, 'v1');
    expect((await api.search('x')).videos, isEmpty);
    expect(await api.resolveUrl('https://youtu.be/v1'), isNull);
    expect(await api.searchSuggestions('x'), isEmpty);
    expect((await api.videoDetails('v1')).info.id, isNotEmpty);
    expect(await api.relatedVideos('v1'), isEmpty);
    expect((await api.comments('v1')).comments, isEmpty);
    expect((await api.channel('c1')).name, 'Channel One');
    expect(await api.channelShorts('c1'), isEmpty);
    expect(await api.channelPlaylists('c1'), isEmpty);
    expect((await api.channelAbout('c1')).description, '');
    expect(await api.channelSearch('c1', 'x'), isEmpty);
    expect((await api.playlist('p')).id, 'pl1');
    expect(await api.resolveChannel('https://youtube.com/@x'), isNull);
    expect(await api.channelVideos('c1'), isEmpty);
    expect(probe.calls, 2);
    fail = false;
    expect((await api.homeFeed()).single.id, 'v1');
    expect(probe.calls, 3);
  });

  test('resolveUrl parses links locally', () async {
    final route = await api.resolveUrl('https://youtu.be/abc');
    expect(route?.videoId, 'abc');
    expect(await api.resolveChannel('https://youtube.com/channel/UC5'), 'UC5');
  });
  test('trailing-slash instance produces single-slash URLs', () async {
    Uri? requested;
    final trailing = InvidiousApi(
      instance: 'https://inv.test/',
      client: MockClient((req) async {
        requested = req.url;
        return http.Response('[]', 200);
      }),
    );
    await trailing.trending();
    expect(requested!.path, '/api/v1/trending');
  });

  test('homeFeed delegates to trending', () async {
    final bare = InvidiousApi(instance: 'https://inv.test');
    expect(bare, isNotNull);
    final feed = await api.homeFeed();
    expect(feed.single.id, 'abc');
  });

  test('comments supports continuation and sort', () async {
    final c = await api.comments(
      'v1',
      continuation: 'tok',
      sort: CommentSort.newest,
    );
    expect(c.comments.single.replyCount, 2);
    expect(c.continuation, 'next');
  });

  test('channel shorts, search and errors', () async {
    expect((await api.channelShorts('UC1')).single.id, 'sh1');
    final short = (await api.channelVideos('UC9')).single;
    expect(short.isShort, isTrue);
    expect(short.thumbnailUrl, contains('hq.jpg'));
    expect(await api.playlist('PL1', continuation: '2'), isNotNull);
    expect(await api.playlist('PL1', continuation: 'x'), isNotNull);
    final hits = await api.channelSearch('UC1', 'up');
    expect(hits.single.id, 'x1');
    expect(await api.channelSearch('UC1', 'zzz'), isEmpty);
    expect(() => api.channel('missing'), throwsA(isA<InvidiousException>()));
    expect(
      () => api.videoDetails('missing'),
      throwsA(isA<InvidiousException>()),
    );
    expect(() => api.playlist('missing'), throwsA(isA<InvidiousException>()));
    expect(const InvidiousException('x').toString(), 'InvidiousException: x');
  });

  test('channelAbout formats joined date', () async {
    final about = await api.channelAbout('UC1');
    expect(about.joinedText, startsWith('2020'));
    expect(about.subscriberCountText, '55 subscribers');
  });

  test('captions fetch and parse', () async {
    final cues = await api.captions(
      const CaptionTrack(
        languageCode: 'en',
        name: 'English',
        url: 'https://inv.test/caps',
      ),
    );
    expect(cues.single.text, contains('hello'));
    final bad = InvidiousApi(
      instance: 'https://inv.test',
      client: MockClient((_) async => http.Response('x', 500)),
    );
    expect(
      () => bad.captions(
        const CaptionTrack(
          languageCode: 'en',
          name: 'x',
          url: 'https://inv.test/none',
        ),
      ),
      throwsA(isA<InvidiousException>()),
    );
  });
}

class _CountingApi extends FakeYouTubeApi {
  final FakeYouTubeApi inner;
  final bool Function() shouldFail;
  int calls = 0;

  _CountingApi(this.inner, this.shouldFail);

  @override
  Future<List<VideoInfo>> homeFeed() {
    calls++;
    if (shouldFail()) throw StateError('down');
    return inner.homeFeed();
  }

  @override
  Future<List<VideoInfo>> trending() {
    calls++;
    if (shouldFail()) throw StateError('down');
    return inner.trending();
  }
}
