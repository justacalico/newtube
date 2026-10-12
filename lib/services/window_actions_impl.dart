// coverage:ignore-file
import 'package:window_manager/window_manager.dart';

import 'window_actions.dart';

class WindowManagerActions implements WindowActions {
  @override
  Future<void> minimize() => windowManager.minimize();

  @override
  Future<void> toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Future<void> close() => windowManager.close();

  @override
  Future<void> startDrag() => windowManager.startDragging();
}
