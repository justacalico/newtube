import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/sleep_timer.dart';
import 'package:newtube/state/app_state.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:newtube/ui/widgets/player_view.dart';

import 'fakes.dart';

Future<void> _openSettings(WidgetTester tester, String entry) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(entry));
  await tester.pumpAndSettle();
}

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
  double controlsOpacity(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(PlayerView),
          matching: find.byType(AnimatedOpacity),
        ),
      )
      .opacity;

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
          onAudioSelected: (_) {},
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
          onAudioSelected: (_) {},
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
          onAudioSelected: (_) {},
          onToggleFullscreen: () {},
        ),
      ),
    );
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);
  });

  testWidgets('touch tap toggles the controls without pausing', (tester) async {
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
          onAudioSelected: (_) {},
          onToggleFullscreen: () {},
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(controlsOpacity(tester), 0.0);

    await tester.tapAt(tester.getCenter(find.byType(PlayerView)));
    await tester.pump();
    expect(player.paused, isFalse);
    expect(controlsOpacity(tester), 1.0);

    await tester.tapAt(tester.getCenter(find.byType(PlayerView)));
    await tester.pump();
    expect(player.paused, isFalse);
    expect(controlsOpacity(tester), 0.0);
  });

  testWidgets('mouse click toggles playback', (tester) async {
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
          onAudioSelected: (_) {},
          onToggleFullscreen: () {},
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(find.byType(PlayerView)),
      kind: PointerDeviceKind.mouse,
    );
    expect(player.paused, isTrue);

    player.playing = false;
    await tester.tapAt(
      tester.getCenter(find.byType(PlayerView)),
      kind: PointerDeviceKind.mouse,
    );
    expect(player.played, isTrue);
  });

  testWidgets('quality menu lists video streams and selects', (tester) async {
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
          onAudioSelected: (_) {},
          onToggleFullscreen: () {},
        ),
      ),
    );

    await _openSettings(tester, 'Quality');
    expect(find.text('720p'), findsOneWidget);
    expect(find.text('360p'), findsOneWidget);
    expect(find.text('audio 128kbps'), findsNothing);

    await tester.tap(find.text('720p'));
    await tester.pumpAndSettle();
    expect(selected, testStreams[0]);
  });

  testWidgets('audio menu lists track names and selects', (tester) async {
    final player = FakePlayerController();
    final state = await testState();
    const streams = [
      ...testStreams,
      PlayableStream(
        url: 'https://audio.example.com/en',
        quality: 'audio 128kbps',
        hasVideo: false,
        audioLanguage: 'en',
        audioTrackName: 'English original',
      ),
      PlayableStream(
        url: 'https://audio.example.com/es',
        quality: 'audio 128kbps',
        hasVideo: false,
        audioLanguage: 'es',
        isDefaultAudio: false,
      ),
    ];
    PlayableStream? audio;
    await tester.pumpWidget(
      _wrap(
        state,
        PlayerView(
          player: player,
          streams: streams,
          current: testStreams[1],
          currentAudio: streams[4],
          onQualitySelected: (_) {},
          onAudioSelected: (s) => audio = s,
          onToggleFullscreen: () {},
        ),
      ),
    );

    await _openSettings(tester, 'Audio');
    expect(find.text('audio 128kbps'), findsOneWidget);
    expect(find.text('English original'), findsOneWidget);
    expect(find.text('es'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('English original'));
    await tester.pumpAndSettle();
    expect(audio, streams[3]);
  });

  testWidgets('arrow keys skip five seconds', (tester) async {
    final player = FakePlayerController()
      ..duration = const Duration(minutes: 2)
      ..position = const Duration(seconds: 30);
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

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(player.lastSeek, const Duration(seconds: 35));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(player.lastSeek, const Duration(seconds: 25));
  });

  testWidgets('arrow key seeks clamp to the video bounds', (tester) async {
    final player = FakePlayerController()
      ..duration = const Duration(minutes: 2)
      ..position = const Duration(seconds: 2);
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

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(player.lastSeek, Duration.zero);

    player.position = const Duration(seconds: 119);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(player.lastSeek, const Duration(minutes: 2));

    player.duration = Duration.zero;
    player.position = Duration.zero;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(player.lastSeek, const Duration(seconds: 5));
  });

  testWidgets('space toggles playback', (tester) async {
    final player = FakePlayerController();
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

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(player.played, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(player.paused, isTrue);
  });

  testWidgets('speed menu sets the playback rate', (tester) async {
    final player = FakePlayerController();
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

    await _openSettings(tester, 'Playback speed');
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('1.5x'), findsOneWidget);

    await tester.tap(find.text('1.5x'));
    await tester.pumpAndSettle();
    expect(player.rate, 1.5);

    await _openSettings(tester, 'Playback speed');
    expect(find.text('Normal'), findsOneWidget);
  });

  testWidgets('J and L skip ten seconds', (tester) async {
    final player = FakePlayerController()
      ..duration = const Duration(minutes: 2)
      ..position = const Duration(seconds: 30);
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

    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    expect(player.lastSeek, const Duration(seconds: 20));

    player.position = const Duration(seconds: 20);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    expect(player.lastSeek, const Duration(seconds: 30));
  });

  testWidgets('K toggles playback and M toggles mute', (tester) async {
    final player = FakePlayerController();
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

    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    expect(player.played, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    expect(player.muted, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    expect(player.muted, isFalse);
  });

  testWidgets('arrow keys adjust the volume', (tester) async {
    final player = FakePlayerController()..volume = 0.5;
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

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(player.volume, closeTo(0.55, 0.001));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(player.volume, closeTo(0.5, 0.001));

    player.volume = 0.02;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(player.volume, 0.0);
    player.volume = 0.99;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(player.volume, 1.0);
  });

  testWidgets('F toggles fullscreen', (tester) async {
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
          onAudioSelected: (_) {},
          onToggleFullscreen: () => toggled = true,
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    expect(toggled, isTrue);
  });

  testWidgets('comma and period step the playback rate', (tester) async {
    final player = FakePlayerController();
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

    await tester.sendKeyEvent(LogicalKeyboardKey.period);
    expect(player.rate, 1.25);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    expect(player.rate, 1.0);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    expect(player.rate, 0.75);

    for (var i = 0; i < 10; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    }
    expect(player.rate, 0.25);
    for (var i = 0; i < 10; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.period);
    }
    expect(player.rate, 2.0);
  });

  testWidgets('sleep timer menu starts and cancels the timer', (tester) async {
    final player = FakePlayerController();
    final sleepTimer = SleepTimer(player);
    addTearDown(sleepTimer.dispose);
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
          sleepTimer: sleepTimer,
        ),
      ),
    );

    await _openSettings(tester, 'Sleep timer');
    expect(find.text('15 minutes'), findsOneWidget);
    expect(find.text('End of video'), findsOneWidget);
    expect(find.text('Off'), findsNothing);

    await tester.tap(find.text('15 minutes'));
    await tester.pumpAndSettle();
    expect(sleepTimer.active, isTrue);
    expect(find.text('15:00'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('14:59'), findsOneWidget);

    await _openSettings(tester, 'Sleep timer');
    await tester.tap(find.text('End of video'));
    await tester.pumpAndSettle();
    expect(sleepTimer.endOfVideo, isTrue);
    expect(find.text('15:00'), findsNothing);

    await _openSettings(tester, 'Sleep timer');
    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();
    expect(sleepTimer.active, isFalse);
  });

  testWidgets('chapters label follows the position', (tester) async {
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
          onAudioSelected: (_) {},
          onToggleFullscreen: () {},
          chapters: const [
            VideoChapter(start: Duration.zero, title: 'Intro'),
            VideoChapter(start: Duration(minutes: 1), title: 'Main part'),
          ],
        ),
      ),
    );

    expect(find.text('Intro'), findsOneWidget);

    player.emitPosition(const Duration(seconds: 75));
    await tester.pump();
    expect(find.text('Main part'), findsOneWidget);
    expect(find.text('Intro'), findsNothing);
  });

  testWidgets('controls auto-hide while playing and reappear on tap', (
    tester,
  ) async {
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
          onAudioSelected: (_) {},
          onToggleFullscreen: () {},
        ),
      ),
    );

    expect(controlsOpacity(tester), 1.0);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(controlsOpacity(tester), 0.0);

    await tester.tapAt(tester.getCenter(find.byType(PlayerView)));
    await tester.pump();
    expect(player.paused, isFalse);
    expect(controlsOpacity(tester), 1.0);
  });

  testWidgets('controls stay visible while paused', (tester) async {
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
          onAudioSelected: (_) {},
          onToggleFullscreen: () {},
        ),
      ),
    );

    player.playing = false;
    player.emitPlaying(false);
    await tester.pump(const Duration(seconds: 4));
    expect(controlsOpacity(tester), 1.0);
  });

  testWidgets('controls hide on resume and reappear when paused', (
    tester,
  ) async {
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
          onAudioSelected: (_) {},
          onToggleFullscreen: () {},
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(controlsOpacity(tester), 0.0);

    player.playing = false;
    player.emitPlaying(false);
    await tester.pump();
    expect(controlsOpacity(tester), 1.0);

    player.playing = true;
    player.emitPlaying(true);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(controlsOpacity(tester), 0.0);
  });

  testWidgets('mouse hover wakes the controls and leaving hides them', (
    tester,
  ) async {
    final player = FakePlayerController()..playing = true;
    final state = await testState();
    await tester.pumpWidget(
      _wrap(
        state,
        Center(
          child: SizedBox(
            width: 400,
            height: 225,
            child: PlayerView(
              player: player,
              streams: testStreams,
              current: testStreams[1],
              onQualitySelected: (_) {},
              onAudioSelected: (_) {},
              onToggleFullscreen: () {},
            ),
          ),
        ),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.byType(PlayerView)));
    await tester.pump();
    expect(controlsOpacity(tester), 1.0);

    await mouse.moveTo(const Offset(10, 10));
    await tester.pump();
    expect(controlsOpacity(tester), 0.0);

    await mouse.moveTo(tester.getCenter(find.byType(PlayerView)));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(controlsOpacity(tester), 0.0);

    await mouse.moveTo(const Offset(10, 10));
    await tester.pump();
    expect(controlsOpacity(tester), 0.0);
  });

  testWidgets('swapping the player resubscribes to play state', (tester) async {
    final first = FakePlayerController()..playing = true;
    final second = FakePlayerController()..playing = true;
    final state = await testState();
    Widget host(FakePlayerController p) => _wrap(
      state,
      PlayerView(
        player: p,
        streams: testStreams,
        current: testStreams[1],
        onQualitySelected: (_) {},
        onAudioSelected: (_) {},
        onToggleFullscreen: () {},
      ),
    );

    await tester.pumpWidget(host(first));
    await tester.pumpWidget(host(first));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(controlsOpacity(tester), 0.0);

    await tester.pumpWidget(host(second));
    first.emitPlaying(false);
    await tester.pump();
    expect(controlsOpacity(tester), 0.0);

    second.playing = false;
    second.emitPlaying(false);
    await tester.pump();
    expect(controlsOpacity(tester), 1.0);
  });
}
