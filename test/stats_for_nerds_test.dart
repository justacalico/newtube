import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/models/video_info.dart';
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
  testWidgets('stats for nerds overlay shows stream details', (tester) async {
    const stream = PlayableStream(
      url: 'u1080',
      quality: '1080p',
      container: 'mp4',
      mimeType: 'video/mp4; codecs="avc1.640028"',
      bitrate: 2500000,
      width: 1920,
      height: 1080,
    );
    const audio = PlayableStream(
      url: 'a128',
      quality: 'audio 128kbps',
      hasVideo: false,
      bitrate: 128000,
    );
    final player = FakePlayerController()
      ..duration = const Duration(minutes: 3)
      ..rate = 1.5
      ..volume = 0.5;
    final state = await testState();
    await tester.pumpWidget(
      _wrap(
        state,
        PlayerView(
          player: player,
          streams: const [stream, audio],
          current: stream,
          currentAudio: audio,
          onQualitySelected: (_) {},
          onAudioSelected: (_) {},
          onToggleFullscreen: () {},
        ),
      ),
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stats for nerds'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1920x1080'), findsOneWidget);
    expect(find.textContaining('avc1.640028'), findsOneWidget);
    expect(find.textContaining('2500kbps'), findsOneWidget);
    expect(find.textContaining('audio 128kbps'), findsOneWidget);
    expect(find.textContaining('1.5x'), findsOneWidget);
    expect(find.textContaining('50%'), findsOneWidget);

    player.emitPosition(const Duration(seconds: 30));
    player.emitBuffered(const Duration(minutes: 1));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('0:30 / 3:00'), findsOneWidget);
    expect(find.textContaining('1:00 buffered'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stats for nerds'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1920x1080'), findsNothing);
  });
}
