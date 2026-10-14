import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/utils/description.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/ui/pages/watch_page.dart';

import 'fakes.dart';

void main() {
  test('descriptionSpans linkifies urls and timestamps', () {
    final links = <Uri>[];
    final seeks = <Duration>[];
    final spans = descriptionSpans(
      'Intro https://youtube.com/x and 1:23 or 1:02:45 end',
      onLink: links.add,
      onTimestamp: seeks.add,
    );
    expect(spans.length, greaterThan(3));

    final rich = TextSpan(children: spans);
    expect(rich.toPlainText(), contains('Intro'));
    expect(rich.toPlainText(), contains('https://youtube.com/x'));
    expect(rich.toPlainText(), contains('1:23'));
    expect(rich.toPlainText(), contains('1:02:45'));
    expect(rich.toPlainText(), contains(' end'));

    TextSpan? findSpan(String needle) => spans.whereType<TextSpan>().firstWhere(
      (s) => s.text == needle,
      orElse: () => const TextSpan(),
    );
    (findSpan('https://youtube.com/x')!.recognizer as TapGestureRecognizer)
        .onTap!();
    expect(links.single.toString(), 'https://youtube.com/x');

    (findSpan('1:23')!.recognizer as TapGestureRecognizer).onTap!();
    expect(seeks.single, const Duration(minutes: 1, seconds: 23));

    (findSpan('1:02:45')!.recognizer as TapGestureRecognizer).onTap!();
    expect(seeks.last, const Duration(hours: 1, minutes: 2, seconds: 45));
  });

  test('descriptionSpans leaves plain text untouched', () {
    final spans = descriptionSpans('no links here');
    expect(spans.length, 1);
    expect((spans.first as TextSpan).text, 'no links here');
  });

  test(
    'descriptionSpans keeps unmatched urls and lacks taps without handlers',
    () {
      final spans = descriptionSpans(
        'visit https://x.y/z at 2:30',
        onLink: (_) {},
      );
      final urlSpan = spans.whereType<TextSpan>().firstWhere(
        (s) => s.text == 'https://x.y/z',
      );
      expect(urlSpan.recognizer, isNotNull);
      final ts = spans.whereType<TextSpan>().firstWhere(
        (s) => s.text == '2:30',
      );
      expect(ts.recognizer, isNull);
    },
  );

  testWidgets('watch page description seeks on timestamp tap', (tester) async {
    final player = FakePlayerController();
    final launched = <Uri>[];
    final api = FakeYouTubeApi(
      feed: testVideos,
      details: VideoDetails(
        info: testVideos.first,
        description: 'skip to 0:42 or visit https://youtu.be/x',
        streams: testStreams,
      ),
    );
    final state = await testState(api: api, player: player, launched: launched);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.text('skip to 0:42 or visit https://youtu.be/x'),
    );
    await tester.pumpAndSettle();
    final selectable = tester.widget<SelectableText>(
      find.byType(SelectableText).last,
    );
    final spans = selectable.textSpan!.children!.whereType<TextSpan>();
    (spans.firstWhere((s) => s.text == '0:42').recognizer!
            as TapGestureRecognizer)
        .onTap!();
    expect(player.lastSeek, const Duration(seconds: 42));
    (spans.firstWhere((s) => s.text == 'https://youtu.be/x').recognizer!
            as TapGestureRecognizer)
        .onTap!();
    expect(launched.single.toString(), 'https://youtu.be/x');
  });
}
