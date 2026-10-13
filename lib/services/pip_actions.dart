import 'package:flutter/foundation.dart';

import 'pip_actions_stub.dart'
    if (dart.library.io) 'pip_actions_io.dart'
    as impl;

abstract class PipActions {
  ValueListenable<bool> get pipMode;
  Future<bool> enterPip();
  Future<void> exitPip();
}

// coverage:ignore-start
PipActions? createPipActions() => impl.createPipActions();
// coverage:ignore-end
