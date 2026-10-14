import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/innertube.dart';
import 'package:newtube/ui/pages/home_page.dart';
import 'package:newtube/ui/pages/search_page.dart';
import 'package:newtube/ui/widgets/video_card.dart';

import 'fakes.dart';

void main() {
  group('shorts detection', () {
    test('videoRenderer with reelWatchEndpoint is a short', () {
      final videos = <VideoInfo>[];
      collectVideos({
        'videoRenderer': {
          'videoId': 's1',
          'title': {
            'runs': [
              {'text': 'a short'},
            ],
          },
          'navigationEndpoint': {
            'reelWatchEndpoint': {'videoId': 's1'},
          },
        },
      }, videos);
      expect(videos.single.isShort, isTrue);
    });

    test('shortsLockupViewModel is parsed as a short', () {
      final videos = <VideoInfo>[];
      collectVideos({
        'shortsLockupViewModel': {
          'entityId': 'shorts-shelf-item-abcdefghijk-1',
          'thumbnail': {
            'sources': [
              {'url': 'https://i/small.jpg'},
              {'url': 'https://i/big.jpg'},
            ],
          },
          'overlayMetadata': {
            'primaryText': {'content': 'short title'},
            'secondaryText': {'content': '1.2M views'},
          },
        },
      }, videos);
      expect(videos.single.isShort, isTrue);
      expect(videos.single.id, 'abcdefghijk');
      expect(videos.single.title, 'short title');
    });

    test('nested reelWatchEndpoint is detected', () {
      final videos = <VideoInfo>[];
      collectVideos({
        'videoRenderer': {
          'videoId': 's2',
          'title': {
            'runs': [
              {'text': 'deep short'},
            ],
          },
          'navigationEndpoint': {
            'commandMetadata': {
              'children': [
                {
                  'reelWatchEndpoint': {'videoId': 's2'},
                },
              ],
            },
          },
        },
      }, videos);
      expect(videos.single.isShort, isTrue);
    });

    test('shortsLockup falls back to the reel endpoint id', () {
      final videos = <VideoInfo>[];
      collectVideos({
        'shortsLockupViewModel': {
          'entityId': 'no-match',
          'thumbnail': {
            'sources': [
              {'url': 'https://i/s.jpg'},
            ],
          },
          'menu': {
            'onTap': {
              'reelWatchEndpoint': {'videoId': 'zzzzzzzzzzz'},
            },
          },
        },
      }, videos);
      expect(videos.single.id, 'zzzzzzzzzzz');
      expect(videos.single.isShort, isTrue);
    });

    test('shortsLockup without an id is skipped', () {
      final videos = <VideoInfo>[];
      collectVideos({
        'shortsLockupViewModel': {'entityId': 'nothing'},
      }, videos);
      expect(videos, isEmpty);
    });

    test('ordinary videos are not shorts', () {
      final videos = <VideoInfo>[];
      collectVideos({
        'videoRenderer': {
          'videoId': 'v1',
          'title': {
            'runs': [
              {'text': 'normal'},
            ],
          },
          'navigationEndpoint': {
            'watchEndpoint': {'videoId': 'v1'},
          },
        },
      }, videos);
      expect(videos.single.isShort, isFalse);
    });
  });

  test('hideShorts persists', () async {
    final state = await testState(initialPrefs: {'hide_shorts': true});
    expect(state.settings.hideShorts, isTrue);
    await state.settings.setHideShorts(false, state.prefs);
    expect(state.settings.hideShorts, isFalse);
    expect(state.prefs.getBool('hide_shorts'), isFalse);
    await state.settings.setHideShorts(true, state.prefs);
    expect(state.prefs.getBool('hide_shorts'), isTrue);
  });

  testWidgets('hideShorts filters the home feed', (tester) async {
    final api = FakeYouTubeApi(
      feed: [
        const VideoInfo(id: 'n1', title: 'Normal', author: 'a', channelId: 'c'),
        const VideoInfo(
          id: 's1',
          title: 'A short',
          author: 'a',
          channelId: 'c',
          isShort: true,
        ),
      ],
    );
    final state = await testState(
      api: api,
      initialPrefs: {'hide_shorts': true},
    );
    await pumpPage(tester, state, const HomePage());
    await tester.pumpAndSettle();
    expect(find.text('Normal'), findsWidgets);
    expect(find.text('A short'), findsNothing);
  });

  testWidgets('hideShorts filters search results', (tester) async {
    final api = FakeYouTubeApi(
      searchResults: SearchResults(
        videos: [
          const VideoInfo(
            id: 'n1',
            title: 'Normal result',
            author: 'a',
            channelId: 'c',
          ),
          const VideoInfo(
            id: 's1',
            title: 'Short result',
            author: 'a',
            channelId: 'c',
            isShort: true,
          ),
        ],
      ),
    );
    final state = await testState(
      api: api,
      initialPrefs: {'hide_shorts': true},
    );
    await pumpPage(tester, state, const SearchPage());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'x');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Normal result'), findsWidgets);
    expect(find.text('Short result'), findsNothing);
  });

  testWidgets('shorts show a badge on thumbnails', (tester) async {
    const video = VideoInfo(
      id: 's1',
      title: 'shorty',
      author: 'a',
      channelId: 'c',
      isShort: true,
    );
    final state = await testState(api: FakeYouTubeApi());
    await pumpPage(tester, state, VideoCard(video: video, onTap: () {}));
    expect(find.text('SHORTS'), findsOneWidget);
  });
}
