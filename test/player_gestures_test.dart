import "dart:async";

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/services/brightness.dart';
import 'package:newtube/state/app_state.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:newtube/ui/widgets/player_view.dart';

import 'fakes.dart';

Widget _wrap(AppState state, Widget child) => AppScope(
  state: state,
  child: MaterialApp(
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  ),
);

void main() {
  Future<void> pumpPlayer(
    WidgetTester tester,
    FakePlayerController player, {
    AppState? state,
    BrightnessControl? brightness,
    bool isFullscreen = false,
    VoidCallback? onToggleFullscreen,
    VoidCallback? onDismiss,
  }) async {
    state ??= await testState(brightness: brightness);
    await tester.pumpWidget(
      _wrap(
        state,
        PlayerView(
          player: player,
          streams: testStreams,
          current: testStreams[1],
          onQualitySelected: (_) {},
          onAudioSelected: (_) {},
          onToggleFullscreen: onToggleFullscreen ?? () {},
          isFullscreen: isFullscreen,
          onDismiss: onDismiss,
        ),
      ),
    );
  }

  Rect playerRect(WidgetTester tester) =>
      tester.getRect(find.byType(PlayerView));

  Offset playerCenter(WidgetTester tester) => playerRect(tester).center;

  testWidgets('double tap right seeks forward 10s', (tester) async {
    final player = FakePlayerController()
      ..duration = const Duration(minutes: 2)
      ..position = const Duration(seconds: 30);
    await pumpPlayer(tester, player);
    final rect = playerRect(tester);
    final spot = Offset(rect.right - 20, rect.center.dy);

    await tester.tapAt(spot);
    await tester.tapAt(spot);
    await tester.pump();
    expect(player.lastSeek, const Duration(seconds: 40));
    expect(find.text('10s'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('10s'), findsNothing);
  });

  testWidgets('double tap left seeks back 10s', (tester) async {
    final player = FakePlayerController()
      ..duration = const Duration(minutes: 2)
      ..position = const Duration(seconds: 30);
    await pumpPlayer(tester, player);
    final rect = playerRect(tester);
    final spot = Offset(rect.left + 20, rect.center.dy);

    await tester.tapAt(spot);
    await tester.tapAt(spot);
    await tester.pump();
    expect(player.lastSeek, const Duration(seconds: 20));
  });

  testWidgets('single tap still toggles the controls', (tester) async {
    final player = FakePlayerController()..playing = true;
    await pumpPlayer(tester, player);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    await tester.tapAt(playerCenter(tester));
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.descendant(
              of: find.byType(PlayerView),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity,
      1.0,
    );
  });

  testWidgets('press and hold plays at 2x', (tester) async {
    final player = FakePlayerController()..rate = 1.0;
    await pumpPlayer(tester, player);
    final center = playerCenter(tester);

    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 600));
    expect(player.rate, 2.0);
    expect(find.text('2x'), findsOneWidget);

    await gesture.up();
    await tester.pump();
    expect(player.rate, 1.0);
    expect(find.text('2x'), findsNothing);
  });

  testWidgets('vertical drag on the right adjusts volume', (tester) async {
    final player = FakePlayerController()..volume = 0.5;
    await pumpPlayer(tester, player);

    final rect = playerRect(tester);
    final gesture = await tester.startGesture(
      Offset(rect.right - 10, rect.center.dy),
    );
    await gesture.moveBy(Offset(0, -rect.height * 0.1));
    await gesture.moveBy(Offset(0, -rect.height * 0.2));
    await tester.pump();
    expect(player.volume, greaterThan(0.5));
    expect(find.textContaining('%'), findsOneWidget);

    await gesture.up();
    await tester.pump();
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('vertical drag on the left adjusts brightness', (tester) async {
    final brightness = FakeBrightnessControl();
    final player = FakePlayerController();
    await pumpPlayer(tester, player, brightness: brightness);

    final rect = playerRect(tester);
    final gesture = await tester.startGesture(
      Offset(rect.left + 10, rect.center.dy),
    );
    await tester.pump();
    await gesture.moveBy(Offset(0, -rect.height * 0.1));
    await gesture.moveBy(Offset(0, -rect.height * 0.2));
    await tester.pump();
    expect(brightness.sets, isNotEmpty);
    expect(brightness.value, greaterThan(0.8));
    expect(find.byIcon(Icons.brightness_6), findsOneWidget);

    await gesture.up();
    await tester.pump();
    expect(find.byIcon(Icons.brightness_6), findsNothing);
  });

  testWidgets('left drag without brightness service shows no hud', (
    tester,
  ) async {
    final player = FakePlayerController()..volume = 0.5;
    await pumpPlayer(tester, player);

    final rect = playerRect(tester);
    final gesture = await tester.startGesture(
      Offset(rect.left + 10, rect.center.dy),
    );
    await tester.pump();
    await gesture.moveBy(Offset(0, -rect.height * 0.1));
    await gesture.moveBy(Offset(0, -rect.height * 0.2));
    await tester.pump();
    expect(find.textContaining('%'), findsNothing);
    await gesture.up();
  });

  testWidgets('swipe down in the middle dismisses the page', (tester) async {
    var dismissed = false;
    final player = FakePlayerController();
    await pumpPlayer(tester, player, onDismiss: () => dismissed = true);

    final center = playerCenter(tester);
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(0, 30));
    await gesture.moveBy(const Offset(0, 90));
    await gesture.up();
    await tester.pump();
    expect(dismissed, isTrue);
  });

  testWidgets('swipe down in fullscreen exits fullscreen', (tester) async {
    var exited = false;
    final player = FakePlayerController();
    await pumpPlayer(
      tester,
      player,
      isFullscreen: true,
      onToggleFullscreen: () => exited = true,
    );

    final center = playerCenter(tester);
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(0, 30));
    await gesture.moveBy(const Offset(0, 90));
    await gesture.up();
    await tester.pump();
    expect(exited, isTrue);
  });

  testWidgets('small middle drag does not dismiss', (tester) async {
    var dismissed = false;
    final player = FakePlayerController();
    await pumpPlayer(tester, player, onDismiss: () => dismissed = true);

    final center = playerCenter(tester);
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(0, 15));
    await gesture.moveBy(const Offset(0, 5));
    await gesture.up();
    await tester.pump();
    expect(dismissed, isFalse);
  });

  testWidgets('swipe down on the watch page pops to the mini player', (
    tester,
  ) async {
    final player = FakePlayerController();
    final state = await testState(player: player);
    await pumpPage(
      tester,
      state,
      Navigator(
        onGenerateRoute: (_) =>
            MaterialPageRoute<void>(builder: (_) => const SizedBox()),
      ),
    );

    unawaited(
      tester
          .state<NavigatorState>(find.byType(Navigator).last)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => WatchPage(video: testVideos.first),
            ),
          ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(WatchPage), findsOneWidget);

    final rect = tester.getRect(find.byType(PlayerView));
    final gesture = await tester.startGesture(rect.center);
    await gesture.moveBy(const Offset(0, 30));
    await gesture.moveBy(const Offset(0, 90));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.byType(WatchPage), findsNothing);
    expect(state.playback.minimized, isTrue);
  });
}
