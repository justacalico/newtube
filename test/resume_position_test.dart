import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/history_store.dart';
import 'package:newtube/ui/pages/watch_page.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  test('positions persist and clear', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final history = await HistoryStore.load(prefs);
    await history.savePosition('v1', const Duration(seconds: 42), prefs);
    expect(history.positionFor('v1'), const Duration(seconds: 42));

    await history.record(
      const VideoInfo(id: 'v1', title: 't', author: 'a', channelId: 'c'),
      prefs,
    );

    final reloaded = await HistoryStore.load(prefs);
    expect(reloaded.positionFor('v1'), const Duration(seconds: 42));
    await reloaded.clearPosition('v1', prefs);
    expect(reloaded.positionFor('v1'), isNull);

    await reloaded.record(
      const VideoInfo(id: 'v1', title: 't', author: 'a', channelId: 'c'),
      prefs,
    );
    await reloaded.savePosition('v1', const Duration(seconds: 10), prefs);
    await reloaded.clear(prefs);
    expect((await HistoryStore.load(prefs)).positionFor('v1'), isNull);
  });

  testWidgets('watch page resumes at the saved position', (tester) async {
    final history = HistoryStore([testVideos.first], {'v1': 75});
    final player = FakePlayerController();
    final state = await testState(
      api: FakeYouTubeApi(),
      history: history,
      player: player,
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(player.seeks, contains(const Duration(seconds: 75)));
    expect(find.textContaining('Resumed'), findsOneWidget);

    await tester.tap(find.text('Start over'));
    await tester.pumpAndSettle();
    expect(player.seeks, contains(Duration.zero));
  });
}
