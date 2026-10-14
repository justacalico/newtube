import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/ui/widgets/player_view.dart';

import 'fakes.dart';

import 'package:newtube/state/app_state.dart';

late AppState _state;

Future<Widget> _wrapAsync({
  FakePlayerController? player,
  VoidCallback? onNext,
  VoidCallback? onPrevious,
  VoidCallback? onPip,
  List<CaptionTrack> captions = const [],
  ValueChanged<CaptionTrack?>? onCaption,
}) async {
  _state = await testState();
  CaptionTrack? selected;
  return AppScope(
    state: _state,
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 450,
          child: StatefulBuilder(
            builder: (context, setState) => PlayerView(
              player: player ?? FakePlayerController(),
              streams: testStreams,
              current: testStreams[0],
              onQualitySelected: (_) {},
              onAudioSelected: (_) {},
              onToggleFullscreen: () {},
              captions: captions,
              selectedCaption: selected,
              onCaptionSelected: (t) {
                setState(() => selected = t);
                onCaption?.call(t);
              },
              onNext: onNext,
              onPrevious: onPrevious,
              onPip: onPip,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('next / previous / pip shortcuts', (tester) async {
    var nexts = 0, prevs = 0, pips = 0;
    await tester.pumpWidget(
      await _wrapAsync(
        onNext: () => nexts++,
        onPrevious: () => prevs++,
        onPip: () => pips++,
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
    await tester.pump();
    expect(nexts, 1);
    expect(prevs, 1);
    expect(pips, 1);
  });

  testWidgets('digit keys seek by percent and home/end jump', (tester) async {
    final player = FakePlayerController()
      ..duration = const Duration(seconds: 100);
    await tester.pumpWidget(await _wrapAsync(player: player));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    expect(player.seeks.last, const Duration(seconds: 50));
    await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
    expect(player.seeks.last, Duration.zero);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    expect(player.seeks.last, const Duration(seconds: 100));
  });

  testWidgets('C cycles captions', (tester) async {
    const tracks = [
      CaptionTrack(url: 'a', languageCode: 'en', name: 'EN'),
      CaptionTrack(url: 'b', languageCode: 'fr', name: 'FR'),
    ];
    CaptionTrack? chosen;
    await tester.pumpWidget(
      await _wrapAsync(captions: tracks, onCaption: (t) => chosen = t),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.pump();
    expect(chosen?.url, 'a');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.pump();
    expect(chosen?.url, 'b');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.pump();
    expect(chosen, isNull);
  });

  testWidgets('shift+? opens the shortcuts sheet', (tester) async {
    await tester.pumpWidget(await _wrapAsync());
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pumpAndSettle();
    expect(find.text('Keyboard shortcuts'), findsOneWidget);
    expect(find.text('Space / K'), findsOneWidget);
  });
}
