import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/subscriptions_store.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:newtube/ui/pages/subscriptions_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  test('groups assign, rename, delete, persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = SubscriptionsStore({
      'UC1': const ChannelInfo(id: 'UC1', name: 'A'),
      'UC2': const ChannelInfo(id: 'UC2', name: 'B'),
    });
    await store.setGroup('UC1', 'Tech', prefs);
    await store.setGroup('UC2', 'Music', prefs);
    expect(store.groups.toSet(), {'Tech', 'Music'});
    expect(store.groupOf('UC1'), 'Tech');
    expect(store.channelsInGroup('Tech').single.id, 'UC1');
    expect(store.channelsInGroup(null).length, 2);

    await store.renameGroup('Tech', 'Gadgets', prefs);
    expect(store.groupOf('UC1'), 'Gadgets');

    final reloaded = await SubscriptionsStore.load(prefs);
    expect(reloaded.groupOf('UC1'), 'Gadgets');

    await reloaded.deleteGroup('Gadgets', prefs);
    expect(reloaded.groupOf('UC1'), isNull);
    await reloaded.setGroup('UC2', null, prefs);
    expect(reloaded.groups, isEmpty);
  });

  testWidgets('group chips filter the feed', (tester) async {
    final store = SubscriptionsStore(
      {
        'UC1': const ChannelInfo(id: 'UC1', name: 'Alpha'),
        'UC2': const ChannelInfo(id: 'UC2', name: 'Beta'),
      },
      {'UC1': 'Tech'},
    );
    final api = FakeYouTubeApi();
    final state = await testState(subscriptions: store, api: api);
    await pumpPage(tester, state, const SubscriptionsPage());
    await tester.pumpAndSettle();
    expect(find.text('All channels'), findsOneWidget);
    expect(find.text('Tech'), findsOneWidget);

    await tester.tap(find.text('Tech'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsWidgets);
    expect(find.text('Beta'), findsNothing);
  });

  testWidgets('long-press channel opens group dialog', (tester) async {
    final store = SubscriptionsStore({
      'UC1': const ChannelInfo(id: 'UC1', name: 'Alpha'),
    });
    final state = await testState(subscriptions: store);
    await pumpPage(tester, state, const SubscriptionsPage());
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Favs');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.groupOf('UC1'), 'Favs');
  });

  testWidgets('feed loads channels concurrently', (tester) async {
    final store = SubscriptionsStore({
      for (var i = 0; i < 8; i++) 'UC$i': ChannelInfo(id: 'UC$i', name: 'Ch$i'),
    });
    final api = FakeYouTubeApi()..channelVideosGate = Completer<void>();
    final state = await testState(subscriptions: store, api: api);
    await pumpPage(tester, state, const SubscriptionsPage());
    await tester.pump();
    api.channelVideosGate!.complete();
    await tester.pumpAndSettle();
    expect(api.peakConcurrent, greaterThan(1));
    expect(api.peakConcurrent, lessThanOrEqualTo(4));
  });

  testWidgets('manage groups dialog deletes groups', (tester) async {
    final store = SubscriptionsStore(
      {'UC1': const ChannelInfo(id: 'UC1', name: 'Alpha')},
      {'UC1': 'Tech'},
    );
    final state = await testState(subscriptions: store);
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Manage groups'),
      150,
      scrollable: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    );
    await tester.tap(find.text('Manage groups'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Tech'), findsWidgets);
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    expect(store.groups, isEmpty);
  });
}
