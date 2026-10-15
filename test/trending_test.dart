import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/services/innertube_api.dart';
import 'package:newtube/ui/pages/trending_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:newtube/ui/shell/app_shell.dart';

import 'fakes.dart';

void main() {
  test('trending browses the livestreams trending tab', () async {
    final browsed = <String>[];
    final api = InnertubeApi(
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final browse = body['browseId'] as String? ?? '';
        browsed.add(browse);
        if (browse != 'UC4R8DWoMoI7CAwX8_LjQHig') {
          return http.Response.bytes(utf8.encode('{}'), 200);
        }
        expect(body['params'], 'EgdsaXZldGFikgEDCKEK');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'contents': {
                'twoColumnBrowseResultsRenderer': {
                  'tabs': [
                    {
                      'tabRenderer': {
                        'content': {
                          'richGridRenderer': {
                            'contents': [
                              {
                                'videoRenderer': {
                                  'videoId': 'tr1',
                                  'title': {
                                    'runs': [
                                      {'text': 'Trending video'},
                                    ],
                                  },
                                  'lengthText': {
                                    'runs': [
                                      {'text': '1:00'},
                                    ],
                                  },
                                },
                              },
                            ],
                          },
                        },
                      },
                    },
                  ],
                },
              },
            }),
          ),
          200,
        );
      }),
    );
    final videos = await api.trending();
    expect(browsed, contains('UC4R8DWoMoI7CAwX8_LjQHig'));
    expect(videos.single.id, 'tr1');
  });

  testWidgets('trending page shows the feed', (tester) async {
    final api = FakeYouTubeApi(feed: testVideos, trendingFeed: testVideos);
    final state = await testState(api: api);
    await pumpPage(tester, state, const TrendingPage());
    await tester.pumpAndSettle();
    expect(find.text(testVideos.first.title), findsWidgets);
  });

  testWidgets('trending page reports errors', (tester) async {
    final api = FakeYouTubeApi()..error = StateError('offline');
    final state = await testState(api: api);
    await pumpPage(tester, state, const TrendingPage());
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('trending destination opens the page', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final api = FakeYouTubeApi(feed: testVideos, trendingFeed: testVideos);
    final state = await testState(api: api);
    await pumpPage(tester, state, const AppShell(), size: const Size(400, 800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trending'));
    await tester.pumpAndSettle();
    expect(state.tabIndex, 1);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('trending card opens the video and channel', (tester) async {
    final api = FakeYouTubeApi(
      feed: testVideos,
      trendingFeed: testVideos,
      uploads: testVideos,
    );
    final state = await testState(api: api);
    await pumpPage(tester, state, const TrendingPage());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Channel One').first);
    await tester.pumpAndSettle();
    expect(find.text('54.3K subscribers'), findsOneWidget);
  });

  testWidgets('trending card opens the watch page', (tester) async {
    final api = FakeYouTubeApi(feed: testVideos, trendingFeed: testVideos);
    final state = await testState(api: api);
    await pumpPage(tester, state, const TrendingPage());
    await tester.pumpAndSettle();
    await tester.tap(find.text(testVideos.first.title).first);
    await tester.pumpAndSettle();
    expect(find.byType(WatchPage), findsOneWidget);
  });
}
