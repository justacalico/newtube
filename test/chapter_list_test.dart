import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/ui/pages/watch_page.dart';

import 'fakes.dart';

void main() {
  testWidgets('chapters section lists chapters and seeks on tap', (
    tester,
  ) async {
    final api = FakeYouTubeApi(
      details: VideoDetails(
        info: testVideos.first,
        description: 'Summary\n0:00 Intro\n1:00 Middle\n2:00 End',
        streams: testStreams,
      ),
    );
    final player = FakePlayerController()
      ..duration = const Duration(minutes: 3);
    final state = await testState(api: api, player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Chapters'), 200);
    await tester.tap(find.text('Chapters'));
    await tester.pumpAndSettle();
    expect(find.text('Intro'), findsWidgets);
    expect(find.text('End'), findsOneWidget);
    expect(find.text('Middle'), findsOneWidget);

    await tester.ensureVisible(find.text('Middle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Middle'));
    await tester.pumpAndSettle();
    expect(player.lastSeek, const Duration(minutes: 1));
  });
}
