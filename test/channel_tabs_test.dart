import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/ui/pages/channel_page.dart';

import 'fakes.dart';

void main() {
  testWidgets('channel page shows tabs, playlists, about, search', (
    tester,
  ) async {
    final api = FakeYouTubeApi(uploads: testVideos)
      ..channelShortsList = [
        const VideoInfo(
          id: 's1',
          title: 'Short vid',
          author: 'a',
          channelId: 'c',
          isShort: true,
        ),
      ]
      ..channelPlaylistList = [
        const PlaylistInfo(id: 'pl1', title: 'My list', videos: []),
      ]
      ..channelAboutInfo = const ChannelAbout(
        description: 'a channel',
        joinedText: 'Joined 2020',
        videoCountText: '100 videos',
      );
    final state = await testState(api: api);
    await pumpPage(tester, state, const ChannelPage(channelId: 'UC1'));
    await tester.pumpAndSettle();

    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('Shorts'), findsOneWidget);
    expect(find.text('Playlists'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    await tester.tap(find.text('Shorts'));
    await tester.pumpAndSettle();
    expect(find.text('Short vid'), findsOneWidget);

    await tester.tap(find.text('Playlists'));
    await tester.pumpAndSettle();
    expect(find.text('My list'), findsOneWidget);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('a channel'), findsOneWidget);
    expect(find.text('Joined 2020'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), testVideos.first.title);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text(testVideos.first.title), findsWidgets);
    expect(find.text(testVideos.last.title), findsNothing);
  });
}
