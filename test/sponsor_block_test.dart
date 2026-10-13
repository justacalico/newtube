import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/services/sponsor_block.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/pages/watch_page.dart';

import 'fakes.dart';

void main() {
  group('SponsorBlockClient', () {
    test('parses segments from the API response', () async {
      Uri? seen;
      final client = SponsorBlockClient(
        client: MockClient((request) async {
          seen = request.url;
          return http.Response(
            jsonEncode([
              {
                'category': 'sponsor',
                'segment': [10.0, 25.5],
              },
              {
                'category': 'selfpromo',
                'segment': [60, 90],
              },
              {'category': 'broken'},
            ]),
            200,
          );
        }),
      );
      final segments = await client.segments('abc', {'sponsor', 'selfpromo'});
      expect(segments, hasLength(2));
      expect(segments.first.category, 'sponsor');
      expect(segments.first.start, const Duration(seconds: 10));
      expect(
        segments.first.end,
        const Duration(seconds: 25, milliseconds: 500),
      );
      expect(seen!.queryParameters['videoID'], 'abc');
      expect(seen!.queryParameters['categories'], contains('sponsor'));
    });

    test('returns empty when the video is not in the database', () async {
      final client = SponsorBlockClient(
        client: MockClient((_) async => http.Response('Not found', 404)),
      );
      expect(await client.segments('x', {'sponsor'}), isEmpty);
    });

    test('throws on server errors', () async {
      final client = SponsorBlockClient(
        client: MockClient((_) async => http.Response('oops', 500)),
      );
      try {
        await client.segments('x', {'sponsor'});
        fail('should have thrown');
      } on SponsorBlockException catch (e) {
        expect(e.toString(), contains('500'));
      }
    });

    test('returns empty on a non-list body', () async {
      final client = SponsorBlockClient(
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      expect(await client.segments('x', {'sponsor'}), isEmpty);
    });
  });

  group('SegmentSkipper', () {
    const segments = [
      SponsorSegment(
        category: 'sponsor',
        start: Duration(seconds: 10),
        end: Duration(seconds: 20),
      ),
      SponsorSegment(
        category: 'intro',
        start: Duration(seconds: 40),
        end: Duration(seconds: 50),
      ),
    ];

    test('auto mode seeks past a segment', () async {
      final player = FakePlayerController();
      final skipper = SegmentSkipper(player: player, segments: segments);
      addTearDown(skipper.dispose);

      player.emitPosition(const Duration(seconds: 12));
      await Future<void>.delayed(Duration.zero);
      expect(player.lastSeek, const Duration(seconds: 20));
      expect(skipper.active, isNull);
    });

    test('auto mode does not re-skip after rewinding into a segment', () async {
      final player = FakePlayerController();
      final skipper = SegmentSkipper(player: player, segments: segments);
      addTearDown(skipper.dispose);

      player.emitPosition(const Duration(seconds: 12));
      await Future<void>.delayed(Duration.zero);
      player.emitPosition(const Duration(seconds: 11));
      await Future<void>.delayed(Duration.zero);
      expect(player.seeks, [const Duration(seconds: 20)]);
    });

    test(
      'manual mode exposes the active segment and skips on demand',
      () async {
        final player = FakePlayerController();
        final skipper = SegmentSkipper(
          player: player,
          segments: segments,
          autoSkip: false,
        );
        addTearDown(skipper.dispose);

        player.emitPosition(const Duration(seconds: 12));
        await Future<void>.delayed(Duration.zero);
        expect(skipper.active?.category, 'sponsor');
        expect(player.seeks, isEmpty);

        skipper.skip();
        expect(player.lastSeek, const Duration(seconds: 20));
        expect(skipper.active, isNull);

        player.emitPosition(const Duration(seconds: 30));
        await Future<void>.delayed(Duration.zero);
        expect(skipper.active, isNull);
      },
    );

    test('leaving the segment clears the active state', () async {
      final player = FakePlayerController();
      final skipper = SegmentSkipper(
        player: player,
        segments: segments,
        autoSkip: false,
      );
      addTearDown(skipper.dispose);

      player.emitPosition(const Duration(seconds: 12));
      await Future<void>.delayed(Duration.zero);
      expect(skipper.active, isNotNull);
      player.emitPosition(const Duration(seconds: 30));
      await Future<void>.delayed(Duration.zero);
      expect(skipper.active, isNull);
    });
  });

  testWidgets('watch page auto-skips sponsor segments', (tester) async {
    final player = FakePlayerController();
    final client = SponsorBlockClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'category': 'sponsor',
              'segment': [10, 20],
            },
          ]),
          200,
        ),
      ),
    );
    final state = await testState(
      player: player,
      sponsorBlock: client,
      settings: SettingsStore(sponsorBlockEnabled: true),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    player.position = const Duration(seconds: 12);
    player.emitPosition(const Duration(seconds: 12));
    await tester.pump();
    await tester.pump();

    expect(player.lastSeek, const Duration(seconds: 20));
  });

  testWidgets('watch page shows a skip button in manual mode', (tester) async {
    final player = FakePlayerController();
    final client = SponsorBlockClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'category': 'sponsor',
              'segment': [10, 20],
            },
          ]),
          200,
        ),
      ),
    );
    final state = await testState(
      player: player,
      sponsorBlock: client,
      settings: SettingsStore(
        sponsorBlockEnabled: true,
        sponsorBlockAutoSkip: false,
      ),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    expect(find.text('Skip'), findsNothing);
    player.position = const Duration(seconds: 12);
    player.emitPosition(const Duration(seconds: 12));
    await tester.pump();
    await tester.pump();
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(player.lastSeek, const Duration(seconds: 20));
  });

  testWidgets('a failing fetch still plays the video', (tester) async {
    final player = FakePlayerController();
    final client = SponsorBlockClient(
      client: MockClient((_) async => http.Response('oops', 500)),
    );
    final state = await testState(
      player: player,
      sponsorBlock: client,
      settings: SettingsStore(sponsorBlockEnabled: true),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.opened, isNotEmpty);
  });

  testWidgets('watch page skips the fetch when sponsorblock is off', (
    tester,
  ) async {
    final player = FakePlayerController();
    var calls = 0;
    final client = SponsorBlockClient(
      client: MockClient((_) async {
        calls++;
        return http.Response('[]', 200);
      }),
    );
    final state = await testState(player: player, sponsorBlock: client);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(calls, 0);
  });
}
