import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/subscriptions_store.dart';
import 'package:newtube/ui/pages/channel_page.dart';
import 'package:newtube/ui/pages/history_page.dart';
import 'package:newtube/ui/pages/home_page.dart';
import 'package:newtube/ui/pages/search_page.dart';
import 'package:newtube/ui/pages/subscriptions_page.dart';

import 'fakes.dart';

void main() {
  group('HomePage', () {
    testWidgets('shows feed and opens video and channel', (tester) async {
      final state = await testState();
      await pumpPage(tester, state, const HomePage());
      await tester.pumpAndSettle();

      expect(find.text('First video'), findsOneWidget);
      await tester.tap(find.text('First video'));
      await tester.pumpAndSettle();
      expect(find.text('A video description'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Channel One').first);
      await tester.pumpAndSettle();
      expect(find.text('Channel One'), findsWidgets);
    });

    testWidgets('error state retries', (tester) async {
      final api = FakeYouTubeApi()..error = 'boom';
      final state = await testState(api: api);
      await pumpPage(tester, state, const HomePage());
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);

      api.error = null;
      api.feed = testVideos;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('First video'), findsOneWidget);
    });

    testWidgets('empty feed shows empty message', (tester) async {
      final state = await testState(api: FakeYouTubeApi());
      await pumpPage(tester, state, const HomePage());
      await tester.pumpAndSettle();
      expect(find.text('No videos found'), findsOneWidget);
    });
  });

  group('SearchPage', () {
    testWidgets('shows channels and videos', (tester) async {
      final api = FakeYouTubeApi(
        searchResults: const SearchResults(
          videos: testVideos,
          channels: [testChannel],
        ),
      );
      final state = await testState(api: api);
      await pumpPage(tester, state, const SearchPage(query: 'cats'));
      await tester.pumpAndSettle();

      expect(find.text('Results: cats'), findsOneWidget);
      expect(find.text('Channel One'), findsWidgets);
      await tester.tap(find.text('Channel One').first);
      await tester.pumpAndSettle();
      expect(find.text('Videos'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('First video'));
      await tester.pumpAndSettle();
    });
  });

  group('ChannelPage', () {
    testWidgets('shows channel header, subscribes, opens video', (
      tester,
    ) async {
      final state = await testState(api: FakeYouTubeApi(uploads: testVideos));
      await pumpPage(tester, state, const ChannelPage(channelId: 'c1'));
      await tester.pumpAndSettle();

      expect(find.text('Channel One'), findsWidgets);
      expect(find.text('54.3K subscribers'), findsOneWidget);

      await tester.tap(find.text('Subscribe'));
      await tester.pump();
      expect(state.subscriptions.isSubscribed('c1'), isTrue);
      expect(find.text('Subscribed'), findsOneWidget);
      await tester.tap(find.text('Subscribed'));
      await tester.pump();
      expect(state.subscriptions.isSubscribed('c1'), isFalse);

      await tester.tap(find.text('First video'));
      await tester.pumpAndSettle();
    });

    testWidgets('error state retries', (tester) async {
      final api = FakeYouTubeApi()..error = 'x';
      final state = await testState(api: api);
      await pumpPage(tester, state, const ChannelPage(channelId: 'c1'));
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);
      api.error = null;
      api.uploads = testVideos;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('First video'), findsOneWidget);
    });
  });

  group('SubscriptionsPage', () {
    testWidgets('empty state when no subscriptions', (tester) async {
      final state = await testState();
      await pumpPage(tester, state, const SubscriptionsPage());
      await tester.pumpAndSettle();
      expect(find.text('No subscriptions yet'), findsOneWidget);
    });

    testWidgets('lists channels, latest videos, unsubscribe', (tester) async {
      final subs = SubscriptionsStore({'c1': testChannel});
      final api = FakeYouTubeApi(uploads: testVideos);
      final state = await testState(api: api, subscriptions: subs);
      await pumpPage(tester, state, const SubscriptionsPage());
      await tester.pumpAndSettle();

      expect(find.text('Channel One'), findsWidgets);
      expect(find.text('Latest from your subscriptions'), findsOneWidget);
      expect(find.text('First video'), findsOneWidget);

      await tester.tap(find.text('Unsubscribe'));
      await tester.pumpAndSettle();
      expect(find.text('No subscriptions yet'), findsOneWidget);
    });

    testWidgets('opens channel and video', (tester) async {
      final subs = SubscriptionsStore({'c1': testChannel});
      final api = FakeYouTubeApi(uploads: testVideos);
      final state = await testState(api: api, subscriptions: subs);
      await pumpPage(tester, state, const SubscriptionsPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Channel One').first);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('First video'));
      await tester.pumpAndSettle();
    });
  });

  group('HistoryPage', () {
    testWidgets('empty state', (tester) async {
      final state = await testState();
      await pumpPage(tester, state, const HistoryPage());
      await tester.pumpAndSettle();
      expect(find.text('Nothing watched yet'), findsOneWidget);
    });

    testWidgets('lists, opens and clears entries', (tester) async {
      final prefs = <String, Object>{
        'history': '[{"id":"v1","title":"First video","author":"Channel One","channelId":"c1","duration":201}]',
      };
      final state = await testState(initialPrefs: prefs);
      await pumpPage(tester, state, const HistoryPage());
      await tester.pumpAndSettle();

      expect(find.text('First video'), findsOneWidget);
      expect(find.text('3:21'), findsOneWidget);

      await tester.tap(find.text('First video'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear history'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing watched yet'), findsOneWidget);
    });
  });
}
