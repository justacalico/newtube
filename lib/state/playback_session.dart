import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/video_info.dart';
import '../services/media_controls.dart';
import '../services/player_controller.dart';
import '../services/sleep_timer.dart';

enum RepeatMode { off, all, one }

class PlaybackSession extends ChangeNotifier {
  PlaybackSession({this.mediaControls});

  final MediaControls? mediaControls;

  PlayerController? _player;
  VideoInfo? _video;
  PlaylistInfo? _playlist;
  int? _index;
  PlayableStream? _stream;
  PlayableStream? _audio;
  SleepTimer? _sleepTimer;
  bool _attached = false;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _shuffle = false;

  PlayerController? get player => _player;
  VideoInfo? get video => _video;
  PlaylistInfo? get playlist => _playlist;
  int? get index => _index;
  PlayableStream? get stream => _stream;
  PlayableStream? get audio => _audio;
  SleepTimer? get sleepTimer => _sleepTimer;

  bool get attached => _attached;
  bool get minimized => _player != null && !_attached;
  RepeatMode get repeatMode => _repeatMode;
  bool get shuffle => _shuffle;

  set repeatMode(RepeatMode value) {
    if (_repeatMode == value) return;
    _repeatMode = value;
    notifyListeners();
  }

  set shuffle(bool value) {
    if (_shuffle == value) return;
    _shuffle = value;
    notifyListeners();
  }

  void attach(
    PlayerController player,
    VideoInfo video, {
    PlaylistInfo? playlist,
    int? index,
    PlayableStream? stream,
    PlayableStream? audio,
    SleepTimer? sleepTimer,
  }) {
    final old = _player;
    final oldTimer = _sleepTimer;
    _player = player;
    _video = video;
    _playlist = playlist;
    _index = index;
    _stream = stream;
    _audio = audio;
    _sleepTimer = sleepTimer;
    _attached = true;
    if (old != null && !identical(old, player)) {
      unawaited(mediaControls?.detach(old));
      unawaited(old.dispose());
      if (!identical(oldTimer, sleepTimer)) oldTimer?.dispose();
    }
    notifyListeners();
  }

  void release(PlayerController player) {
    if (!identical(_player, player)) return;
    _attached = false;
    scheduleMicrotask(notifyListeners);
  }

  void updateStream(PlayableStream? stream, PlayableStream? audio) {
    _stream = stream;
    _audio = audio;
  }

  Future<void> stop() async {
    final player = _player;
    if (player == null) return;
    final timer = _sleepTimer;
    _player = null;
    _video = null;
    _playlist = null;
    _index = null;
    _stream = null;
    _audio = null;
    _sleepTimer = null;
    _attached = false;
    notifyListeners();
    unawaited(mediaControls?.detach(player));
    timer?.dispose();
    await player.dispose();
  }
}
