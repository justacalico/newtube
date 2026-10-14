import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/history_store.dart';
import 'package:newtube/ui/pages/home_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:newtube/ui/widgets/video_card.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  test('positions persist and clear', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final history = await HistoryStore.load(prefs);
    await history.savePosition('v1', const Duration(seconds: 42), prefs);
    expect(history.positionFor('v1'), const Duration(seconds: 42));
    expect(history.inProgress, isEmpty);

    await history.record(
      const VideoInfo(id: 'v1', title: 't', author: 'a', channelId: 'c'),
      prefs,
    );
    expect(history.inProgress.single.id, 'v1');

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
    expect(reloaded.inProgress, isEmpty);
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

  testWidgets('continue watching row lists in-progress videos', (tester) async {
    final state = await testState(
      history: HistoryStore([testVideos.first], {'v1': 30}),
    );
    await pumpPage(tester, state, const HomePage());
    await tester.pumpAndSettle();
    expect(find.text('Continue watching'), findsOneWidget);
    expect(find.text('First video'), findsWidgets);
    await tester.tap(find.widgetWithText(VideoCard, 'First video').first);
    await tester.pumpAndSettle();
    expect(find.byType(WatchPage), findsOneWidget);
  });
}
