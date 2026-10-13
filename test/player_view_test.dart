import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/app_state.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:newtube/ui/widgets/player_view.dart';

import 'fakes.dart';

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
  testWidgets('play and pause buttons drive the player', (tester) async {
    final player = FakePlayerController();
    final state = await testState();
    var toggled = false;
    await tester.pumpWidget(
      _wrap(
        state,
        PlayerView(
          player: player,
          streams: testStreams,
          current: testStreams[1],
          onQualitySelected: (_) {},
          onToggleFullscreen: () => toggled = true,
        ),
      ),
    );

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_arrow));
    expect(player.played, isTrue);

    player.emitPlaying(true);
    await tester.pump();
    expect(find.byIcon(Icons.pause), findsOneWidget);
    await tester.tap(find.byIcon(Icons.pause));
    expect(player.paused, isTrue);

    await tester.tap(find.byIcon(Icons.fullscreen));
    expect(toggled, isTrue);
  });

  testWidgets('slider seeks and buffering bar shows', (tester) async {
    final player = FakePlayerController()
      ..duration = const Duration(minutes: 2);
    final state = await testState();
    await tester.pumpWidget(
      _wrap(
        state,
        PlayerView(
          player: player,
          streams: testStreams,
          current: testStreams[1],
          onQualitySelected: (_) {},
          onToggleFullscreen: () {},
        ),
      ),
    );

    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('2:00'), findsOneWidget);

    player.emitPosition(const Duration(seconds: 30));
    await tester.pump();
    expect(find.text('0:30'), findsOneWidget);

    player.emitPosition(const Duration(minutes: 5));
    await tester.pump();
    expect(find.text('2:00'), findsWidgets);

    player.emitBuffering(true);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    player.emitBuffering(false);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.drag(find.byType(Slider), const Offset(50, 0));
    expect(player.lastSeek, isNotNull);
  });

  testWidgets('slider disabled with zero duration', (tester) async {
    final player = FakePlayerController()..duration = Duration.zero;
    final state = await testState();
    await tester.pumpWidget(
      _wrap(
        state,
        PlayerView(
          player: player,
          streams: const [],
          current: null,
          onQualitySelected: (_) {},
          onToggleFullscreen: () {},
        ),
      ),
    );
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);
  });

  testWidgets('tapping the video toggles playback', (tester) async {
    final player = FakePlayerController()..playing = true;
    final state = await testState();
    await tester.pumpWidget(
      _wrap(
        state,
        PlayerView(
          player: player,
          streams: testStreams,
          current: testStreams[1],
          onQualitySelected: (_) {},
          onToggleFullscreen: () {},
        ),
      ),
    );

    await tester.tapAt(tester.getCenter(find.byType(PlayerView)));
    expect(player.paused, isTrue);

    player.playing = false;
    await tester.tapAt(tester.getCenter(find.byType(PlayerView)));
    expect(player.played, isTrue);
  });

  testWidgets('quality menu lists streams and selects', (tester) async {
    final player = FakePlayerController();
    final state = await testState();
    PlayableStream? selected;
    await tester.pumpWidget(
      _wrap(
        state,
        PlayerView(
          player: player,
          streams: testStreams,
          current: testStreams[1],
          onQualitySelected: (s) => selected = s,
          onToggleFullscreen: () {},
        ),
      ),
    );

    await tester.tap(find.byTooltip('Quality'));
    await tester.pumpAndSettle();
    expect(find.text('720p'), findsOneWidget);
    expect(find.text('Audio only'), findsOneWidget);

    await tester.tap(find.text('Audio only'));
    await tester.pumpAndSettle();
    expect(selected, testStreams[2]);
  });
}
