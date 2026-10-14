import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/services/network_proxy.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  test('proxyRule parses schemes', () {
    expect(proxyRule(''), '');
    expect(proxyRule('  '), '');
    expect(proxyRule('socks5://127.0.0.1:9050'), 'SOCKS5 127.0.0.1:9050');
    expect(proxyRule('http://127.0.0.1:8080'), 'PROXY 127.0.0.1:8080');
    expect(proxyRule('https://127.0.0.1:8080'), 'PROXY 127.0.0.1:8080');
    expect(proxyRule('127.0.0.1:8080'), 'PROXY 127.0.0.1:8080');
  });

  test('networkProxy persists', () async {
    SharedPreferences.setMockInitialValues({'network_proxy': 'socks5://x:1'});
    final prefs = await SharedPreferences.getInstance();
    final settings = await SettingsStore.load(prefs);
    expect(settings.networkProxy, 'socks5://x:1');
    await settings.setNetworkProxy('http://y:2', prefs);
    expect(prefs.getString('network_proxy'), 'http://y:2');
  });

  testWidgets('proxy field shows on native', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      const SettingsPage(),
      size: const Size(800, 3000),
    );
    await tester.pumpAndSettle();
    expect(find.text('Network proxy'), findsOneWidget);
    await tester.enterText(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText == 'socks5://127.0.0.1:9050',
      ),
      'http://1.2.3.4:8080',
    );
    await tester.pump();
    expect(state.settings.networkProxy, 'http://1.2.3.4:8080');
  });
}
