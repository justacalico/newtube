import 'package:flutter/widgets.dart';

import '../utils/debug_log.dart';
import 'player_controller.dart';

class UnsupportedPlayerController implements PlayerController {
  @override
  Duration get position => Duration.zero;
  @override
  Duration get duration => Duration.zero;
  @override
  bool get playing => false;
  @override
  bool get buffering => false;

  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration> get durationStream => const Stream.empty();
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  Stream<bool> get bufferingStream => const Stream.empty();

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
  @override
  Widget buildView(BuildContext context) => const SizedBox.shrink();
  @override
  Future<void> dispose() async {}
}
