import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/innertube_api.dart';
import 'package:newtube/state/app_state.dart';
import 'package:newtube/ui/widgets/player_view.dart';
import 'package:newtube/utils/storyboard.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'fakes.dart';

const _spec =
    'https://i.example.com/sb/vid/storyboard3_L\$L/\$N.jpg'
    '|48#27#100#10#10#0#default#sigA'
    '|160#90#25#5#5#2000#M\$M#sigB'
    '|bad#data';

const _board = Storyboard(
  urlTemplate: 'https://i.example.com/sb/vid/storyboard3_L1/M\$M.jpg',
  sigh: 'sigB',
  tileWidth: 160,
  tileHeight: 90,
  tileCount: 60,
  cols: 5,
  rows: 5,
  interval: Duration(seconds: 2),
);

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
  test('parseStoryboardSpec parses levels and skips bad data', () {
    final boards = parseStoryboardSpec(_spec);
    expect(boards, hasLength(2));
    expect(boards[0].tileWidth, 48);
    expect(boards[0].sigh, 'sigA');
    expect(boards[1].tileWidth, 160);
    expect(boards[1].interval, const Duration(seconds: 2));
    expect(
      boards[1].urlTemplate,
      'https://i.example.com/sb/vid/storyboard3_L1/M\$M.jpg',
    );
    expect(boards[1].boardUrl(2), contains('M2.jpg?sigh=sigB'));
  });

  test('parseStoryboardSpec handles missing and zero-dimension parts', () {
    expect(parseStoryboardSpec('https://x/sb'), isEmpty);
    expect(
      parseStoryboardSpec('https://x/sb|160#0#25#5#5#2000#M\$M#s'),
      isEmpty,
    );
  });

  test('storyboardTileAt maps time to board and tile rect', () {
    final tile = storyboardTileAt(_board, const Duration(seconds: 12))!;
    expect(
      tile.url,
      'https://i.example.com/sb/vid/storyboard3_L1/M0.jpg?sigh=sigB',
    );
    expect(tile.sourceRect, const Rect.fromLTWH(160, 90, 160, 90));

    final next = storyboardTileAt(_board, const Duration(seconds: 50))!;
    expect(next.url, contains('M1.jpg'));
    expect(next.sourceRect, const Rect.fromLTWH(0, 0, 160, 90));

    final clamped = storyboardTileAt(_board, const Duration(minutes: 5))!;
    expect(clamped.url, contains('M2.jpg'));
  });

  test('storyboardTileAt returns null without an interval', () {
    const zero = Storyboard(
      urlTemplate: 'u',
      sigh: '',
      tileWidth: 10,
      tileHeight: 10,
      tileCount: 1,
      cols: 1,
      rows: 1,
      interval: Duration.zero,
    );
    expect(storyboardTileAt(zero, const Duration(seconds: 1)), isNull);
  });

  test('bestStoryboard picks the largest tile board', () {
    expect(bestStoryboard(const []), isNull);
    final boards = parseStoryboardSpec(_spec);
    expect(bestStoryboard(boards)!.tileWidth, 160);
  });

  test('innertube api parses storyboards', () async {
    final api = InnertubeApi(
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['videoId'], 'v');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'videoDetails': {'title': 'Vid', 'lengthSeconds': '60'},
              'storyboards': {
                'playerStoryboardSpecRenderer': {'spec': _spec},
              },
            }),
          ),
          200,
        );
      }),
    );
    final details = await api.videoDetails('v');
    expect(details.storyboards, hasLength(2));
  });

  testWidgets('seek bar shows the buffered range', (tester) async {
    final player = FakePlayerController()
      ..duration = const Duration(minutes: 3);
    final state = await testState();
    await tester.pumpWidget(
      _wrap(
        state,
        PlayerView(
          player: player,
          streams: testStreams,
          current: testStreams[1],
          onQualitySelected: (_) {},
          onAudioSelected: (_) {},
          onToggleFullscreen: () {},
        ),
      ),
    );
    var slider = tester.widget<Slider>(
      find.byKey(const ValueKey('seekSlider')),
    );
    expect(slider.secondaryTrackValue, 0.0);

    player.emitBuffered(const Duration(minutes: 1));
    await tester.pump();
    slider = tester.widget<Slider>(find.byKey(const ValueKey('seekSlider')));
    expect(slider.secondaryTrackValue, closeTo(1 / 3, 0.001));
  });

  testWidgets('hovering the seek bar shows a storyboard preview', (
    tester,
  ) async {
    final player = FakePlayerController()
      ..duration = const Duration(minutes: 3);
    final state = await testState();
    await tester.pumpWidget(
      _wrap(
        state,
        PlayerView(
          player: player,
          streams: testStreams,
          current: testStreams[1],
          onQualitySelected: (_) {},
          onAudioSelected: (_) {},
          onToggleFullscreen: () {},
          storyboard: _board,
        ),
      ),
    );

    final slider = find.byKey(const ValueKey('seekSlider'));
    final rect = tester.getRect(slider);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: rect.center);
    await gesture.moveTo(rect.center);
    await tester.pump();
    expect(find.text('1:30'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is NetworkImage),
      findsOneWidget,
    );

    await gesture.moveTo(const Offset(0, 0));
    await tester.pump();
    expect(find.text('1:30'), findsNothing);
  });

  testWidgets('scrubbing the seek bar shows a storyboard preview', (
    tester,
  ) async {
    final player = FakePlayerController()
      ..duration = const Duration(minutes: 3);
    final state = await testState();
    await tester.pumpWidget(
      _wrap(
        state,
        PlayerView(
          player: player,
          streams: testStreams,
          current: testStreams[1],
          onQualitySelected: (_) {},
          onAudioSelected: (_) {},
          onToggleFullscreen: () {},
          storyboard: _board,
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('seekSlider')),
      const Offset(40, 0),
    );
    await tester.pump();
    await tester.pump();
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is NetworkImage),
      findsOneWidget,
    );
  });
}
