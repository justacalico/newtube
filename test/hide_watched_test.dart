import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/state/history_store.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/ui/pages/search_page.dart';

import 'fakes.dart';

void main() {
  test('hideWatched persists', () async {
    final state = await testState(initialPrefs: {'hide_watched': true});
    expect(state.settings.hideWatched, isTrue);
    await state.settings.setHideWatched(false, state.prefs);
    expect(state.prefs.getBool('hide_watched'), isFalse);
  });

  testWidgets('hide watched filters search results', (tester) async {
    const watched = VideoInfo(
      id: 'w1',
      title: 'Already seen',
      author: 'a',
      channelId: 'c',
    );
    const fresh = VideoInfo(
      id: 'n1',
      title: 'Fresh video',
      author: 'a',
      channelId: 'c',
    );
    final api = FakeYouTubeApi(
      searchResults: SearchResults(videos: [watched, fresh]),
    );
    final state = await testState(
      api: api,
      history: HistoryStore([watched]),
      initialPrefs: {'hide_watched': true},
    );
    await pumpPage(tester, state, const SearchPage());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'x');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Fresh video'), findsWidgets);
    expect(find.text('Already seen'), findsNothing);
  });

  testWidgets('hide watched off keeps watched search results', (tester) async {
    const watched = VideoInfo(
      id: 'w1',
      title: 'Already seen',
      author: 'a',
      channelId: 'c',
    );
    final api = FakeYouTubeApi(searchResults: SearchResults(videos: [watched]));
    final state = await testState(api: api, history: HistoryStore([watched]));
    await pumpPage(tester, state, const SearchPage());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'x');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Already seen'), findsWidgets);
  });
}
