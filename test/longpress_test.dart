import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/ui/widgets/video_card.dart';
import 'package:newtube/ui/widgets/video_list_tile.dart';

import 'fakes.dart';

void main() {
  testWidgets('long-press on card opens action sheet', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: SizedBox(
          width: 300,
          height: 200,
          child: VideoCard(video: testVideos.first, onTap: () {}),
        ),
      ),
    );
    await tester.longPress(find.byType(VideoCard));
    await tester.pumpAndSettle();
    expect(find.text('Not interested'), findsOneWidget);
    expect(find.text('Add to queue'), findsOneWidget);
  });

  testWidgets('long-press on list tile opens action sheet', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: VideoListTile(video: testVideos.first, onTap: () {}),
      ),
    );
    await tester.longPress(find.byType(VideoListTile));
    await tester.pumpAndSettle();
    expect(find.text('Not interested'), findsOneWidget);
    await tester.tap(find.text('Not interested'));
    await tester.pumpAndSettle();
    expect(state.hidden.isVideoHidden('v1'), isTrue);
  });
}
