// coverage:ignore-file
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../ui/shell/title_bar.dart' show isDesktopPlatform;
import 'pip_actions.dart';

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
}

PipActions? createPipActions() {
  if (Platform.isAndroid) return _AndroidPipActions();
  if (isDesktopPlatform) return _DesktopPipActions();
  return null;
}
