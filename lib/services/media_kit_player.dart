// coverage:ignore-file
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../utils/debug_log.dart';
import 'player_controller.dart';

class MediaKitPlayerController implements PlayerController {
  final Player _player;
  late final VideoController _videoController;
  final _mutedChanges = StreamController<bool>.broadcast();
  bool _muted = false;
  double _unmutedVolume = 1.0;

  MediaKitPlayerController({Player? player}) : _player = player ?? Player() {
    _videoController = VideoController(_player);
  }

  @override
  Duration get position => _player.state.position;
  @override
  Duration get duration => _player.state.duration;
  @override
  bool get playing => _player.state.playing;
  @override
  bool get buffering => _player.state.buffering;
  @override
  Duration get buffered => _player.state.buffer;
  @override
  double get rate => _player.state.rate;
  @override
  double get volume => _player.state.volume / 100;
  @override
  bool get muted => _muted;

  @override
  final ValueNotifier<BoxFit> videoFit = ValueNotifier(BoxFit.contain);

  @override
  Stream<Duration> get positionStream => _player.stream.position;
  @override
  Stream<Duration> get durationStream => _player.stream.duration;
  @override
  Stream<bool> get playingStream => _player.stream.playing;
  @override
  Stream<bool> get bufferingStream => _player.stream.buffering;
  @override
  Stream<Duration> get bufferedStream => _player.stream.buffer;
  @override
  Stream<double> get rateStream => _player.stream.rate;
  @override
  Stream<double> get volumeStream => _player.stream.volume.map((v) => v / 100);
  @override
  Stream<bool> get mutedStream => _mutedChanges.stream;
  @override
  Stream<bool> get completedStream => _player.stream.completed;

  @override
  Future<void> open(String url, {String? audioUrl}) async {
    debugLog(
      '[player] open $url${audioUrl == null ? '' : ' + audio $audioUrl'}',
    );
    try {
      await _player.open(Media(url), play: false);
      if (audioUrl != null) {
        final platform = _player.platform;
        if (platform is NativePlayer) {
          await platform.command(['audio-add', audioUrl]);
        }
      }
      await _player.play();
    } catch (e) {
      debugLog('[player] open failed: $e');
      rethrow;
    }
    debugLog('[player] playing');
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position) {
    debugLog('[player] seek ${position.inSeconds}s');
    return _player.seek(position);
  }

  @override
  Future<void> setRate(double rate) => _player.setRate(rate);

  @override
  Future<void> setVolume(double volume) async {
    _unmutedVolume = volume.clamp(0.0, 1.0);
    if (!_muted) await _player.setVolume(_unmutedVolume * 100);
  }

  @override
  Future<void> setMuted(bool muted) async {
    if (_muted == muted) return;
    _muted = muted;
    await _player.setVolume(muted ? 0 : _unmutedVolume * 100);
    _mutedChanges.add(muted);
  }

  @override
  Future<void> setVideoEnabled(bool enabled) async {
    final platform = _player.platform;
    if (platform is NativePlayer) {
      await platform.setProperty('vid', enabled ? 'auto' : 'no');
    }
  }

  @override
  Widget buildView(BuildContext context) => ValueListenableBuilder<BoxFit>(
    valueListenable: videoFit,
    builder: (context, fit, _) => Video(
      controller: _videoController,
      controls: (_) => const SizedBox.shrink(),
      pauseUponEnteringBackgroundMode: false,
      fit: fit,
    ),
  );

  @override
  Future<void> dispose() {
    _mutedChanges.close();
    return _player.dispose();
  }
}
