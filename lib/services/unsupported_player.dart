import 'package:flutter/widgets.dart';

import '../utils/debug_log.dart';
import 'player_controller.dart';

class UnsupportedPlayerController implements PlayerController {
  @override
  Duration get position => Duration.zero;
  @override
  Duration get duration => Duration.zero;
  @override
  Duration get buffered => Duration.zero;
  @override
  bool get playing => false;
  @override
  bool get buffering => false;
  @override
  double get rate => 1.0;
  @override
  double get volume => 1.0;
  @override
  bool get muted => false;
  @override
  final ValueNotifier<BoxFit> videoFit = ValueNotifier(BoxFit.contain);

  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration> get durationStream => const Stream.empty();
  @override
  Stream<Duration> get bufferedStream => const Stream.empty();
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  Stream<bool> get bufferingStream => const Stream.empty();
  @override
  Stream<double> get rateStream => const Stream.empty();
  @override
  Stream<double> get volumeStream => const Stream.empty();
  @override
  Stream<bool> get mutedStream => const Stream.empty();
  @override
  Stream<bool> get completedStream => const Stream.empty();

  @override
  Future<void> open(String url, {String? audioUrl}) async {
    debugLog('[player] playback unsupported on this platform: $url');
  }

  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> setRate(double rate) async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> setMuted(bool muted) async {}
  @override
  Future<void> setVideoEnabled(bool enabled) async {}
  @override
  Widget buildView(BuildContext context) => const SizedBox.shrink();
  @override
  Future<void> dispose() async {}
}
