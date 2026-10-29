import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/innertube_api.dart';
import 'package:newtube/state/watch_later_store.dart';
import 'package:newtube/ui/pages/playlist_page.dart';
import 'package:newtube/ui/pages/search_page.dart';
import 'package:newtube/ui/pages/watch_later_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Map<String, dynamic> _playlistBrowse() => {
  'header': {
    'playlistHeaderRenderer': {
      'title': {
        'runs': [
          {'text': 'My list'},
        ],
      },
      'ownerText': {
        'runs': [
          {'text': 'Owner'},
        ],
      },
      'numVideosText': {'simpleText': '2 videos'},
      'avatar': {
        'thumbnails': [
          {'url': 'https://i/pl.jpg'},
        ],
      },
    },
  },
  'contents': {
    'twoColumnBrowseResultsRenderer': {
      'tabs': [
        {
          'tabRenderer': {
            'content': {
              'sectionListRenderer': {
                'contents': [
                  {
                    'itemSectionRenderer': {
                      'contents': [
                        {
                          'playlistVideoListRenderer': {
                            'contents': [
                              {
                                'playlistVideoRenderer': {
                                  'videoId': 'v1',
                                  'title': {
                                    'runs': [
                                      {'text': 'Entry one'},
                                    ],
                                  },
                                  'shortBylineText': {
                                    'runs': [
                                      {
                                        'text': 'Chan',
                                        'navigationEndpoint': {
                                          'browseEndpoint': {'browseId': 'UCx'},
                                        },
                                      },
                                    ],
                                  },
                                  'thumbnail': {
                                    'thumbnails': [
                                      {'url': 'https://i/v1.jpg'},
                                    ],
                                  },
                                  'lengthText': {'simpleText': '3:00'},
                                  'videoInfo': {
                                    'runs': [
                                      {'text': '5 views'},
                                      {'text': ' • '},
                                      {'text': '2 days ago'},
                                    ],
                                  },
                                },
                              },
                              {
                                'playlistVideoRenderer': {
                                  'videoId': 'v2',
                                  'title': {'simpleText': 'Entry two'},
                                },
                              },
                              {
                                'playlistVideoRenderer': {'bad': true},
                              },
                            ],
                          },
                        },
                      ],
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
};

InnertubeApi _api(Map<String, dynamic> response) => InnertubeApi(
  httpClient: MockClient((request) async {
    if (request.method != 'POST') return http.Response.bytes(const [], 206);
    return http.Response.bytes(utf8.encode(jsonEncode(response)), 200);
  }),
);

void main() {
  group('innertube playlists', () {
    test('playlist parses header and entries', () async {
      String? browseId;
      final api = InnertubeApi(
        httpClient: MockClient((request) async {
          if (request.method != 'POST') {
            return http.Response.bytes(const [], 206);
          }
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          browseId = body['browseId'] as String?;
          return http.Response.bytes(
            utf8.encode(jsonEncode(_playlistBrowse())),
            200,
          );
        }),
      );
      final playlist = await api.playlist('PLabc');
      expect(browseId, 'VLPLabc');
      expect(playlist.title, 'My list');
      expect(playlist.author, 'Owner');
      expect(playlist.videoCount, 2);
      expect(playlist.thumbnailUrl, 'https://i/pl.jpg');
      expect(playlist.videos, hasLength(2));
      expect(playlist.videos.first.id, 'v1');
      expect(playlist.videos.first.title, 'Entry one');
      expect(playlist.videos.first.author, 'Chan');
      expect(playlist.videos.first.channelId, 'UCx');
      expect(playlist.videos.first.duration, const Duration(minutes: 3));
      expect(playlist.videos.first.uploaded, '2 days ago');
      expect(playlist.videos[1].id, 'v2');
      expect(playlist.videos[1].duration, isNull);
    });

    test('playlist falls back to metadata and first thumb', () async {
      final api = _api({
        'metadata': {
          'playlistMetadataRenderer': {'title': 'Meta title'},
        },
        'x': {
          'playlistVideoRenderer': {
            'videoId': 'v9',
            'title': <String, dynamic>{},
          },
        },
      });
      final playlist = await api.playlist('VLraw');
      expect(playlist.title, 'Meta title');
      expect(playlist.author, '');
      expect(playlist.videoCount, 1);
      expect(playlist.videos.single.id, 'v9');
    });

    test('search returns playlists', () async {
      final api = _api({
        'contents': {
          'x': {
            'playlistRenderer': {
              'playlistId': 'PLx',
              'title': {'simpleText': 'Mix results'},
              'longBylineText': {'simpleText': 'DJ'},
              'thumbnail': {
                'thumbnails': [
                  {'url': 'https://i/plx.jpg'},
                ],
              },
              'videoCountText': {'simpleText': '42 videos'},
            },
          },
          'y': {
            'playlistRenderer': {'bad': true},
          },
        },
      });
      final r = await api.search('q');
      expect(r.playlists.single.id, 'PLx');
      expect(r.playlists.single.title, 'Mix results');
      expect(r.playlists.single.author, 'DJ');
      expect(r.playlists.single.videoCount, 42);
    });
  });

  group('watch later store', () {
    Future<SharedPreferences> prefs([Map<String, Object> v = const {}]) async {
      SharedPreferences.setMockInitialValues(v);
      return SharedPreferences.getInstance();
    }

    test('toggles, persists and round-trips', () async {
      final p = await prefs();
      final store = WatchLaterStore();
      expect(store.videos, isEmpty);
      await store.toggle(testVideos.first, p);
      expect(store.contains('v1'), isTrue);
      await store.toggle(testVideos.first, p);
      expect(store.contains('v1'), isFalse);
      await store.toggle(testVideos.first, p);
      await store.toggle(testVideos[1], p);

      final reloaded = await WatchLaterStore.load(p);
      expect(reloaded.videos, hasLength(2));
      expect(reloaded.videos.first.id, 'v1');
      expect(reloaded.videos.first.title, 'First video');
      expect(reloaded.videos.first.duration, testVideos.first.duration);
      expect(reloaded.videos.first.uploaded, '2 days ago');
      await reloaded.remove('v1', p);
      expect(reloaded.videos.single.id, 'v2');
      expect(store.contains('v1'), isTrue);
    });

    test('load tolerates junk', () async {
      expect((await WatchLaterStore.load(await prefs())).videos, isEmpty);
      expect(
        (await WatchLaterStore.load(await prefs({'watch_later': 'junk'})))
            .videos,
        isEmpty,
      );
      expect(
        (await WatchLaterStore.load(await prefs({'watch_later': '{}'}))).videos,
        isEmpty,
      );
      expect(
        (await WatchLaterStore.load(
          await prefs({'watch_later': '[{"bad": true}, {"id": "ok"}]'}),
        )).videos.single.id,
        'ok',
      );
    });
  });

  group('playlist page', () {
    testWidgets('shows entries and opens a video with playlist context', (
      tester,
    ) async {
      final player = FakePlayerController();
      final api = FakeYouTubeApi(
        playlistInfo: const PlaylistInfo(
          id: 'pl1',
          title: 'Weekend mix',
          author: 'Channel One',
          videoCount: 2,
          videos: testVideos,
        ),
      );
      final state = await testState(api: api, player: player);
      await pumpPage(
        tester,
        state,
        const PlaylistPage(playlistId: 'pl1', summary: null),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weekend mix'), findsWidgets);
      expect(find.text('Channel One · 2 videos'), findsOneWidget);
      expect(find.text('First video'), findsWidgets);

      await tester.tap(find.text('Second video'));
      await tester.pumpAndSettle();
      expect(find.byType(WatchPage), findsOneWidget);
      expect(player.opened, isNotEmpty);
    });

    testWidgets('shows an error state and retries', (tester) async {
      final api = FakeYouTubeApi()..error = 'nope';
      final state = await testState(api: api);
      await pumpPage(tester, state, PlaylistPage(playlistId: 'pl1'));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);

      api.error = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Test playlist'), findsWidgets);
    });
  });

  group('watch page playlist context', () {
    const playlist = PlaylistInfo(
      id: 'pl1',
      title: 'Mix',
      videoCount: 2,
      videos: testVideos,
    );

    testWidgets('auto-advances to the next video on completion', (
      tester,
    ) async {
      final player = FakePlayerController();
      final state = await testState(player: player);
      await pumpPage(
        tester,
        state,
        WatchPage(video: testVideos[0], playlist: playlist, index: 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mix · 1/2'), findsOneWidget);
      player.emitCompleted();
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      expect(find.text('Mix · 2/2'), findsOneWidget);
      expect(find.text('Second video'), findsWidgets);
    });

    testWidgets('tapping a playlist entry switches to it', (tester) async {
      final state = await testState(player: FakePlayerController());
      await pumpPage(
        tester,
        state,
        WatchPage(video: testVideos[0], playlist: playlist, index: 0),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Second video'));
      await tester.tap(find.text('Second video'));
      await tester.pumpAndSettle();
      expect(find.text('Mix · 2/2'), findsOneWidget);
    });

    testWidgets('advances while fullscreen is open', (tester) async {
      final player = FakePlayerController();
      final state = await testState(player: player);
      await pumpPage(
        tester,
        state,
        WatchPage(video: testVideos[0], playlist: playlist, index: 0),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pumpAndSettle();
      player.emitCompleted();
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      expect(find.text('Mix · 2/2'), findsOneWidget);
    });

    testWidgets('stays put at the end of a playlist', (tester) async {
      final player = FakePlayerController();
      final state = await testState(player: player);
      await pumpPage(
        tester,
        state,
        WatchPage(video: testVideos[1], playlist: playlist, index: 1),
      );
      await tester.pumpAndSettle();
      player.emitCompleted();
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      expect(find.text('Mix · 2/2'), findsOneWidget);
    });

    testWidgets('watch later bookmark toggles', (tester) async {
      final watchLater = WatchLaterStore();
      final state = await testState(
        player: FakePlayerController(),
        watchLater: watchLater,
      );
      await pumpPage(tester, state, WatchPage(video: testVideos.first));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pump();
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(watchLater.contains('v1'), isTrue);
      await tester.tap(find.byIcon(Icons.bookmark));
      await tester.pump();
      expect(watchLater.contains('v1'), isFalse);
    });
  });

  group('watch later page', () {
    testWidgets('shows the saved queue and an empty state', (tester) async {
      final watchLater = WatchLaterStore();
      final state = await testState(watchLater: watchLater);
      await pumpPage(tester, state, WatchLaterPage());
      await tester.pumpAndSettle();
      expect(find.text('Nothing saved for later'), findsOneWidget);

      await watchLater.toggle(testVideos.first, state.prefs);
      await tester.pumpAndSettle();
      expect(find.text('First video'), findsOneWidget);

      await tester.tap(find.text('First video'));
      await tester.pumpAndSettle();
      expect(find.byType(WatchPage), findsOneWidget);
    });
  });

  group('search page playlists', () {
    testWidgets('shows a playlists row and opens the playlist', (tester) async {
      final api = FakeYouTubeApi(
        searchResults: const SearchResults(
          videos: testVideos,
          playlists: [
            PlaylistInfo(
              id: 'pl1',
              title: 'Big mix',
              videoCount: 5,
              thumbnailUrl: 'https://i/pl.jpg',
            ),
          ],
        ),
      );
      final state = await testState(api: api);
      await pumpPage(tester, state, SearchPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'mix');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Big mix'), findsOneWidget);
      expect(find.text('5 videos'), findsOneWidget);
      await tester.tap(find.text('Big mix'));
      await tester.pumpAndSettle();
      expect(find.byType(PlaylistPage), findsOneWidget);
    });
  });
}
