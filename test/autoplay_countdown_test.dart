import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/pages/watch_page.dart';

import 'fakes.dart';

void main() {
  testWidgets('autoplay waits on a countdown before switching', (
    tester,
  ) async {
    final player = FakePlayerController();
    final api = FakeYouTubeApi(
      feed: testVideos,
      related: testVideos.sublist(1),
    );
    final state = await testState(api: api, player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    player.emitCompleted();
    await tester.pump();
    await tester.pump();
    expect(find.text('Up next'), findsOneWidget);
    expect(find.text(testVideos[1].title), findsWidgets);

    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.text('Up next'), findsNothing);
  });

  testWidgets('cancelling the countdown leaves the end screen', (tester) async {
    final player = FakePlayerController();
    final api = FakeYouTubeApi(
      feed: testVideos,
      related: testVideos.sublist(1),
    );
    final state = await testState(api: api, player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    player.emitCompleted();
    await tester.pump();
    await tester.pump();
    expect(find.text('Up next'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Up next'), findsNothing);
    expect(find.text('Replay'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Replay'), findsOneWidget);
  });

  testWidgets('autoplay off shows the plain end screen', (tester) async {
    final player = FakePlayerController();
    final api = FakeYouTubeApi(
      feed: testVideos,
      related: testVideos.sublist(1),
    );
    final state = await testState(
      api: api,
      player: player,
      settings: SettingsStore(autoplay: false),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    player.emitCompleted();
    await tester.pump();
    await tester.pump();
    expect(find.text('Up next'), findsNothing);
    expect(find.text('Replay'), findsOneWidget);
  });
}
