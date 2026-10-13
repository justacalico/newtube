// coverage:ignore-file
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../utils/debug_log.dart';
import 'player_controller.dart';

class MediaKitPlayerController implements PlayerController {
  final Player _player;
  late final VideoController _videoController;

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
  double get rate => _player.state.rate;

  @override
  Stream<Duration> get positionStream => _player.stream.position;
  @override
  Stream<Duration> get durationStream => _player.stream.duration;
  @override
  Stream<bool> get playingStream => _player.stream.playing;
  @override
  Stream<bool> get bufferingStream => _player.stream.buffering;
  @override
  Stream<double> get rateStream => _player.stream.rate;

  @override
  Future<void> open(String url, {String? audioUrl}) async {
    debugLog(
      '[player] open $url${audioUrl == null ? '' : ' + audio $audioUrl'}',
    );
    try {
      await _player.open(Media(url), play: false);
      if (audioUrl != null &&
          (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
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
  Widget buildView(BuildContext context) =>
      Video(controller: _videoController, controls: NoVideoControls);

  @override
  Future<void> dispose() => _player.dispose();
}
