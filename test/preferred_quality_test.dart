import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:newtube/utils/stream_picker.dart';

import 'fakes.dart';
import 'stream_picker_test.dart' show v720, v360v, m360, m180, a128;

void main() {
  test('preferred quality caps the resolution', () {
    final choice = pickDefaultStream(
      const [v720, m360, m180, a128],
      desktop: false,
      preferredQuality: 360,
    )!;
    expect(choice.stream, m360);
  });

  test('preferred quality picks the largest stream at or below the cap', () {
    final choice = pickDefaultStream(
      const [v720, m360, m180, a128],
      desktop: false,
      preferredQuality: 480,
    )!;
    expect(choice.stream, m360);
  });

  test('preferred quality on desktop prefers a separate video stream', () {
    final choice = pickDefaultStream(
      const [v720, v360v, m360, m180, a128],
      desktop: true,
      preferredQuality: 720,
    )!;
    expect(choice.stream, v720);
    expect(choice.audio, a128);
  });

  test('lowest picks the smallest video stream', () {
    final choice = pickDefaultStream(
      const [v720, m360, m180, a128],
      desktop: false,
      preferredQuality: -1,
    )!;
    expect(choice.stream, m180);
  });

  test('lowest pairs a video-only stream with audio', () {
    final choice = pickDefaultStream(
      const [v720, v360v, a128],
      desktop: true,
      preferredQuality: -1,
    )!;
    expect(choice.stream, v360v);
    expect(choice.audio, a128);
  });

  test('desktop preference falls back to a muxed stream', () {
    final choice = pickDefaultStream(
      const [m360, m180, a128],
      desktop: true,
      preferredQuality: 360,
    )!;
    expect(choice.stream, m360);
  });

  test('preferred quality above everything uses the default pick', () {
    final choice = pickDefaultStream(
      const [m360, m180, a128],
      desktop: false,
      preferredQuality: 2160,
    )!;
    expect(choice.stream, m360);
  });

  test('preferred quality persists through the settings store', () async {
    final state = await testState();
    expect(state.settings.preferredQuality, 0);
    await state.settings.setPreferredQuality(720, state.prefs);
    expect(state.settings.preferredQuality, 720);

    final reloaded = await SettingsStore.load(state.prefs);
    expect(reloaded.preferredQuality, 720);
  });

  testWidgets('settings page stores the preferred quality', (tester) async {
    final state = await testState();
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Auto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('720p'));
    await tester.pumpAndSettle();
    expect(state.settings.preferredQuality, 720);
  });

  testWidgets('watch page opens the preferred quality', (tester) async {
    final player = FakePlayerController();
    final state = await testState(
      player: player,
      settings: SettingsStore(preferredQuality: 360),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.opened.single, 'https://video.example.com/360');
  });
}
