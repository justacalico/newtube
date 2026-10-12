import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const supportedLocales = [
  Locale('en', 'GB'),
  Locale('zh', 'Hans'),
  Locale('ru'),
  Locale('ga'),
];

enum AppTheme { system, light, dark, oled }

class SettingsStore extends ChangeNotifier {
  static const _themeKey = 'theme';
  static const _localeKey = 'locale';
  static const _autoplayKey = 'autoplay';
  static const _proxyPrefixKey = 'proxy_prefix';
  static const _searchHistoryKey = 'search_history_enabled';

  AppTheme _theme;
  Locale? _locale;
  bool _autoplay;
  String _proxyPrefix;
  bool _searchHistoryEnabled;

  SettingsStore({
    this._theme = AppTheme.system,
    this._locale,
    this._autoplay = true,
    this._proxyPrefix = '',
    this._searchHistoryEnabled = true,
  });

  static Future<SettingsStore> load(SharedPreferences prefs) async {
    return SettingsStore(
      theme:
          AppTheme.values.asNameMap()[prefs.getString(_themeKey)] ??
          AppTheme.system,
      locale: _parseLocale(prefs.getString(_localeKey)),
      autoplay: prefs.getBool(_autoplayKey) ?? true,
      proxyPrefix: prefs.getString(_proxyPrefixKey) ?? '',
      searchHistoryEnabled: prefs.getBool(_searchHistoryKey) ?? true,
    );
  }

  static Locale? _parseLocale(String? value) {
    if (value == null || value == 'system') return null;
    for (final locale in supportedLocales) {
      if (_localeString(locale) == value) return locale;
    }
    return null;
  }

  static String _localeString(Locale? locale) => locale == null
      ? 'system'
      : locale.countryCode == null
      ? locale.languageCode
      : '${locale.languageCode}_${locale.countryCode}';

  AppTheme get theme => _theme;
  Locale? get locale => _locale;
  bool get autoplay => _autoplay;
  String get proxyPrefix => _proxyPrefix;
  bool get searchHistoryEnabled => _searchHistoryEnabled;

  Future<void> setTheme(AppTheme theme, SharedPreferences prefs) async {
    _theme = theme;
    await prefs.setString(_themeKey, theme.name);
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale, SharedPreferences prefs) async {
    _locale = locale;
    await prefs.setString(_localeKey, _localeString(locale));
    notifyListeners();
  }

  Future<void> setProxyPrefix(String value, SharedPreferences prefs) async {
    _proxyPrefix = value.trim();
    await prefs.setString(_proxyPrefixKey, _proxyPrefix);
    notifyListeners();
  }

  Future<void> setAutoplay(bool value, SharedPreferences prefs) async {
    _autoplay = value;
    await prefs.setBool(_autoplayKey, value);
    notifyListeners();
  }

  Future<void> setSearchHistoryEnabled(
    bool value,
    SharedPreferences prefs,
  ) async {
    _searchHistoryEnabled = value;
    await prefs.setBool(_searchHistoryKey, value);
    notifyListeners();
  }
}
