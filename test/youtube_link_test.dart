import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/models/youtube_route.dart';
import 'package:newtube/services/innertube_api.dart';
import 'package:newtube/ui/pages/channel_page.dart';
import 'package:newtube/ui/pages/playlist_page.dart';
import 'package:newtube/ui/pages/search_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';

import 'fakes.dart';

void main() {
  group('parseYouTubeLink', () {
    test('watch urls carry video, playlist and start time', () {
      final route = parseYouTubeLink(
        'https://www.youtube.com/watch?v=abc123&list=PLxyz&t=1h2m3s',
      )!;
      expect(route.videoId, 'abc123');
      expect(route.playlistId, 'PLxyz');
      expect(route.startSeconds, 3723);
    });

    test('youtu.be and shorts links resolve to videos', () {
      expect(
        parseYouTubeLink('https://youtu.be/abc123?t=90')!.startSeconds,
        90,
      );
      expect(
        parseYouTubeLink('https://youtube.com/shorts/vid99')!.videoId,
        'vid99',
      );
      expect(
        parseYouTubeLink('https://m.youtube.com/live/live1')!.videoId,
        'live1',
      );
    });

    test('playlist, channel and handle urls route correctly', () {
      expect(
        parseYouTubeLink('https://youtube.com/playlist?list=PL42')!.playlistId,
        'PL42',
      );
      expect(
        parseYouTubeLink('https://youtube.com/channel/UCabcd')!.channelId,
        'UCabcd',
      );
      expect(
        parseYouTubeLink('https://youtube.com/user/someuser')!.channelId,
        'someuser',
      );
      expect(
        parseYouTubeLink('https://youtube.com/c/custom')!.channelId,
        'custom',
      );
      expect(
        parseYouTubeLink('https://youtube.com/@handle/videos')!.channelId,
        '@handle',
      );
    });

    test('non-youtube input returns null', () {
      expect(parseYouTubeLink('plain search text'), isNull);
      expect(parseYouTubeLink('https://example.com/watch?v=x'), isNull);
      expect(looksLikeYouTubeLink('youtube.com/watch?v=x'), isTrue);
      expect(parseYouTubeLink('newtube://watch?v=abc')!.videoId, 'abc');
      expect(parseYouTubeLink('newtube://channel/UC9')!.channelId, 'UC9');
      expect(looksLikeYouTubeLink('https://notyoutube.com'), isFalse);
    });
  });

  test('innertube resolveUrl maps endpoint types', () async {
    final api = InnertubeApi(
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final url = body['url'] as String;
        final endpoint = switch (url) {
          'watch' => {
            'watchEndpoint': {
              'videoId': 'v1',
              'playlistId': 'PLx',
              'startTimeSeconds': 42,
            },
          },
          'playlist' => {
            'browseEndpoint': {'browseId': 'VLlist1'},
          },
          'channel' => {
            'browseEndpoint': {'browseId': 'UCchan'},
          },
          _ => {},
        };
        return http.Response.bytes(
          utf8.encode(jsonEncode({'endpoint': endpoint})),
          200,
        );
      }),
    );
    final watch = (await api.resolveUrl('watch'))!;
    expect(watch.videoId, 'v1');
    expect(watch.playlistId, 'PLx');
    expect(watch.startSeconds, 42);
    expect((await api.resolveUrl('playlist'))!.playlistId, 'list1');
    expect((await api.resolveUrl('channel'))!.channelId, 'UCchan');
    expect(await api.resolveUrl('unknown'), isNull);
  });

  testWidgets('pasting a watch url opens the watch page', (tester) async {
    final api = FakeYouTubeApi(searchResults: const SearchResults(videos: []));
    final state = await testState(api: api);
    await pumpPage(tester, state, const SearchPage());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'https://youtu.be/vid1?t=30',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(WatchPage), findsOneWidget);
  });

  testWidgets('pasting a playlist url opens the playlist page', (tester) async {
    final api = FakeYouTubeApi(searchResults: const SearchResults(videos: []));
    final state = await testState(api: api);
    await pumpPage(tester, state, const SearchPage());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'https://youtube.com/playlist?list=PL1',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(PlaylistPage), findsOneWidget);
  });

  testWidgets('unresolvable youtube urls fall back to search', (tester) async {
    final api = FakeYouTubeApi(
      searchResults: SearchResults(videos: testVideos),
    );
    final state = await testState(api: api);
    await pumpPage(tester, state, const SearchPage());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'https://youtube.com/feed/library',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.textContaining('Results:'), findsOneWidget);
  });

  testWidgets('handle urls resolve via the api', (tester) async {
    final api = FakeYouTubeApi(searchResults: const SearchResults(videos: []))
      ..resolvedUrls = {
        'https://youtube.com/@chan': const YouTubeRoute.channel('UC1'),
      };
    final state = await testState(api: api);
    await pumpPage(tester, state, const SearchPage());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'https://youtube.com/@chan');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(ChannelPage), findsOneWidget);
  });
}
