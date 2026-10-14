import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/state/app_state.dart';
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
  Future<void> pumpPlayer(WidgetTester tester, FakePlayerController player) {
    return testState().then(
      (state) => tester.pumpWidget(
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
      ),
    );
  }

  testWidgets('wide layout shows a mute button and inline volume slider', (
    tester,
  ) async {
    final player = FakePlayerController()..volume = 0.6;
    await pumpPlayer(tester, player);

    expect(find.byIcon(Icons.volume_up), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(2));
  });

  testWidgets('volume slider drives the player volume', (tester) async {
    final player = FakePlayerController()..volume = 0.5;
    await pumpPlayer(tester, player);

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('volumeSlider')),
    );
    slider.onChanged!(0.9);
    expect(player.volume, 0.9);
    expect(player.muted, isFalse);
  });

  testWidgets('mute button toggles muted and swaps the icon', (tester) async {
    final player = FakePlayerController()
      ..volume = 0.6
      ..muted = false;
    await pumpPlayer(tester, player);

    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pump();
    expect(player.muted, isTrue);
    expect(find.byIcon(Icons.volume_off), findsOneWidget);

    await tester.tap(find.byIcon(Icons.volume_off));
    await tester.pump();
    expect(player.muted, isFalse);
  });

  testWidgets('muted volume shows the slider at zero', (tester) async {
    final player = FakePlayerController()
      ..volume = 0.6
      ..muted = true;
    await pumpPlayer(tester, player);

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('volumeSlider')),
    );
    expect(slider.value, 0.0);
  });

  testWidgets('narrow layout opens a popup volume slider', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final player = FakePlayerController()..volume = 0.5;
    await pumpPlayer(tester, player);

    expect(find.byKey(const ValueKey('volumeSlider')), findsNothing);
    expect(find.byIcon(Icons.volume_up), findsOneWidget);

    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pump();
    expect(find.byKey(const ValueKey('volumeSlider')), findsOneWidget);

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('volumeSlider')),
    );
    slider.onChanged!(0.2);
    expect(player.volume, 0.2);

    await tester.tap(find.byIcon(Icons.volume_up).last);
    await tester.pump();
    expect(find.byKey(const ValueKey('volumeSlider')), findsNothing);
  });

  testWidgets('volume icon reflects low volume', (tester) async {
    final player = FakePlayerController()..volume = 0.2;
    await pumpPlayer(tester, player);
    expect(find.byIcon(Icons.volume_down), findsOneWidget);
  });
}
