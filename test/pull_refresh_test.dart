import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/ui/pages/home_page.dart';
import 'package:newtube/ui/pages/subscriptions_page.dart';

import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/subscriptions_store.dart';

import 'fakes.dart';

void main() {
  testWidgets('pull to refresh reloads the home feed', (tester) async {
    var calls = 0;
    final api = _CountingApi(() => calls++);
    final state = await testState(api: api);
    await pumpPage(tester, state, const HomePage());
    await tester.pumpAndSettle();
    expect(calls, 1);

    await tester.drag(find.byType(GridView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('pull to refresh reloads subscriptions', (tester) async {
    var calls = 0;
    final api = _CountingApi(() => calls++);
    final subs = SubscriptionsStore({
      'UC1': const ChannelInfo(id: 'UC1', name: 'chan'),
    });
    final state = await testState(api: api, subscriptions: subs);
    await pumpPage(tester, state, const SubscriptionsPage());
    await tester.pumpAndSettle();
    expect(calls, greaterThan(0));
    final before = calls;

    await tester.drag(find.byType(GridView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(calls, greaterThan(before));
  });

  testWidgets('refresh button reloads on desktop', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    var calls = 0;
    final api = _CountingApi(() => calls++);
    final state = await testState(api: api);
    await pumpPage(tester, state, const HomePage());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(calls, 2);
    debugDefaultTargetPlatformOverride = null;
  });
}

class _CountingApi extends FakeYouTubeApi {
  _CountingApi(this.onFetch) : super(feed: testVideos);
  final VoidCallback onFetch;

  @override
  Future<List<VideoInfo>> homeFeed() async {
    onFetch();
    return feed;
  }

  @override
  Future<List<VideoInfo>> channelVideos(String channelId) async {
    onFetch();
    return feed;
  }
}
