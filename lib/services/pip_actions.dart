import 'pip_actions_stub.dart'
    if (dart.library.io) 'pip_actions_io.dart'
    as impl;

abstract class PipActions {
  Future<bool> enterPip();
  Future<void> exitPip();
}

// coverage:ignore-start
PipActions? createPipActions() => impl.createPipActions();
// coverage:ignore-end
