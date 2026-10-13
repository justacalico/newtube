// coverage:ignore-file
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';

import 'notifier.dart';

FlutterLocalNotificationsPlugin? _mobile;
var _desktopReady = false;

Future<void> _notifyMobile(String title, String body) async {
  final plugins = _mobile ??= FlutterLocalNotificationsPlugin();
  await plugins.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  await plugins
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();
  await plugins.show(
    id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'uploads',
        'Uploads',
        importance: Importance.defaultImportance,
      ),
      iOS: DarwinNotificationDetails(),
    ),
  );
}

Future<void> _notifyDesktop(String title, String body) async {
  if (!_desktopReady) {
    await localNotifier.setup(appName: 'NewTube');
    _desktopReady = true;
  }
  await LocalNotification(title: title, body: body).show();
}

NotifyCallback? createNotifier() {
  if (Platform.isAndroid || Platform.isIOS) return _notifyMobile;
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    return _notifyDesktop;
  }
  return null;
}
