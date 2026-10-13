import 'dart:async';

import 'package:flutter/foundation.dart';

import 'player_controller.dart';

class SleepTimer extends ChangeNotifier {
  SleepTimer(this._player);

  final PlayerController _player;
  Timer? _timer;
  StreamSubscription<Duration>? _positionSub;
  Duration? _remaining;
  bool _endOfVideo = false;

  Duration? get remaining => _remaining;
  bool get endOfVideo => _endOfVideo;
  bool get active => _remaining != null || _endOfVideo;

  void startAfter(Duration duration) {
    _stop();
    _remaining = duration;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void startAtEndOfVideo() {
    _stop();
    _endOfVideo = true;
    _positionSub = _player.positionStream.listen(_checkEnd);
    _checkEnd(_player.position);
    notifyListeners();
  }

  void cancel() {
    _stop();
    notifyListeners();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _positionSub?.cancel();
    _positionSub = null;
    _remaining = null;
    _endOfVideo = false;
  }

  void _tick() {
    final left = _remaining;
    if (left == null) return;
    if (left <= const Duration(seconds: 1)) {
      _fire();
      return;
    }
    _remaining = left - const Duration(seconds: 1);
    notifyListeners();
  }

  void _checkEnd(Duration position) {
    final total = _player.duration;
    if (total > Duration.zero && position >= total) _fire();
  }

  void _fire() {
    _stop();
    _player.pause();
    notifyListeners();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}
