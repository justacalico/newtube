import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/services/sponsor_block.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:newtube/ui/widgets/player_view.dart';

import 'fakes.dart';

void main() {
  test('new categories appear in the picker', () {
    expect(sponsorBlockCategoryIds, contains('filler'));
    expect(sponsorBlockCategoryIds, contains('exclusive_access'));
    expect(sponsorBlockCategoryIds, contains('chapter'));
    expect(sponsorBlockJumpCategory, 'poi_highlight');
  });

  test('skipper exposes highlight and never autoskips it', () async {
    final player = FakePlayerController();
    final skipper = SegmentSkipper(
      player: player,
      segments: const [
        SponsorSegment(
          category: 'poi_highlight',
          start: Duration(seconds: 30),
          end: Duration(seconds: 30),
        ),
        SponsorSegment(
          category: 'sponsor',
          start: Duration(seconds: 60),
          end: Duration(seconds: 90),
        ),
      ],
      autoSkip: false,
    );
    expect(skipper.highlight?.start, const Duration(seconds: 30));
    skipper.jumpToHighlight();
    expect(player.seeks, contains(const Duration(seconds: 30)));

    player.emitPosition(const Duration(seconds: 60));
    await pumpEventQueue();
    expect(skipper.active?.category, 'sponsor');
  });

  testWidgets('picker shows new categories', (tester) async {
    final state = await testState(initialPrefs: {'sponsorblock_enabled': true});
    await pumpPage(
      tester,
      state,
      const SettingsPage(),
      size: const Size(800, 2400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skipped categories'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Filler'), findsOneWidget);
    expect(find.text('Point of interest (jump)'), findsOneWidget);
  });
}
