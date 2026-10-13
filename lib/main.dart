import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'services/file_saver.dart';
import 'services/innertube_api.dart';
import 'services/launcher.dart';
import 'services/mcp_server.dart';
import 'services/player_controller.dart';
import 'services/window_actions_impl.dart';
import 'services/youtube_explode_api.dart';
import 'state/app_state.dart';
import 'state/history_store.dart';
import 'state/search_history_store.dart';
import 'state/settings_store.dart';
import 'state/subscriptions_store.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

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
  final settings = await SettingsStore.load(prefs);
  return AppState(
    prefs: prefs,
    api:
        kIsWeb // coverage:ignore-start
        ? InnertubeApi(proxyPrefix: () => settings.proxyPrefix)
        : YouTubeExplodeApi(
            proxyPrefix: () => settings.proxyPrefix,
          ), // coverage:ignore-end
    isWeb: kIsWeb,
    settings: settings,
    subscriptions: await SubscriptionsStore.load(prefs),
    history: await HistoryStore.load(prefs),
    searchHistory: await SearchHistoryStore.load(prefs),
    launch: defaultLaunch,
    packageInfo: PackageInfo.fromPlatform,
    createPlayer: createPlayerController,
    windowActions: isDesktopPlatform ? WindowManagerActions() : null,
    createMcpServer: isDesktopPlatform ? createMcpServer : null,
    saveFile: isDesktopPlatform ? saveFileDialog : null,
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
