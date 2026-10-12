import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_update.dart';
import '../services/launcher.dart';
import '../services/player_controller.dart';
import '../services/version_checker.dart';
import '../services/window_actions.dart';
import '../services/youtube_api.dart';
import 'history_store.dart';
import 'settings_store.dart';
import 'subscriptions_store.dart';

class AppState extends ChangeNotifier {
  final SharedPreferences prefs;
  final YouTubeApi api;
  final WindowActions? windowActions;
  final SettingsStore settings;
  final SubscriptionsStore subscriptions;
  final HistoryStore history;
  final UrlLaunch launch;
  final Future<PackageInfo> Function() packageInfo;
  final PlayerController Function() createPlayer;
  final bool isWeb;

  int _tabIndex = 0;
  AppUpdate? _update;
  Future<AppUpdate?>? _updateCheck;
  VersionChecker? _versionChecker;

  AppState({
    required this.prefs,
    required this.api,
    required this.settings,
    required this.subscriptions,
    required this.history,
    required this.launch,
    required this.packageInfo,
    required this.createPlayer,
    this.windowActions,
    this._versionChecker,
    this.isWeb = false,
  });

  int get tabIndex => _tabIndex;

  void selectTab(int index) {
    if (index == _tabIndex) return;
    _tabIndex = index;
    notifyListeners();
  }

  AppUpdate? get update => _update;

  Future<AppUpdate?> checkForUpdate() {
    final existing = _updateCheck;
    if (existing != null) return existing;
    return _updateCheck = _runUpdateCheck().whenComplete(
      () => _updateCheck = null,
    );
  }

  Future<AppUpdate?> _runUpdateCheck() async {
    try {
      _versionChecker ??= VersionChecker();
      final info = await packageInfo();
      final update = await _versionChecker!.check(info.version);
      if (_update != update) {
        _update = update;
        notifyListeners();
      }
      return update;
    } catch (_) {
      return null;
    }
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<AppScope>()!.widget
              as AppScope)
          .notifier!;
}
