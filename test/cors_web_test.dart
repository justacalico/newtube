import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/services/proxy_client.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/pages/home_page.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:newtube/ui/widgets/cors_notice.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  test('proxiedUrl passes through without a prefix', () {
    expect(proxiedUrl('https://a/b', null), 'https://a/b');
    expect(proxiedUrl('https://a/b', ''), 'https://a/b');
  });

  test('proxiedUrl appends the encoded url', () {
    expect(
      proxiedUrl('https://a/b?x=1', 'https://p/?url='),
      'https://p/?url=https%3A%2F%2Fa%2Fb%3Fx%3D1',
    );
  });

  test('ProxiedClient rewrites requests when a prefix is set', () async {
    var prefix = '';
    final seen = <String>[];
    final client = ProxiedClient(
      MockClient((request) async {
        seen.add(request.url.toString());
        return http.Response('ok', 200);
      }),
      () => prefix,
    );

    await client.get(Uri.parse('https://youtube.com/x'));
    prefix = 'https://proxy/?u=';
    await client.post(
      Uri.parse('https://youtube.com/y'),
      headers: {'a': 'b'},
      body: 'hello',
    );
    expect(seen, [
      'https://youtube.com/x',
      'https://proxy/?u=https%3A%2F%2Fyoutube.com%2Fy',
    ]);
    client.close();
  });

  test('settings store persists proxy prefix', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = SettingsStore();
    await store.setProxyPrefix('  https://p/?u= ', prefs);
    expect(store.proxyPrefix, 'https://p/?u=');
    expect((await SettingsStore.load(prefs)).proxyPrefix, 'https://p/?u=');
  });

  testWidgets('web feed error shows cors help and launches links', (
    tester,
  ) async {
    final api = FakeYouTubeApi()..error = 'cors';
    final launched = <Uri>[];
    final state = await testState(api: api, isWeb: true, launched: launched);
    await pumpPage(tester, state, HomePage());
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Videos are blocked in the browser'), findsOneWidget);

    await tester.tap(find.text('Firefox add-on'));
    await tester.tap(find.text('Chrome extension'));
    expect(launched.map((u) => u.host), [
      'addons.mozilla.org',
      'chromewebstore.google.com',
    ]);
  });

  testWidgets('non-web feed error hides cors help', (tester) async {
    final api = FakeYouTubeApi()..error = 'x';
    final state = await testState(api: api);
    await pumpPage(tester, state, const HomePage());
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.byType(CorsNotice), findsNothing);
  });

  testWidgets('web settings shows the proxy field', (tester) async {
    final state = await testState(isWeb: true);
    await pumpPage(tester, state, SettingsPage());
    await tester.pumpAndSettle();

    expect(find.text('CORS proxy prefix'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField),
      'https://proxy.example/?url=',
    );
    await tester.pump();
    expect(state.settings.proxyPrefix, 'https://proxy.example/?url=');
  });
}
