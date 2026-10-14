// coverage:ignore-file
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../ui/shell/title_bar.dart' show isDesktopPlatform;
import 'pip_actions.dart';
import 'player_controller.dart';

class _AndroidPipActions implements PipActions {
  static const _channel = MethodChannel('newtube/pip');

  final _pipMode = ValueNotifier<bool>(false);

  _AndroidPipActions() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'pipModeChanged') {
        _pipMode.value = call.arguments == true;
      }
    });
  }

  @override
  ValueListenable<bool> get pipMode => _pipMode;

  @override
  Future<bool> enterPip() async =>
      (await _channel.invokeMethod<bool>('enterPip')) ?? false;

  @override
  Future<void> exitPip() async {}

  @override
  void updatePlayback(
    PlayerController? player, {
    String? url,
    String? audioUrl,
  }) {}
}

class _IosPipActions implements PipActions {
  static const _channel = MethodChannel('newtube/pip');

  final _pipMode = ValueNotifier<bool>(false);
  late final AppLifecycleListener lifecycle;

  PlayerController? _player;
  String? _url;
  String? _audioUrl;

  _IosPipActions() {
    _channel.setMethodCallHandler(_handle);
    lifecycle = AppLifecycleListener(onResume: _resync);
  }

  @override
  ValueListenable<bool> get pipMode => _pipMode;

  @override
  void updatePlayback(
    PlayerController? player, {
    String? url,
    String? audioUrl,
  }) {
    _player = player;
    _url = url;
    _audioUrl = audioUrl;
  }

  @override
  Future<bool> enterPip() async {
    final url = _url;
    final player = _player;
    if (_pipMode.value || url == null || player == null) return _pipMode.value;
    return await _channel.invokeMethod<bool>('enterPip', {
          'url': url,
          'audioUrl': _audioUrl,
          'position': player.position.inMilliseconds / 1000,
          'rate': player.rate,
          'playing': player.playing,
        }) ??
        false;
  }

  @override
  Future<void> exitPip() async {
    await _channel.invokeMethod<void>('exitPip');
  }

  Future<void> _resync() async {
    final active = await _channel.invokeMethod<bool>('isPipActive') ?? false;
    if (active == _pipMode.value) return;
    await _pipChanged(active, null);
  }

  Future<void> _handle(MethodCall call) async {
    if (call.method != 'pipModeChanged') return;
    final args = call.arguments;
    await _pipChanged(
      args is Map ? args['active'] == true : args == true,
      args,
    );
  }

  Future<void> _pipChanged(bool active, Object? args) async {
    _pipMode.value = active;
    final player = _player;
    if (player == null) return;
    if (active) {
      await player.pause();
      return;
    }
    var position = args is Map ? (args['position'] as num?)?.toDouble() : null;
    position ??= await _channel.invokeMethod<double>('pipPosition');
    if (position != null) {
      await player.seek(Duration(milliseconds: (position * 1000).round()));
    }
    final playing = args is Map ? args['playing'] == true : true;
    if (playing) await player.play();
  }
}

class _DesktopPipActions implements PipActions {
  final _pipMode = ValueNotifier<bool>(false);
  Size? _size;
  bool _active = false;

  @override
  ValueListenable<bool> get pipMode => _pipMode;

  @override
  Future<bool> enterPip() async {
    if (!_active) _size = await windowManager.getSize();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setMinimumSize(const Size(320, 180));
    await windowManager.setSize(const Size(480, 270));
    await windowManager.setAspectRatio(16 / 9);
    _active = true;
    _pipMode.value = true;
    return true;
  }

  @override
  Future<void> exitPip() async {
    if (!_active) return;
    _active = false;
    _pipMode.value = false;
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setAspectRatio(0);
    await windowManager.setMinimumSize(const Size(400, 300));
    final size = _size;
    if (size != null) await windowManager.setSize(size);
  }

  @override
  void updatePlayback(
    PlayerController? player, {
    String? url,
    String? audioUrl,
  }) {}
}

PipActions? createPipActions() {
  if (Platform.isAndroid) return _AndroidPipActions();
  if (Platform.isIOS) return _IosPipActions();
  if (isDesktopPlatform) return _DesktopPipActions();
  return null;
}
