import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/services/ryd.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';

import 'fakes.dart';

RydClient _client(int status, String body) => RydClient(
  client: MockClient(
    (request) async => http.Response.bytes(utf8.encode(body), status),
  ),
);

void main() {
  test('RydClient parses the dislike count', () async {
    final client = _client(200, '{"dislikes": 42, "likes": 1000}');
    expect(await client.dislikes('v1'), 42);
  });

  test('RydClient returns null for missing votes', () async {
    expect(await _client(404, '{}').dislikes('v1'), isNull);
    expect(await _client(200, '[]').dislikes('v1'), isNull);
  });

  test('RydClient throws on server errors', () async {
    expect(_client(500, '').dislikes('v1'), throwsA(isA<RydException>()));
  });

  test('ryd setting persists', () async {
    final state = await testState();
    expect(state.settings.rydEnabled, isFalse);
    await state.settings.setRydEnabled(true, state.prefs);
    expect(state.settings.rydEnabled, isTrue);
    final reloaded = await SettingsStore.load(state.prefs);
    expect(reloaded.rydEnabled, isTrue);
  });

  testWidgets('watch page shows dislikes when enabled', (tester) async {
    final ryd = FakeRydClient(count: 42);
    final state = await testState(
      ryd: ryd,
      settings: SettingsStore(rydEnabled: true),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(ryd.calls, 1);
    expect(find.textContaining('42 dislikes'), findsOneWidget);
  });

  testWidgets('watch page skips ryd when disabled', (tester) async {
    final ryd = FakeRydClient(count: 42);
    final state = await testState(ryd: ryd);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(ryd.calls, 0);
    expect(find.textContaining('dislikes'), findsNothing);
  });

  testWidgets('watch page tolerates ryd failures', (tester) async {
    final ryd = FakeRydClient()..failure = StateError('down');
    final state = await testState(
      ryd: ryd,
      settings: SettingsStore(rydEnabled: true),
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(ryd.calls, 1);
    expect(find.textContaining('dislikes'), findsNothing);
  });

  testWidgets('settings toggle enables dislikes', (tester) async {
    final state = await testState();
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Show dislike counts'), 200);
    await tester.ensureVisible(find.text('Show dislike counts'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Show dislike counts'),
    );
    await tester.pumpAndSettle();
    expect(state.settings.rydEnabled, isTrue);
  });

  test('RydException formats its message', () {
    expect(
      RydException('rate limited').toString(),
      'RydException: rate limited',
    );
  });
}
