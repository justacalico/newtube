import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/state/history_store.dart';
import 'package:newtube/ui/pages/history_page.dart';
import 'package:newtube/ui/widgets/video_actions_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  test('remove drops the entry and its position', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = HistoryStore(List.of(testVideos), {'v1': 12});
    await store.remove('v1', prefs);
    expect(store.contains('v1'), isFalse);
    expect(store.positionFor('v1'), isNull);
    expect(store.contains('v2'), isTrue);
  });

  testWidgets('filter field narrows the list', (tester) async {
    final state = await testState(history: HistoryStore(List.of(testVideos)));
    await pumpPage(tester, state, const HistoryPage());
    await tester.pumpAndSettle();
    expect(find.text('First video'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'second');
    await tester.pumpAndSettle();
    expect(find.text('First video'), findsNothing);
    expect(find.text('Second video'), findsWidgets);
  });

  testWidgets('trailing delete removes the entry', (tester) async {
    final history = HistoryStore(List.of(testVideos));
    final state = await testState(history: history);
    await pumpPage(tester, state, const HistoryPage());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(history.contains('v1'), isFalse);
    expect(find.text('First video'), findsNothing);
  });

  testWidgets('swipe removes the entry', (tester) async {
    final history = HistoryStore(List.of(testVideos));
    final state = await testState(history: history);
    await pumpPage(tester, state, const HistoryPage());
    await tester.pumpAndSettle();

    await tester.fling(find.text('First video'), const Offset(-400, 0), 800);
    await tester.pumpAndSettle();
    expect(history.contains('v1'), isFalse);
  });

  testWidgets('mark as watched toggles the entry from the card menu', (
    tester,
  ) async {
    final state = await testState();
    await pumpPage(
      tester,
      state,
      Scaffold(body: VideoActionsMenu(video: testVideos.first)),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as watched'));
    await tester.pumpAndSettle();
    expect(state.history.contains('v1'), isTrue);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as unwatched'));
    await tester.pumpAndSettle();
    expect(state.history.contains('v1'), isFalse);
  });
}
