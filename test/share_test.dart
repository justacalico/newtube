import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:newtube/ui/widgets/video_list_tile.dart';

import 'package:newtube/services/share.dart';

import 'fakes.dart';

void main() {
  testWidgets('card menu shares, copies and opens on YouTube', (tester) async {
    final shared = FakeShareActions();
    final launched = <Uri>[];
    final state = await testState(share: shared, launched: launched);
    await pumpPage(
      tester,
      state,
      VideoListTile(video: testVideos.first, onTap: _noop),
    );
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(shared.shared, [
      'https://www.youtube.com/watch?v=${testVideos.first.id}',
    ]);

    final clip = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clip.add((call.arguments as Map)['text'] as String);
          }
          return null;
        });

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy link'));
    await tester.pumpAndSettle();
    expect(clip, ['https://www.youtube.com/watch?v=${testVideos.first.id}']);
    expect(find.text('Link copied'), findsOneWidget);

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watch on YouTube'));
    await tester.pumpAndSettle();
    expect(
      launched.single.toString(),
      'https://www.youtube.com/watch?v=${testVideos.first.id}',
    );
  });

  testWidgets('watch page share menu copies link at current time', (
    tester,
  ) async {
    final shared = FakeShareActions();
    final player = FakePlayerController()
      ..position = const Duration(seconds: 90);
    final launched = <Uri>[];
    final clip = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clip.add((call.arguments as Map)['text'] as String);
          }
          return null;
        });
    final state = await testState(
      player: player,
      share: shared,
      launched: launched,
    );
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    player.emitPosition(const Duration(seconds: 90));
    await tester.pump();

    await tester.tap(find.byTooltip('Share'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy link at current time'));
    await tester.pumpAndSettle();
    expect(
      clip.single,
      'https://www.youtube.com/watch?v=${testVideos.first.id}&t=90s',
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Share'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(
      shared.shared.single,
      'https://www.youtube.com/watch?v=${testVideos.first.id}',
    );

    clip.clear();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Share'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy link'));
    await tester.pumpAndSettle();
    expect(
      clip.single,
      'https://www.youtube.com/watch?v=${testVideos.first.id}',
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Share'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watch on YouTube'));
    await tester.pumpAndSettle();
    expect(
      launched.single.toString(),
      'https://www.youtube.com/watch?v=${testVideos.first.id}',
    );
  });

  test('share actions reach the platform', () async {
    final shared = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/share'),
          (call) async {
            shared.add(call.method);
            return 'dev.fluttercommunity.plus/share/success';
          },
        );
    final clip = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clip.add((call.arguments as Map)['text'] as String);
          }
          return null;
        });

    await SheetShareActions().share('hello');
    await ClipboardShareActions().share('world');
    expect(shared, isNotEmpty);
    expect(clip, ['world']);
  });
}

void _noop() {}
