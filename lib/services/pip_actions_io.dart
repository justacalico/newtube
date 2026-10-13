// coverage:ignore-file
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../ui/shell/title_bar.dart' show isDesktopPlatform;
import 'pip_actions.dart';

class _AndroidPipActions implements PipActions {
  static const _channel = MethodChannel('newtube/pip');

  @override
  Future<bool> enterPip() async =>
      (await _channel.invokeMethod<bool>('enterPip')) ?? false;

  @override
  Future<void> exitPip() async {}
}

class _DesktopPipActions implements PipActions {
  Size? _size;
  bool _active = false;

  @override
  Future<bool> enterPip() async {
    if (!_active) _size = await windowManager.getSize();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setMinimumSize(const Size(320, 180));
    await windowManager.setSize(const Size(480, 270));
    await windowManager.setAspectRatio(16 / 9);
    _active = true;
    return true;
  }

  @override
  Future<void> exitPip() async {
    if (!_active) return;
    _active = false;
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
