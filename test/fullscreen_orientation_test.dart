import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/services/orientation.dart';
import 'package:newtube/ui/pages/watch_page.dart';

import 'fakes.dart';

void main() {
  testWidgets('fullscreen locks landscape and restores on exit', (
    tester,
  ) async {
    final orientation = FakeOrientationActions();
    final player = FakePlayerController();
    final state = await testState(player: player, orientation: orientation);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Fullscreen'));
    await tester.pumpAndSettle();
    expect(orientation.landscapeCalls, 1);
    expect(orientation.restoreCalls, 0);

    await tester.tap(find.byTooltip('Fullscreen'));
    await tester.pumpAndSettle();
    expect(orientation.restoreCalls, 1);
  });

  test('real orientation actions hit the platform channel', () async {
    const actions = OrientationActions();
    await actions.landscape();
    await actions.restore();
  });
}
