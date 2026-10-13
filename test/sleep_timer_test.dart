import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/services/sleep_timer.dart';

import 'fakes.dart';

void main() {
  test('timed sleep pauses the player when it fires', () {
    fakeAsync((async) {
      final player = FakePlayerController();
      final timer = SleepTimer(player);
      var changes = 0;
      timer.addListener(() => changes++);

      timer.startAfter(const Duration(minutes: 15));
      expect(timer.active, isTrue);
      expect(timer.remaining, const Duration(minutes: 15));

      async.elapse(const Duration(seconds: 61));
      expect(timer.remaining, const Duration(minutes: 13, seconds: 59));
      expect(player.paused, isFalse);

      async.elapse(const Duration(minutes: 15));
      expect(player.paused, isTrue);
      expect(timer.active, isFalse);
      expect(changes, greaterThan(1));
      timer.dispose();
    });
  });

  test('end of video mode pauses when playback completes', () {
    fakeAsync((async) {
      final player = FakePlayerController()
        ..playing = true
        ..duration = const Duration(minutes: 3);
      final timer = SleepTimer(player);

      timer.startAtEndOfVideo();
      expect(timer.active, isTrue);
      expect(timer.endOfVideo, isTrue);
      expect(timer.remaining, isNull);

      player.emitPosition(const Duration(minutes: 1));
      async.flushMicrotasks();
      expect(player.paused, isFalse);

      player.emitPosition(const Duration(minutes: 3));
      async.flushMicrotasks();
      expect(player.paused, isTrue);
      expect(timer.active, isFalse);
      timer.dispose();
    });
  });

  test('end of video fires immediately when already finished', () {
    final player = FakePlayerController()
      ..position = const Duration(minutes: 3)
      ..duration = const Duration(minutes: 3);
    final timer = SleepTimer(player);
    timer.startAtEndOfVideo();
    expect(player.paused, isTrue);
    expect(timer.active, isFalse);
    timer.dispose();
  });

  test('cancel stops the countdown', () {
    fakeAsync((async) {
      final player = FakePlayerController();
      final timer = SleepTimer(player);
      timer.startAfter(const Duration(minutes: 15));
      timer.cancel();
      expect(timer.active, isFalse);
      async.elapse(const Duration(minutes: 20));
      expect(player.paused, isFalse);
      timer.dispose();
    });
  });

  test('starting a new mode replaces the old one', () {
    fakeAsync((async) {
      final player = FakePlayerController()
        ..duration = const Duration(minutes: 3);
      final timer = SleepTimer(player);
      timer.startAtEndOfVideo();
      timer.startAfter(const Duration(seconds: 2));
      expect(timer.endOfVideo, isFalse);
      expect(timer.remaining, const Duration(seconds: 2));
      async.elapse(const Duration(seconds: 3));
      expect(player.paused, isTrue);
      timer.dispose();
    });
  });
}
