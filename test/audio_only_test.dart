import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/app_state.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:newtube/ui/widgets/player_view.dart';

import 'fakes.dart';

void main() {
  test('audio only setting persists', () async {
    final state = await testState();
    expect(state.settings.audioOnly, isFalse);
    await state.settings.setAudioOnly(true, state.prefs);
    expect(state.settings.audioOnly, isTrue);
    expect(state.prefs.getBool('audio_only'), isTrue);

    final reloaded = await testState(initialPrefs: {'audio_only': true});
    expect(reloaded.settings.audioOnly, isTrue);
  });

  testWidgets('audio-only default opens the audio stream', (tester) async {
    final player = FakePlayerController();
    final state = await testState(
      player: player,
      settings: SettingsStore(audioOnly: true),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    expect(player.opened.single, 'https://audio.example.com/128');
    expect(state.playback.audioOnly, isFalse);
  });

  testWidgets('audio-only toggle switches streams and shows artwork', (
    tester,
  ) async {
    final player = FakePlayerController();
    final state = await testState(player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    expect(player.opened.single, 'https://video.example.com/360');

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audio only'));
    await tester.pumpAndSettle();

    expect(state.playback.audioOnly, isTrue);
    expect(player.opened.last, 'https://audio.example.com/128');
    expect(find.byType(Image), findsWidgets);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audio only'));
    await tester.pumpAndSettle();

    expect(state.playback.audioOnly, isFalse);
    expect(player.opened.last, 'https://video.example.com/360');
  });

  testWidgets('disabling audio-only on an audio-only video stays on audio', (
    tester,
  ) async {
    final api = FakeYouTubeApi(
      details: VideoDetails(
        info: testVideos.first,
        description: '',
        streams: [
          PlayableStream(
            url: 'https://audio.example.com/64',
            quality: 'audio 64kbps',
            hasVideo: false,
          ),
        ],
      ),
    );
    final player = FakePlayerController();
    final state = await testState(
      api: api,
      player: player,
      settings: SettingsStore(audioOnly: true),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.opened.single, 'https://audio.example.com/64');

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audio only'));
    await tester.pumpAndSettle();

    expect(state.playback.audioOnly, isFalse);
    expect(player.opened.last, 'https://audio.example.com/64');
    expect(player.opened, hasLength(2));
  });

  testWidgets('adopted audio-only session has no stored video stream', (
    tester,
  ) async {
    const audioStream = PlayableStream(
      url: 'https://audio.example.com/64',
      quality: 'audio 64kbps',
      hasVideo: false,
    );
    final api = FakeYouTubeApi(
      details: VideoDetails(
        info: testVideos.first,
        description: '',
        streams: const [audioStream],
      ),
    );
    final player = FakePlayerController();
    final state = await testState(api: api, player: player);
    state.playback.attach(player, testVideos.first, stream: audioStream);
    state.playback.audioOnly = true;
    state.playback.release(player);

    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audio only'));
    await tester.pumpAndSettle();

    expect(state.playback.audioOnly, isFalse);
    expect(player.opened.last, 'https://audio.example.com/64');
  });

  testWidgets('audio-only player without artwork shows a note icon', (
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
              audioOnly: true,
              artworkUrl: 'not-a-url',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.music_note), findsOneWidget);
  });
}
