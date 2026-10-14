import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/state/app_state.dart';
import 'package:newtube/ui/widgets/player_view.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
  testWidgets('video fit menu cycles the player fit mode', (tester) async {
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
    expect(player.videoFit.value, BoxFit.contain);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Video fit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zoom to fill'));
    await tester.pumpAndSettle();
    expect(player.videoFit.value, BoxFit.cover);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Video fit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stretch'));
    await tester.pumpAndSettle();
    expect(player.videoFit.value, BoxFit.fill);
  });
}
