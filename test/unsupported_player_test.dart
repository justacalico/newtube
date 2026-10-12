import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/services/unsupported_player.dart';

void main() {
  test('unsupported player is a harmless no-op', () async {
    final player = UnsupportedPlayerController();
    expect(player.position, Duration.zero);
    expect(player.duration, Duration.zero);
    expect(player.playing, isFalse);
    expect(player.buffering, isFalse);
    expect(await player.positionStream.isEmpty, isTrue);
    expect(await player.durationStream.isEmpty, isTrue);
    expect(await player.playingStream.isEmpty, isTrue);
    expect(await player.bufferingStream.isEmpty, isTrue);
    await player.open('https://x', audioUrl: 'a');
    await player.play();
    await player.pause();
    await player.seek(const Duration(seconds: 1));
    await player.dispose();
  });

  testWidgets('buildView renders nothing', (tester) async {
    final player = UnsupportedPlayerController();
    await tester.pumpWidget(
      Builder(builder: (context) => player.buildView(context)),
    );
    expect(find.byType(SizedBox), findsWidgets);
  });
}
