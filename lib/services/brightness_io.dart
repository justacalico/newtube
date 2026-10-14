// coverage:ignore-file
import 'dart:io';

import 'package:flutter/services.dart';

import 'brightness.dart';

class _ChannelBrightness implements BrightnessControl {
  static const _channel = MethodChannel('newtube/brightness');

  @override
  Future<double> getBrightness() async =>
      await _channel.invokeMethod<double>('getBrightness') ?? 1.0;

  @override
  Future<void> setBrightness(double value) =>
      _channel.invokeMethod<void>('setBrightness', value.clamp(0.0, 1.0));
}

BrightnessControl? createBrightness() {
  if (Platform.isAndroid || Platform.isIOS) return _ChannelBrightness();
  return null;
}
