import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/innertube_api.dart';
import 'package:newtube/state/app_state.dart';
import 'package:newtube/ui/widgets/player_view.dart';
import 'package:newtube/utils/heatmap.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'fakes.dart';

Map<String, dynamic> _heatResponse() => {
  'frameworkUpdates': {
    'entityBatchUpdate': {
      'mutations': [
        {
          'payload': {
            'markersEntity': {
              'markersMap': [
                {
                  'key': 'HEATSEEKER',
                  'value': {
                    'heatmap': {
                      'heatMarkers': [
                        {'timeRangeStartMillis': 0, 'heatScoreNormalized': 0.2},
                        {
                          'timeRangeStartMillis': 30000,
                          'heatScoreNormalized': 0.9,
                        },
                      ],
                      'heatMarkersDurationMillis': '60000',
                    },
                  },
                },
              ],
            },
          },
        },
      ],
    },
  },
};

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

InnertubeApi _api(Map<String, dynamic> Function(String endpoint) handler) {
  return InnertubeApi(
    httpClient: MockClient((request) async {
      if (request.method != 'POST') {
        return http.Response.bytes(const [], 206);
      }
      final endpoint = request.url.path.split('/').last.split('?').first;
      return http.Response.bytes(
        utf8.encode(jsonEncode(handler(endpoint))),
        200,
      );
    }),
  );
}

void main() {
  test('parseHeatMarkers reads heatMarkers from frameworkUpdates', () {
    final markers = parseHeatMarkers(_heatResponse());
    expect(markers, hasLength(2));
    expect(markers[0].start, Duration.zero);
    expect(markers[1].start, const Duration(seconds: 30));
    expect(markers[1].intensity, 0.9);
  });

  test('parseHeatMarkers tolerates missing data', () {
    expect(parseHeatMarkers(null), isEmpty);
    expect(parseHeatMarkers({}), isEmpty);
    expect(
      parseHeatMarkers({
        'frameworkUpdates': {
          'entityBatchUpdate': {
            'mutations': [
              {
                'payload': {'other': {}},
              },
            ],
          },
        },
      }),
      isEmpty,
    );
  });

  test('videoDetails parses heatmap from the player response', () async {
    final api = _api(
      (endpoint) => {
        'videoDetails': {'title': 'Vid', 'lengthSeconds': '60'},
        ..._heatResponse(),
      },
    );
    final details = await api.videoDetails('v');
    expect(details.heatmap, hasLength(2));
  });

  test('videoDetails without markers yields an empty heatmap', () async {
    final api = _api(
      (_) => {
        'videoDetails': {'title': 'Vid', 'lengthSeconds': '60'},
      },
    );
    final details = await api.videoDetails('v');
    expect(details.heatmap, isEmpty);
  });

  testWidgets('seek bar renders the heatmap painter', (tester) async {
    final player = FakePlayerController()
      ..duration = const Duration(minutes: 1);
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
          heatmap: const [
            HeatMarker(start: Duration.zero, intensity: 0.2),
            HeatMarker(start: Duration(seconds: 30), intensity: 0.9),
          ],
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is CustomPaint && w.painter.toString().contains('HeatMapPainter'),
      ),
      findsOneWidget,
    );

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
          heatmap: const [HeatMarker(start: Duration.zero, intensity: 0.5)],
        ),
      ),
    );
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is CustomPaint && w.painter.toString().contains('HeatMapPainter'),
      ),
      findsOneWidget,
    );
  });
}
