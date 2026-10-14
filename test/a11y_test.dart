import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/ui/widgets/video_card.dart';
import 'package:newtube/ui/widgets/mini_player.dart';

import 'fakes.dart';

void main() {
  testWidgets('video card has a semantic label', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: SizedBox(
          width: 300,
          height: 220,
          child: VideoCard(video: testVideos.first, onTap: () {}),
        ),
      ),
    );
    expect(
      find.ancestor(
        of: find.text(testVideos.first.title),
        matching: find.bySemanticsLabel(testVideos.first.title),
      ),
      findsWidgets,
    );
  });

  testWidgets('mini player exposes title semantics', (tester) async {
    final player = FakePlayerController();
    final state = await testState(player: player);
    state.playback.attach(player, testVideos.first);
    state.playback.release(player);
    await pumpPage(
      tester,
      state,
      Scaffold(
        bottomNavigationBar: MiniPlayer(
          session: state.playback,
          onExpand: () {},
        ),
      ),
    );
    final sem = tester.getSemantics(
      find
          .ancestor(
            of: find.text(testVideos.first.title),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(sem.label, contains('First'));
  });
}
