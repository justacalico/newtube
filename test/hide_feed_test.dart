import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/state/hidden_store.dart';
import 'package:newtube/ui/widgets/video_actions_menu.dart';
import 'package:newtube/utils/feed_filter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  test('hidden persists and filters', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final hidden = await HiddenStore.load(prefs);
    await hidden.hideVideo('v1', prefs);
    await hidden.hideChannel('ch1', prefs);

    final reloaded = await HiddenStore.load(prefs);
    expect(reloaded.isVideoHidden('v1'), isTrue);
    expect(reloaded.isChannelHidden('ch1'), isTrue);

    final state = await testState(hidden: reloaded);
    final out = visibleVideos(testVideos, state.settings, state);
    expect(out.any((v) => v.id == 'v1'), isFalse);
    expect(out.any((v) => v.channelId == 'ch1'), isFalse);
  });

  testWidgets('menu hides a video and settings unhides', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      Builder(
        builder: (context) =>
            Scaffold(body: VideoActionsMenu(video: testVideos.first)),
      ),
    );
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not interested'));
    await tester.pumpAndSettle();
    expect(state.hidden.isVideoHidden('v1'), isTrue);
  });
}
