import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/widgets/video_grid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  testWidgets('list density renders tiles', (tester) async {
    final state = await testState();
    await state.settings.setFeedDensity(1, state.prefs);
    await pumpPage(
      tester,
      state,
      Scaffold(
        body: VideoGrid(videos: testVideos, onVideoTap: (_) {}),
      ),
    );
    await tester.pump();
    expect(find.byType(ListTile), findsWidgets);
    expect(find.byType(GridView), findsNothing);
  });

  test('feedDensity persists', () async {
    SharedPreferences.setMockInitialValues({'feed_density': 2});
    final prefs = await SharedPreferences.getInstance();
    final settings = await SettingsStore.load(prefs);
    expect(settings.feedDensity, 2);
    await settings.setFeedDensity(1, prefs);
    expect(prefs.getInt('feed_density'), 1);
  });
}
