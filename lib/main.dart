import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'services/launcher.dart';
import 'services/player_controller.dart';
import 'services/window_actions_impl.dart';
import 'services/youtube_explode_api.dart';
import 'state/app_state.dart';
import 'state/history_store.dart';
import 'state/settings_store.dart';
import 'state/subscriptions_store.dart';
import 'ui/shell/title_bar.dart' show isDesktopPlatform;

// coverage:ignore-start
Future<void> _initWindow() async {
  await windowManager.ensureInitialized();
  const options = WindowOptions(
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
// coverage:ignore-end

Future<AppState> createAppState(SharedPreferences prefs) async {
  return AppState(
    prefs: prefs,
    api: YouTubeExplodeApi(),
    settings: await SettingsStore.load(prefs),
    subscriptions: await SubscriptionsStore.load(prefs),
    history: await HistoryStore.load(prefs),
    launch: defaultLaunch,
    packageInfo: PackageInfo.fromPlatform,
    createPlayer: createPlayerController,
    windowActions: isDesktopPlatform ? WindowManagerActions() : null,
  );
}

// coverage:ignore-start
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  if (isDesktopPlatform) {
    await _initWindow();
  }
  final prefs = await SharedPreferences.getInstance();
  final state = await createAppState(prefs);
  runApp(AppScope(state: state, child: const NewtubeApp()));
}
// coverage:ignore-end
