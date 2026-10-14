import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:newtube/ui/widgets/mini_player.dart';
import 'package:newtube/ui/widgets/video_actions_menu.dart';

import 'package:newtube/state/playback_session.dart';

import 'fakes.dart';

void main() {
  test('queue enqueue, playNext, takeNext, remove and move', () async {
    final session = PlaybackSession();
    const a = VideoInfo(id: 'a', title: 'A', author: '', channelId: '');
    const b = VideoInfo(id: 'b', title: 'B', author: '', channelId: '');
    const c = VideoInfo(id: 'c', title: 'C', author: '', channelId: '');
    session.enqueue(a);
    session.enqueue(c);
    session.playNext(b);
    expect(session.queue.map((v) => v.id), ['b', 'a', 'c']);

    session.moveQueued(2, 0);
    expect(session.queue.map((v) => v.id), ['c', 'b', 'a']);
    session.moveQueued(-1, 0);
    session.moveQueued(0, 99);
    expect(session.queue.map((v) => v.id), ['c', 'b', 'a']);

    session.removeQueued(1);
    expect(session.queue.map((v) => v.id), ['c', 'a']);
    session.removeQueued(9);

    expect(session.takeNextFrom(0)?.id, 'c');
    expect(session.takeNextFrom(9), isNull);
    expect(session.takeNext()?.id, 'a');
    expect(session.takeNext(), isNull);
    expect(session.queue, isEmpty);
  });

  testWidgets('card menu offers play-next and queue actions', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      Scaffold(body: VideoActionsMenu(video: testVideos.first)),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play next'));
    await tester.pumpAndSettle();
    expect(state.playback.queue.single.id, 'v1');

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to queue'));
    await tester.pumpAndSettle();
    expect(state.playback.queue.length, 2);
  });

  testWidgets('up next panel lists, removes and reorders', (tester) async {
    const a = VideoInfo(id: 'qa', title: 'Queued A', author: '', channelId: '');
    const b = VideoInfo(id: 'qb', title: 'Queued B', author: '', channelId: '');
    final state = await testState();
    final session = state.playback
      ..enqueue(a)
      ..enqueue(b);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Queued A'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SingleChildScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Up next'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();
    expect(session.queue.single.id, 'qa');
  });

  testWidgets('up next tap plays the queued video', (tester) async {
    const a = VideoInfo(id: 'qa', title: 'Queued A', author: '', channelId: '');
    final state = await testState();
    final session = state.playback..enqueue(a);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Queued A'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SingleChildScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Queued A'));
    await tester.pumpAndSettle();
    expect(session.queue, isEmpty);
  });

  testWidgets('mini player next button plays the queue head', (tester) async {
    const next = VideoInfo(
      id: 'n9',
      title: 'Next up',
      author: '',
      channelId: '',
    );
    final state = await testState();
    final session = state.playback;
    session.attach(
      FakePlayerController(),
      testVideos.first,
      stream: testStreams.first,
    );
    await pumpPage(
      tester,
      state,
      MiniPlayer(session: session, onExpand: () {}),
    );
    session.release(session.player!);
    await tester.pump();
    expect(find.byIcon(Icons.skip_next), findsNothing);

    session.enqueue(next);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.skip_next));
    await tester.pump();
    expect(session.queue, isEmpty);
    expect(state.watchRequest?.id, 'n9');
  });

  testWidgets('watch page autoplay consumes the queue first', (tester) async {
    const next = VideoInfo(
      id: 'n9',
      title: 'Queue head',
      author: '',
      channelId: '',
    );
    final player = FakePlayerController();
    final state = await testState(player: player);
    final session = state.playback..enqueue(next);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    player.emitCompleted();
    await tester.pump();
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(session.queue, isEmpty);
  });
}
