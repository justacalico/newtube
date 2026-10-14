import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/innertube.dart';
import 'package:newtube/services/innertube_api.dart';
import 'package:newtube/state/app_state.dart';
import 'package:newtube/ui/widgets/player_view.dart';
import 'package:newtube/ui/widgets/video_card.dart';
import 'package:newtube/ui/widgets/video_list_tile.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'fakes.dart';

void _noop() {}

Widget _wrap(AppState state, Widget child) => AppScope(
  state: state,
  child: MaterialApp(
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  ),
);

void main() {
  test('videoDetails marks live and upcoming videos', () async {
    for (final live in [true, false]) {
      final api = InnertubeApi(
        httpClient: MockClient((request) async {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'videoDetails': {
                  'title': 'Vid',
                  'lengthSeconds': '0',
                  'isLive': live,
                  'isUpcoming': !live,
                },
              }),
            ),
            200,
          );
        }),
      );
      final details = await api.videoDetails('v');
      expect(details.info.isLive, live);
      expect(details.info.isUpcoming, !live);
    }
  });

  test('videoRenderer detects live and upcoming overlays', () {
    final live = parseVideoRenderer({
      'videoId': 'v',
      'thumbnailOverlays': [
        {
          'thumbnailOverlayTimeStatusRenderer': {'style': 'LIVE'},
        },
      ],
    })!;
    expect(live.isLive, isTrue);
    expect(live.isUpcoming, isFalse);

    final upcoming = parseVideoRenderer({
      'videoId': 'v',
      'badges': [
        {
          'metadataBadgeRenderer': {'style': 'BADGE_STYLE_TYPE_UPCOMING'},
        },
      ],
    })!;
    expect(upcoming.isUpcoming, isTrue);

    expect(parseVideoRenderer({'videoId': 'v'})!.isLive, isFalse);
  });

  testWidgets('live videos show a badge instead of the duration', (
    tester,
  ) async {
    final state = await testState();
    await tester.pumpWidget(
      _wrap(
        state,
        VideoCard(
          video: const VideoInfo(
            id: 'v',
            title: 'Live stream',
            author: 'Channel',
            channelId: 'c1',
            isLive: true,
          ),
          onTap: () {},
        ),
      ),
    );
    expect(find.text('Live'), findsOneWidget);
  });

  testWidgets('upcoming videos show an upcoming badge', (tester) async {
    final state = await testState();
    await tester.pumpWidget(
      _wrap(
        state,
        VideoCard(
          video: const VideoInfo(
            id: 'v',
            title: 'Premiere',
            author: 'Channel',
            channelId: 'c1',
            isUpcoming: true,
          ),
          onTap: () {},
        ),
      ),
    );
    expect(find.text('Upcoming'), findsOneWidget);
  });

  testWidgets('list tiles show live and upcoming badges', (tester) async {
    final state = await testState();
    await tester.pumpWidget(
      _wrap(
        state,
        const Column(
          children: [
            VideoListTile(
              video: VideoInfo(
                id: 'v1',
                title: 'Streaming now',
                author: 'a',
                channelId: 'c',
                isLive: true,
              ),
              onTap: _noop,
            ),
            VideoListTile(
              video: VideoInfo(
                id: 'v2',
                title: 'Coming soon',
                author: 'a',
                channelId: 'c',
                isUpcoming: true,
              ),
              onTap: _noop,
            ),
          ],
        ),
      ),
    );
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
  });

  testWidgets('live player hides the seek bar and end screen', (tester) async {
    final player = FakePlayerController();
    final state = await testState();
    var endBuilt = false;
    await tester.pumpWidget(
      _wrap(
        state,
        PlayerView(
          player: player,
          streams: const [],
          current: null,
          onQualitySelected: (_) {},
          onAudioSelected: (_) {},
          onToggleFullscreen: () {},
          live: true,
          endScreenBuilder: (_) {
            endBuilt = true;
            return const Text('end screen');
          },
        ),
      ),
    );
    expect(find.byKey(const ValueKey('seekSlider')), findsNothing);
    expect(find.text('Live'), findsOneWidget);

    player.emitCompleted();
    await tester.pump();
    expect(endBuilt, isFalse);
  });
}
