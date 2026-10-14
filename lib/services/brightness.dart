import 'brightness_stub.dart' if (dart.library.io) 'brightness_io.dart' as impl;

abstract class BrightnessControl {
  Future<double> getBrightness();
  Future<void> setBrightness(double value);
}

// coverage:ignore-start
BrightnessControl? createBrightness() => impl.createBrightness();
// coverage:ignore-end
