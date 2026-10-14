import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/models/youtube_route.dart';
import 'package:newtube/ui/pages/channel_page.dart';
import 'package:newtube/ui/pages/playlist_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:newtube/ui/shell/app_shell.dart';

import 'fakes.dart';

void main() {
  testWidgets('an incoming link opens the watch page', (tester) async {
    final links = FakeLinkActions();
    final api = FakeYouTubeApi(feed: testVideos);
    final state = await testState(api: api, links: links);
    await pumpPage(tester, state, const AppShell());
    await tester.pumpAndSettle();

    links.linksController.add(Uri.parse('https://youtu.be/vid1?t=45'));
    await tester.pumpAndSettle();
    expect(find.byType(WatchPage), findsOneWidget);
  });

  testWidgets('a channel link opens the channel page', (tester) async {
    final links = FakeLinkActions();
    final api = FakeYouTubeApi(feed: testVideos)
      ..resolvedUrls = {
        'https://youtube.com/@chan': const YouTubeRoute.channel('UC1'),
      };
    final state = await testState(api: api, links: links);
    await pumpPage(tester, state, const AppShell());
    await tester.pumpAndSettle();

    links.linksController.add(Uri.parse('https://youtube.com/@chan'));
    await tester.pumpAndSettle();
    expect(find.byType(ChannelPage), findsOneWidget);
  });

  testWidgets('the initial link is honoured on startup', (tester) async {
    final links = FakeLinkActions()
      ..initialLink = Uri.parse('https://youtube.com/playlist?list=PL9');
    final state = await testState(
      api: FakeYouTubeApi(feed: testVideos),
      links: links,
    );
    await pumpPage(tester, state, const AppShell());
    await tester.pumpAndSettle();
    expect(find.byType(PlaylistPage), findsOneWidget);
  });

  testWidgets('non-youtube links are ignored', (tester) async {
    final links = FakeLinkActions();
    final state = await testState(
      api: FakeYouTubeApi(feed: testVideos),
      links: links,
    );
    await pumpPage(tester, state, const AppShell());
    await tester.pumpAndSettle();

    links.linksController.add(Uri.parse('https://example.com/x'));
    links.linksController.add(Uri.parse('https://youtube.com/feed/library'));
    await tester.pumpAndSettle();
    expect(find.byType(WatchPage), findsNothing);
    expect(find.byType(ChannelPage), findsNothing);
  });
}
