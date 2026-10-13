import 'notifier_stub.dart' if (dart.library.io) 'notifier_io.dart' as impl;

typedef NotifyCallback = Future<void> Function(String title, String body);

// coverage:ignore-start
NotifyCallback? createNotifier() => impl.createNotifier();
// coverage:ignore-end
