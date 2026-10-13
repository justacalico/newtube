// coverage:ignore-file
import 'dart:async';

import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../utils/debug_log.dart';
import 'player_controller.dart';

class WebPlayerController implements PlayerController {
  final _viewType = 'newtube-player-${_nextId++}';
  static int _nextId = 0;

  final _video = web.HTMLVideoElement()
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.backgroundColor = 'black';
  late final web.HTMLAudioElement _audio;
  bool _audioAttached = false;

  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _buffering = StreamController<bool>.broadcast();
  final _rateChanges = StreamController<double>.broadcast();
  final _volumeChanges = StreamController<double>.broadcast();
  final _mutedChanges = StreamController<bool>.broadcast();
  double _rate = 1.0;

  Timer? _poll;
  bool _lastPlaying = false;
  bool _lastBuffering = true;
  Duration _lastDuration = Duration.zero;

  WebPlayerController() {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) => _video);
    _video.onError.listen(
      (_) => debugLog('[player] video error: ${_video.error?.message}'),
    );
    _video.onVolumeChange.listen((_) {
      _volumeChanges.add(_video.volume.toDouble());
      _mutedChanges.add(_video.muted);
    });
  }

  @override
  Duration get position =>
      Duration(milliseconds: (_video.currentTime * 1000).round());

  @override
  Duration get duration => _video.duration.isFinite
      ? Duration(milliseconds: (_video.duration * 1000).round())
      : Duration.zero;

  @override
  bool get playing => !_video.paused;

  @override
  bool get buffering => playing && _video.readyState < 3;

  @override
  double get rate => _rate;

  @override
  double get volume => _video.volume.toDouble();

  @override
  bool get muted => _video.muted;

  @override
  Stream<Duration> get positionStream => _position.stream;
  @override
  Stream<Duration> get durationStream => _duration.stream;
  @override
  Stream<bool> get playingStream => _playing.stream;
  @override
  Stream<bool> get bufferingStream => _buffering.stream;
  @override
  Stream<double> get rateStream => _rateChanges.stream;
  @override
  Stream<double> get volumeStream => _volumeChanges.stream;
  @override
  Stream<bool> get mutedStream => _mutedChanges.stream;

  void _syncAudio() {
    if (!_audioAttached) return;
    final diff = (_audio.currentTime - _video.currentTime).abs();
    if (diff > 0.3) _audio.currentTime = _video.currentTime;
    if (playing && _audio.paused) {
      _audio.play();
    } else if (!playing && !_audio.paused) {
      _audio.pause();
    }
  }

  void _tick() {
    _position.add(position);
    final d = duration;
    if (d != _lastDuration) {
      _lastDuration = d;
      _duration.add(d);
    }
    final p = playing;
    if (p != _lastPlaying) {
      _lastPlaying = p;
      debugLog('[player] playing=$p');
      _playing.add(p);
    }
    final b = buffering;
    if (b != _lastBuffering) {
      _lastBuffering = b;
      debugLog('[player] buffering=$b');
      _buffering.add(b);
    }
    _syncAudio();
  }

  @override
  Future<void> open(String url, {String? audioUrl}) async {
    debugLog(
      '[player] open $url${audioUrl == null ? '' : ' + audio $audioUrl'}',
    );
    _video.src = url;
    _video.playbackRate = _rate;
    _video.defaultPlaybackRate = _rate;
    if (audioUrl != null) {
      _audio = web.HTMLAudioElement()
        ..src = audioUrl
        ..volume = _video.volume
        ..muted = _video.muted;
      _audioAttached = true;
    }
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  @override
  Future<void> play() async {
    _video.play();
    if (_audioAttached) _audio.play();
  }

  @override
  Future<void> pause() async {
    _video.pause();
    if (_audioAttached) _audio.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    debugLog('[player] seek ${position.inSeconds}s');
    _video.currentTime = position.inMilliseconds / 1000;
    if (_audioAttached) {
      _audio.currentTime = _video.currentTime;
    }
    _position.add(this.position);
  }

  @override
  Future<void> setRate(double rate) async {
    _rate = rate;
    _video.playbackRate = rate;
    _video.defaultPlaybackRate = rate;
    if (_audioAttached) {
      _audio.playbackRate = rate;
      _audio.defaultPlaybackRate = rate;
    }
    _rateChanges.add(rate);
  }

  @override
  Future<void> setVolume(double volume) async {
    _video.volume = volume.clamp(0.0, 1.0);
    if (_audioAttached) _audio.volume = _video.volume;
  }

  @override
  Future<void> setMuted(bool muted) async {
    _video.muted = muted;
    if (_audioAttached) _audio.muted = muted;
  }

  @override
  Widget buildView(BuildContext context) =>
      HtmlElementView(viewType: _viewType);

  @override
  Future<void> dispose() async {
    _poll?.cancel();
    _video.pause();
    _video.removeAttribute('src');
    _video.load();
    if (_audioAttached) {
      _audio.pause();
      _audio.removeAttribute('src');
    }
    await Future.wait([
      _position.close(),
      _duration.close(),
      _playing.close(),
      _buffering.close(),
      _rateChanges.close(),
      _volumeChanges.close(),
      _mutedChanges.close(),
    ]);
  }
}
