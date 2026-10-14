import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/ui/widgets/thumbnail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:newtube/state/settings_store.dart';

import 'fakes.dart';

void main() {
  test('dataSaver persists', () async {
    SharedPreferences.setMockInitialValues({'data_saver': true});
    final prefs = await SharedPreferences.getInstance();
    final settings = await SettingsStore.load(prefs);
    expect(settings.dataSaver, isTrue);
  });

  testWidgets('thumbnail placeholder under data saver', (tester) async {
    final state = await testState();
    await state.settings.setDataSaver(true, state.prefs);
    await pumpPage(
      tester,
      state,
      const Scaffold(
        body: VideoThumbnail(url: 'https://img.youtube.com/vi/x/0.jpg'),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
  });
}
