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
  bool _audioOnly = false;
  double? _lastRate;
  final List<VideoInfo> _queue = [];
  final List<VideoInfo> _playedBefore = [];

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
  bool get audioOnly => _audioOnly;
  double? get lastRate => _lastRate;
  List<VideoInfo> get queue => List.unmodifiable(_queue);

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

  set audioOnly(bool value) {
    if (_audioOnly == value) return;
    _audioOnly = value;
    notifyListeners();
  }

  set lastRate(double? value) {
    if (_lastRate == value) return;
    _lastRate = value;
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

  void enqueue(VideoInfo video) {
    _queue.add(video);
    notifyListeners();
  }

  void playNext(VideoInfo video) {
    _queue.insert(0, video);
    notifyListeners();
  }

  VideoInfo? takeNext() {
    if (_queue.isEmpty) return null;
    final current = _video;
    if (current != null) _playedBefore.add(current);
    final next = _queue.removeAt(0);
    notifyListeners();
    return next;
  }

  VideoInfo? takePrevious() {
    if (_playedBefore.isEmpty) return null;
    final prev = _playedBefore.removeLast();
    final current = _video;
    if (current != null) _queue.insert(0, current);
    notifyListeners();
    return prev;
  }

  bool get hasPrevious => _playedBefore.isNotEmpty;
  bool get hasNext => _queue.isNotEmpty;

  VideoInfo? takeNextFrom(int index) {
    if (index < 0 || index >= _queue.length) return null;
    final current = _video;
    if (current != null) _playedBefore.add(current);
    final next = _queue.removeAt(index);
    notifyListeners();
    return next;
  }

  void removeQueued(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    notifyListeners();
  }

  void moveQueued(int from, int to) {
    if (from < 0 || from >= _queue.length) return;
    if (to < 0 || to >= _queue.length) return;
    final item = _queue.removeAt(from);
    _queue.insert(to, item);
    notifyListeners();
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
