import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/services/uploads_watcher.dart';
import 'package:newtube/state/subscriptions_store.dart';
import 'package:newtube/ui/pages/subscriptions_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  test('mute persists and reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = SubscriptionsStore({
      'UC1': const ChannelInfo(id: 'UC1', name: 'A'),
    });
    await store.setMuted('UC1', true, prefs);
    expect(store.isMuted('UC1'), isTrue);
    final reloaded = await SubscriptionsStore.load(prefs);
    expect(reloaded.isMuted('UC1'), isTrue);
    await reloaded.setMuted('UC1', false, prefs);
    expect(reloaded.isMuted('UC1'), isFalse);
  });

  test('watcher skips muted channels', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = SubscriptionsStore(
      {
        'UC1': const ChannelInfo(id: 'UC1', name: 'A'),
        'UC2': const ChannelInfo(id: 'UC2', name: 'B'),
      },
      {},
      {'UC1'},
    );
    final hits = <String>[];
    final watcher = UploadsWatcher(
      prefs: prefs,
      subscriptions: store,
      notify: (title, body) async {},
      client: MockClient((req) {
        hits.add(req.url.toString());
        return Future.value(
          http.Response(
            '<feed><entry><title>x</title><link href="https://youtu.be/v1"/><published>2026-01-01T00:00:00Z</published></entry></feed>',
            200,
          ),
        );
      }),
    );
    await watcher.checkNow();
    expect(hits.any((u) => u.contains('UC2')), isTrue);
    expect(hits.any((u) => u.contains('UC1')), isFalse);
  });

  testWidgets('bell toggles mute on the channel row', (tester) async {
    final store = SubscriptionsStore({
      'UC1': const ChannelInfo(id: 'UC1', name: 'Alpha'),
    });
    final state = await testState(subscriptions: store);
    await pumpPage(tester, state, const SubscriptionsPage());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    await tester.tap(
      find.byIcon(Icons.notifications_active),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(store.isMuted('UC1'), isTrue);
    expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
  });
}
