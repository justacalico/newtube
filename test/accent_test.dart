import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  test('accent color persists', () async {
    SharedPreferences.setMockInitialValues({'accent_color': 0xFF1976D2});
    final prefs = await SharedPreferences.getInstance();
    final settings = await SettingsStore.load(prefs);
    expect(settings.accentColor, 0xFF1976D2);
    await settings.setAccentColor(0xFF388E3C, prefs);
    expect(prefs.getInt('accent_color'), 0xFF388E3C);
  });

  testWidgets('swatches select a color', (tester) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      const SettingsPage(),
      size: const Size(800, 3000),
    );
    await tester.pumpAndSettle();
    final swatch = find.byWidgetPredicate(
      (w) => w is CircleAvatar && w.backgroundColor == const Color(0xFF1976D2),
    );
    await tester.tap(swatch);
    await tester.pump();
    expect(state.settings.accentColor, 0xFF1976D2);
  });
}
