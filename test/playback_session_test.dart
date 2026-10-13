import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/sleep_timer.dart';
import 'package:newtube/state/playback_session.dart';

import 'fakes.dart';

void main() {
  test('attach stores the session and notifies', () {
    final session = PlaybackSession();
    final player = FakePlayerController();
    var notified = 0;
    session.addListener(() => notified++);

    session.attach(
      player,
      testVideos.first,
      playlist: const PlaylistInfo(
        id: 'pl1',
        title: 'Playlist',
        author: 'A',
        videoCount: 2,
        videos: testVideos,
      ),
      index: 1,
      stream: testStreams[1],
      audio: testStreams[2],
    );

    expect(session.player, player);
    expect(session.video, testVideos.first);
    expect(session.playlist?.id, 'pl1');
    expect(session.index, 1);
    expect(session.stream, testStreams[1]);
    expect(session.audio, testStreams[2]);
    expect(session.attached, isTrue);
    expect(session.minimized, isFalse);
    expect(notified, 1);
  });

  test('attaching a new player disposes and detaches the old one', () {
    final controls = FakeMediaControls();
    final session = PlaybackSession(mediaControls: controls);
    final first = FakePlayerController();
    final second = FakePlayerController();
    final firstTimer = SleepTimer(first);

    session.attach(first, testVideos.first, sleepTimer: firstTimer);
    session.attach(second, testVideos.last);

    expect(session.player, second);
    expect(first.disposed, isTrue);
    expect(controls.detaches, 1);
    expect(() => firstTimer.notifyListeners(), throwsA(isA<FlutterError>()));
  });

  test('reattaching the same player keeps it and its timer', () {
    final session = PlaybackSession();
    final player = FakePlayerController();
    final timer = SleepTimer(player);

    session.attach(player, testVideos.first, sleepTimer: timer);
    session.release(player);
    expect(session.minimized, isTrue);
    session.attach(player, testVideos.first, sleepTimer: timer);

    expect(player.disposed, isFalse);
    expect(session.attached, isTrue);
    timer.notifyListeners();
  });

  test('release only minimizes for the current player', () {
    final session = PlaybackSession();
    final player = FakePlayerController();
    session.attach(player, testVideos.first);

    session.release(FakePlayerController());
    expect(session.attached, isTrue);

    session.release(player);
    expect(session.attached, isFalse);
    expect(session.minimized, isTrue);
    expect(player.disposed, isFalse);
  });

  test('updateStream stores the selection without notifying', () {
    final session = PlaybackSession();
    var notified = 0;
    session.addListener(() => notified++);
    session.attach(FakePlayerController(), testVideos.first);
    notified = 0;

    session.updateStream(testStreams[1], testStreams[2]);
    expect(session.stream, testStreams[1]);
    expect(session.audio, testStreams[2]);
    expect(notified, 0);
  });

  test('stop is a no-op when empty', () async {
    final session = PlaybackSession();
    await session.stop();
    expect(session.player, isNull);
  });

  test('stop clears the session and disposes the player', () async {
    final controls = FakeMediaControls();
    final session = PlaybackSession(mediaControls: controls);
    final player = FakePlayerController();
    final timer = SleepTimer(player);

    session.attach(
      player,
      testVideos.first,
      playlist: const PlaylistInfo(
        id: 'pl1',
        title: 'Playlist',
        author: 'A',
        videoCount: 2,
        videos: testVideos,
      ),
      index: 1,
      stream: testStreams[1],
      audio: testStreams[2],
      sleepTimer: timer,
    );
    session.release(player);

    await session.stop();

    expect(session.player, isNull);
    expect(session.video, isNull);
    expect(session.playlist, isNull);
    expect(session.index, isNull);
    expect(session.stream, isNull);
    expect(session.audio, isNull);
    expect(session.sleepTimer, isNull);
    expect(session.minimized, isFalse);
    expect(player.disposed, isTrue);
    expect(controls.detaches, 1);
    expect(() => timer.notifyListeners(), throwsA(isA<FlutterError>()));
  });
}
