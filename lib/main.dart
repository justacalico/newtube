import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'services/brightness.dart';
import 'services/file_saver.dart';
import 'services/innertube_api.dart';
import 'services/launcher.dart';
import 'services/links.dart';
import 'services/mcp_server.dart';
import 'services/dearrow.dart';
import 'services/dearrow_api.dart';
import 'services/downloads.dart';
import 'services/fallback_api.dart';
import 'services/youtube_api.dart';
import 'services/invidious_api.dart';
import 'services/network_proxy.dart';
import 'services/file_opener.dart';
import 'services/media_controls.dart';
import 'services/pip_actions.dart';
import 'services/player_controller.dart';
import 'services/ryd.dart';
import 'services/share.dart';
import 'services/notifier.dart';
import 'services/orientation.dart';
import 'services/sponsor_block.dart';
import 'services/uploads_watcher.dart';
import 'services/window_actions_impl.dart';
import 'services/youtube_explode_api.dart';
import 'state/app_state.dart';
import 'state/downloads_store.dart';
import 'state/history_store.dart';
import 'state/playlists_store.dart';
import 'state/search_history_store.dart';
import 'state/settings_store.dart';
import 'state/subscriptions_store.dart';
import 'state/hidden_store.dart';
import 'state/watch_later_store.dart';

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

YouTubeApi _primaryApi(SettingsStore settings) {
  // coverage:ignore-start
  final client = proxyHttpClient(settings.networkProxy);
  final base = kIsWeb
      ? InnertubeApi(
          proxyPrefix: () => settings.proxyPrefix,
          httpClient: client,
        )
      : YouTubeExplodeApi(
          proxyPrefix: () => settings.proxyPrefix,
          httpClient: client,
        );
  if (settings.fallbackBackend.isNotEmpty) {
    return FallbackApi(base, InvidiousApi(instance: settings.fallbackBackend));
  }
  return base;
  // coverage:ignore-end
}

Future<AppState> createAppState(SharedPreferences prefs) async {
  final settings = await SettingsStore.load(prefs);
  final subscriptions = await SubscriptionsStore.load(prefs);
  return AppState(
    prefs: prefs,
    api: DeArrowApi(
      settings: settings,
      client: DeArrowClient(),
      inner: _primaryApi(settings),
    ),
    isWeb: kIsWeb,
    settings: settings,
    subscriptions: subscriptions,
    watchLater: await WatchLaterStore.load(prefs),
    hidden: await HiddenStore.load(prefs),
    playlists: await PlaylistsStore.load(prefs),
    history: await HistoryStore.load(prefs),
    searchHistory: await SearchHistoryStore.load(prefs),
    launch: defaultLaunch,
    packageInfo: PackageInfo.fromPlatform,
    createPlayer: createPlayerController,
    windowActions: isDesktopPlatform ? WindowManagerActions() : null,
    createMcpServer: isDesktopPlatform ? createMcpServer : null,
    saveFile: isDesktopPlatform ? saveFileDialog : null,
    downloads: kIsWeb
        ? null
        : NetDownloadActions(http.Client(), saveFileDialog),
    // coverage:ignore-line
    downloadsStore: await DownloadsStore.load(prefs),
    openFile: kIsWeb ? null : openTextFileDialog,
    sponsorBlock: SponsorBlockClient(),
    // coverage:ignore-line
    ryd: kIsWeb ? null : RydClient(),
    // coverage:ignore-line
    share: isDesktopPlatform || kIsWeb
        ? ClipboardShareActions() // coverage:ignore-line
        : SheetShareActions(), // coverage:ignore-line
    links: AppLinksActions(), // coverage:ignore-line
    // coverage:ignore-line
    pipActions: kIsWeb ? null : createPipActions(),
    // coverage:ignore-line
    orientation: isDesktopPlatform || kIsWeb
        ? null
        : const OrientationActions(),
    // coverage:ignore-line
    mediaControls: kIsWeb ? null : createMediaControls(),
    // coverage:ignore-line
    brightness: kIsWeb ? null : createBrightness(),
    uploads: switch (createNotifier()) {
      // coverage:ignore-line
      null => null,
      final notify => UploadsWatcher(
        prefs: prefs,
        subscriptions: subscriptions,
        notify: notify,
      )..attach(settings),
    },
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
