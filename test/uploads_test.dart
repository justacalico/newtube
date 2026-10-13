import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/uploads_watcher.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/state/subscriptions_store.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

String _feed(String videoId, String title, String published) =>
    '''
<feed xmlns:yt="http://www.youtube.com/xml/schemas/2015"
      xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <yt:videoId>$videoId</yt:videoId>
    <title>$title</title>
    <published>$published</published>
  </entry>
  <entry><yt:videoId>older</yt:videoId><title>Old</title>
    <published>2020-01-01T00:00:00+00:00</published></entry>
  <entry><yt:videoId>junk</yt:videoId></entry>
</feed>
''';

Future<SharedPreferences> _prefs([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  const channel = ChannelInfo(id: 'UC1', name: 'Chan');
  const channel2 = ChannelInfo(id: 'UC2', name: 'Chan2');

  UploadsWatcher watcher(
    SharedPreferences prefs, {
    required SubscriptionsStore subs,
    required MockClient client,
    required List<String> notified,
  }) => UploadsWatcher(
    prefs: prefs,
    subscriptions: subs,
    notify: (title, body) async => notified.add('$title|$body'),
    client: client,
  );

  test('records first seen upload without notifying', () async {
    final prefs = await _prefs();
    final notified = <String>[];
    final w = watcher(
      prefs,
      subs: SubscriptionsStore({'UC1': channel}),
      client: MockClient(
        (_) async =>
            http.Response(_feed('v1', 'New vid', '2026-01-02T00:00:00Z'), 200),
      ),
      notified: notified,
    );
    await w.checkNow();
    expect(notified, isEmpty);
    expect(prefs.getString('upload_seen'), contains('UC1'));

    final reloaded = watcher(
      prefs,
      subs: SubscriptionsStore({'UC1': channel}),
      client: MockClient(
        (_) async => http.Response(
          _feed('v2', 'Newer vid', '2026-01-03T00:00:00Z'),
          200,
        ),
      ),
      notified: notified,
    );
    await reloaded.checkNow();
    expect(notified, ['Chan|Newer vid']);
  });

  test('skips bad feeds, stale entries and notify dedupe', () async {
    final prefs = await _prefs();
    var status = 500;
    final notified = <String>[];
    final w = watcher(
      prefs,
      subs: SubscriptionsStore({'UC1': channel, 'UC2': channel2}),
      client: MockClient((request) async {
        if (request.url.queryParameters['channel_id'] == 'UC2') {
          return http.Response('not xml', status);
        }
        return http.Response(_feed('v1', 'A', '2026-01-02T00:00:00Z'), 200);
      }),
      notified: notified,
    );
    await w.checkNow();
    expect(notified, isEmpty);
    status = 200;
    await w.checkNow();
    await w.checkNow();
    expect(notified, isEmpty);
  });

  test('tolerates a corrupt seen map', () async {
    final prefs = await _prefs({'upload_seen': '{"UC1": "garbage"}'});
    final notified = <String>[];
    final w = watcher(
      prefs,
      subs: SubscriptionsStore({'UC1': channel}),
      client: MockClient(
        (_) async =>
            http.Response(_feed('v1', 'A', '2026-01-02T00:00:00Z'), 200),
      ),
      notified: notified,
    );
    await w.checkNow();
    expect(notified, ['Chan|A']);
  });

  test('notify failure does not abort the channel loop', () async {
    final prefs = await _prefs({
      'upload_seen': '{"UC1": "2020-01-01T00:00:00Z", "UC2": "2020-01-01T00:00:00Z", "GONE": "2020-01-01T00:00:00Z"}',
    });
    final notified = <String>[];
    var first = true;
    final w = UploadsWatcher(
      prefs: prefs,
      subscriptions: SubscriptionsStore({'UC1': channel, 'UC2': channel2}),
      notify: (title, body) async {
        notified.add('$title|$body');
        if (first) {
          first = false;
          throw StateError('boom');
        }
      },
      client: MockClient(
        (_) async =>
            http.Response(_feed('v1', 'A', '2026-01-02T00:00:00Z'), 200),
      ),
    );
    await w.checkNow();
    expect(notified, hasLength(2));
    expect(prefs.getString('upload_seen'), isNot(contains('GONE')));
  });

  test('dispose stops and disables the watcher', () async {
    final prefs = await _prefs();
    final w = watcher(
      prefs,
      subs: SubscriptionsStore(),
      client: MockClient((_) async => http.Response('x', 500)),
      notified: <String>[],
    );
    w.start(const Duration(minutes: 30));
    expect(w.running, isTrue);
    w.dispose();
    expect(w.running, isFalse);
    w.start(const Duration(minutes: 30));
    await w.checkNow();
    expect(w.running, isFalse);
  });

  test('loads a snapped interval from storage', () async {
    final prefs = await _prefs({'upload_interval': 42});
    expect((await SettingsStore.load(prefs)).uploadCheckIntervalMinutes, 30);
    final prefs2 = await _prefs({'upload_interval': 120});
    expect((await SettingsStore.load(prefs2)).uploadCheckIntervalMinutes, 120);
  });

  test('attach starts and stops with the setting', () async {
    final prefs = await _prefs();
    final notified = <String>[];
    final w = watcher(
      prefs,
      subs: SubscriptionsStore({'UC1': channel}),
      client: MockClient(
        (_) async =>
            http.Response(_feed('v1', 'A', '2026-01-02T00:00:00Z'), 200),
      ),
      notified: notified,
    );
    final settings = SettingsStore();
    w.attach(settings);
    expect(w.running, isFalse);

    await settings.setUploadNotificationsEnabled(true, prefs);
    expect(w.running, isTrue);
    expect(w.interval, const Duration(minutes: 30));

    await settings.setUploadCheckIntervalMinutes(60, prefs);
    expect(w.interval, const Duration(minutes: 60));

    w.attach(settings);
    await settings.setUploadNotificationsEnabled(false, prefs);
    expect(w.running, isFalse);

    w.attach(settings);
    w.dispose();
    expect(w.running, isFalse);
  });

  testWidgets('settings page toggles upload notifications', (tester) async {
    final prefs = await _prefs();
    final state = await testState(
      prefs: prefs,
      uploads: UploadsWatcher(
        prefs: prefs,
        subscriptions: SubscriptionsStore(),
        notify: (_, _) async {},
        client: MockClient((_) async => http.Response('x', 500)),
      ),
    );
    state.uploads!.attach(state.settings);
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Upload notifications'), 200);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Upload notifications'),
    );
    await tester.pumpAndSettle();
    expect(state.settings.uploadNotificationsEnabled, isTrue);
    expect(state.uploads!.running, isTrue);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Every 60 min').last);
    await tester.pumpAndSettle();
    expect(state.settings.uploadCheckIntervalMinutes, 60);
    state.uploads!.dispose();
  });
}
