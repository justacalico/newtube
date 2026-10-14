import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/services/backup.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  test('backup round-trips prefs and restores stores', () async {
    SharedPreferences.setMockInitialValues({
      'autoplay': false,
      'history': '[{"id":"x","title":"T","author":"a","channelId":"c"}]',
      'count_pref': 3,
    });
    final prefs = await SharedPreferences.getInstance();
    final text = exportBackup(prefs);

    SharedPreferences.setMockInitialValues({});
    final target = await SharedPreferences.getInstance();
    expect(target.getBool('autoplay'), isNull);
    final count = await importBackup(text, target);
    expect(count, 3);
    expect(target.getBool('autoplay'), isFalse);
    expect(target.getString('history'), contains('"x"'));
    expect(target.getInt('count_pref'), 3);
  });

  test('bad backup throws', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(() => importBackup('not json', prefs), throwsFormatException);
  });

  testWidgets('backup export and restore flow', (tester) async {
    String? saved;
    final state = await testState(
      saveFile: (name, bytes, {extension}) async {
        saved = String.fromCharCodes(bytes);
        return '/tmp/$name';
      },
      openFile: () async => saved,
    );
    await state.settings.setAutoplay(true, state.prefs);
    await state.history.record(testVideos.first, state.prefs);
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Export backup'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Export backup'));
    await tester.pumpAndSettle();
    expect(saved, isNotNull);
    await tester.pump(const Duration(seconds: 5));

    state.settings.setAutoplay(false, state.prefs);
    await state.history.clear(state.prefs);
    await tester.scrollUntilVisible(
      find.text('Import backup'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Restored'), findsOneWidget);
    expect(state.settings.autoplay, isTrue);
    expect(state.history.contains('v1'), isTrue);
  });
}
