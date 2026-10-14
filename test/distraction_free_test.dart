import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  testWidgets('settings toggles persist', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await testState();
    await pumpPage(
      tester,
      state,
      const SettingsPage(),
      size: const Size(800, 3000),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'Show comments'));
    await tester.pump();
    expect(state.settings.showComments, isFalse);
    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Show related videos'),
    );
    await tester.pump();
    expect(state.settings.showRelated, isFalse);
  });

  testWidgets('watch page hides comments and related when off', (tester) async {
    SharedPreferences.setMockInitialValues({
      'show_comments': false,
      'show_related': false,
    });
    final state = await testState();
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    expect(find.text('Comments'), findsNothing);
    expect(find.text('Related videos'), findsNothing);
  });
}
