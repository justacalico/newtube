import 'package:flutter/services.dart';

class OrientationActions {
  const OrientationActions();

  Future<void> landscape() => SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  Future<void> restore() =>
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
}
