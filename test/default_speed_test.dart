import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/state/app_state.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:newtube/ui/widgets/player_view.dart';

import 'fakes.dart';

void main() {
  test('default speed persists through the settings store', () async {
    final state = await testState();
    expect(state.settings.defaultSpeed, 1.0);
    await state.settings.setDefaultSpeed(1.5, state.prefs);
    expect(state.settings.defaultSpeed, 1.5);

    final reloaded = await SettingsStore.load(state.prefs);
    expect(reloaded.defaultSpeed, 1.5);
  });

  testWidgets('watch page opens at the default speed', (tester) async {
    final player = FakePlayerController();
    final state = await testState(
      player: player,
      settings: SettingsStore(defaultSpeed: 1.75),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.rate, 1.75);
  });

  testWidgets('last session rate wins over the default', (tester) async {
    final player = FakePlayerController();
    final state = await testState(
      player: player,
      settings: SettingsStore(defaultSpeed: 0.5),
    );
    state.playback.lastRate = 1.5;
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.rate, 1.5);
  });

  testWidgets('choosing a speed in the player records it on the session', (
    tester,
  ) async {
    final player = FakePlayerController();
    final state = await testState();
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: PlayerView(
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

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Playback speed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1.5x'));
    await tester.pumpAndSettle();
    expect(player.rate, 1.5);
    expect(state.playback.lastRate, 1.5);
  });

  testWidgets('settings page stores the default speed', (tester) async {
    final state = await testState();
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Normal'),
      200,
      scrollable: find
          .descendant(
            of: find
                .byWidgetPredicate(
                  (w) => w is ListView && w.scrollDirection == Axis.vertical,
                )
                .first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text('Normal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Normal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1.25x'));
    await tester.pumpAndSettle();
    expect(state.settings.defaultSpeed, 1.25);
  });
}
