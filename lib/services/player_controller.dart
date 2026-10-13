import 'package:flutter/widgets.dart';

import 'player_factory_stub.dart'
    if (dart.library.html) 'player_factory_web.dart'
    if (dart.library.io) 'player_factory_io.dart'
    as player_factory;

abstract class PlayerController {
  Duration get position;
  Duration get duration;
  bool get playing;
  bool get buffering;
  double get rate;
  double get volume;
  bool get muted;

  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<bool> get playingStream;
  Stream<bool> get bufferingStream;
  Stream<double> get rateStream;
  Stream<double> get volumeStream;
  Stream<bool> get mutedStream;
  Stream<bool> get completedStream;

  Future<void> open(String url, {String? audioUrl});
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setRate(double rate);
  Future<void> setVolume(double volume);
  Future<void> setMuted(bool muted);
  Widget buildView(BuildContext context);
  Future<void> dispose();
}

// coverage:ignore-start
PlayerController createPlayerController() =>
    player_factory.createPlayerController();
// coverage:ignore-end
