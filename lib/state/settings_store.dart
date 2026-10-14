import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const supportedLocales = [
  Locale('en', 'GB'),
  Locale('zh', 'Hans'),
  Locale('ru'),
  Locale('ga'),
];

enum AppTheme { system, light, dark, oled }

enum DeArrowMode { off, titles, thumbnails, both }

class SettingsStore extends ChangeNotifier {
  static const _themeKey = 'theme';
  static const _localeKey = 'locale';
  static const _autoplayKey = 'autoplay';
  static const _proxyPrefixKey = 'proxy_prefix';
  static const _networkProxyKey = 'network_proxy';
  static const _searchHistoryKey = 'search_history_enabled';
  static const _mcpEnabledKey = 'mcp_enabled';
  static const _sidebarCollapsedKey = 'sidebar_collapsed';
  static const _sponsorBlockKey = 'sponsorblock_enabled';
  static const _rydKey = 'ryd_enabled';
  static const _sponsorBlockAutoSkipKey = 'sponsorblock_autoskip';
  static const _sponsorBlockCategoriesKey = 'sponsorblock_categories';
  static const _deArrowModeKey = 'dearrow_mode';
  static const _uploadNotifyKey = 'upload_notify';
  static const _uploadIntervalKey = 'upload_interval';
  static const _captionsEnabledKey = 'captions_enabled';
  static const _captionLanguageKey = 'caption_language';
  static const _audioOnlyKey = 'audio_only';
  static const _hideShortsKey = 'hide_shorts';
  static const _hideWatchedKey = 'hide_watched';
  static const _preferredQualityKey = 'preferred_quality';
  static const _preferredCodecKey = 'preferred_codec';
  static const _defaultSpeedKey = 'default_speed';
  static const defaultSponsorBlockCategories = {'sponsor', 'selfpromo'};

  AppTheme _theme;
  Locale? _locale;
  bool _autoplay;
  String _proxyPrefix;
  String _networkProxy;
  bool _searchHistoryEnabled;
  bool _mcpEnabled;
  bool _sidebarCollapsed;
  bool _sponsorBlockEnabled;
  bool _rydEnabled;
  bool _sponsorBlockAutoSkip;
  Set<String> _sponsorBlockCategories;
  DeArrowMode _deArrowMode;
  bool _uploadNotificationsEnabled;
  int _uploadCheckIntervalMinutes;
  bool _captionsEnabled;
  String _captionLanguage;
  bool _audioOnly;
  bool _hideShorts;
  bool _hideWatched;
  int _preferredQuality;
  int _preferredCodec;
  double _defaultSpeed;

  SettingsStore({
    this._theme = AppTheme.system,
    this._locale,
    this._autoplay = true,
    this._proxyPrefix = '',
    this._networkProxy = '',
    this._searchHistoryEnabled = true,
    this._mcpEnabled = false,
    this._sidebarCollapsed = false,
    this._sponsorBlockEnabled = false,
    this._rydEnabled = false,
    this._sponsorBlockAutoSkip = true,
    Set<String>? sponsorBlockCategories,
    this._deArrowMode = DeArrowMode.off,
    this._uploadNotificationsEnabled = false,
    this._uploadCheckIntervalMinutes = 30,
    this._captionsEnabled = false,
    this._captionLanguage = '',
    this._audioOnly = false,
    this._hideShorts = false,
    this._hideWatched = false,
    this._preferredQuality = 0,
    this._preferredCodec = 0,
    this._defaultSpeed = 1.0,
  }) : _sponsorBlockCategories =
           sponsorBlockCategories ?? Set.of(defaultSponsorBlockCategories);

  static Future<SettingsStore> load(SharedPreferences prefs) async {
    return SettingsStore(
      theme:
          AppTheme.values.asNameMap()[prefs.getString(_themeKey)] ??
          AppTheme.system,
      locale: _parseLocale(prefs.getString(_localeKey)),
      autoplay: prefs.getBool(_autoplayKey) ?? true,
      proxyPrefix: prefs.getString(_proxyPrefixKey) ?? '',
      networkProxy: prefs.getString(_networkProxyKey) ?? '',
      searchHistoryEnabled: prefs.getBool(_searchHistoryKey) ?? true,
      mcpEnabled: prefs.getBool(_mcpEnabledKey) ?? false,
      sidebarCollapsed: prefs.getBool(_sidebarCollapsedKey) ?? false,
      sponsorBlockEnabled: prefs.getBool(_sponsorBlockKey) ?? false,
      rydEnabled: prefs.getBool(_rydKey) ?? false,
      sponsorBlockAutoSkip: prefs.getBool(_sponsorBlockAutoSkipKey) ?? true,
      sponsorBlockCategories: prefs
          .getStringList(_sponsorBlockCategoriesKey)
          ?.toSet(),
      deArrowMode:
          DeArrowMode.values.asNameMap()[prefs.getString(_deArrowModeKey)] ??
          DeArrowMode.off,
      uploadNotificationsEnabled: prefs.getBool(_uploadNotifyKey) ?? false,
      uploadCheckIntervalMinutes:
          const {15, 30, 60, 120}.contains(prefs.getInt(_uploadIntervalKey))
          ? prefs.getInt(_uploadIntervalKey)!
          : 30,
      captionsEnabled: prefs.getBool(_captionsEnabledKey) ?? false,
      captionLanguage: prefs.getString(_captionLanguageKey) ?? '',
      audioOnly: prefs.getBool(_audioOnlyKey) ?? false,
      hideShorts: prefs.getBool(_hideShortsKey) ?? false,
      hideWatched: prefs.getBool(_hideWatchedKey) ?? false,
      preferredQuality: prefs.getInt(_preferredQualityKey) ?? 0,
      preferredCodec: prefs.getInt(_preferredCodecKey) ?? 0,
      defaultSpeed: prefs.getDouble(_defaultSpeedKey) ?? 1.0,
    );
  }

  Future<void> reload(SharedPreferences prefs) async {
    final fresh = await SettingsStore.load(prefs);
    _theme = fresh._theme;
    _locale = fresh._locale;
    _autoplay = fresh._autoplay;
    _proxyPrefix = fresh._proxyPrefix;
    _networkProxy = fresh._networkProxy;
    _searchHistoryEnabled = fresh._searchHistoryEnabled;
    _mcpEnabled = fresh._mcpEnabled;
    _sidebarCollapsed = fresh._sidebarCollapsed;
    _sponsorBlockEnabled = fresh._sponsorBlockEnabled;
    _rydEnabled = fresh._rydEnabled;
    _sponsorBlockAutoSkip = fresh._sponsorBlockAutoSkip;
    _sponsorBlockCategories = fresh._sponsorBlockCategories;
    _deArrowMode = fresh._deArrowMode;
    _uploadNotificationsEnabled = fresh._uploadNotificationsEnabled;
    _uploadCheckIntervalMinutes = fresh._uploadCheckIntervalMinutes;
    _captionsEnabled = fresh._captionsEnabled;
    _captionLanguage = fresh._captionLanguage;
    _audioOnly = fresh._audioOnly;
    _hideShorts = fresh._hideShorts;
    _hideWatched = fresh._hideWatched;
    _preferredQuality = fresh._preferredQuality;
    _preferredCodec = fresh._preferredCodec;
    _defaultSpeed = fresh._defaultSpeed;
    notifyListeners();
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
  String get networkProxy => _networkProxy;
  bool get searchHistoryEnabled => _searchHistoryEnabled;
  bool get mcpEnabled => _mcpEnabled;
  bool get sidebarCollapsed => _sidebarCollapsed;
  bool get sponsorBlockEnabled => _sponsorBlockEnabled;
  bool get rydEnabled => _rydEnabled;
  bool get sponsorBlockAutoSkip => _sponsorBlockAutoSkip;
  Set<String> get sponsorBlockCategories => _sponsorBlockCategories;
  DeArrowMode get deArrowMode => _deArrowMode;
  bool get deArrowTitles =>
      _deArrowMode == DeArrowMode.titles || _deArrowMode == DeArrowMode.both;
  bool get deArrowThumbnails =>
      _deArrowMode == DeArrowMode.thumbnails ||
      _deArrowMode == DeArrowMode.both;
  bool get uploadNotificationsEnabled => _uploadNotificationsEnabled;
  int get uploadCheckIntervalMinutes => _uploadCheckIntervalMinutes;
  bool get captionsEnabled => _captionsEnabled;
  String get captionLanguage => _captionLanguage;
  bool get audioOnly => _audioOnly;
  bool get hideShorts => _hideShorts;
  bool get hideWatched => _hideWatched;
  int get preferredQuality => _preferredQuality;
  int get preferredCodec => _preferredCodec;
  double get defaultSpeed => _defaultSpeed;

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

  Future<void> setNetworkProxy(String value, SharedPreferences prefs) async {
    _networkProxy = value.trim();
    await prefs.setString(_networkProxyKey, _networkProxy);
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

  Future<void> setMcpEnabled(bool value, SharedPreferences prefs) async {
    _mcpEnabled = value;
    await prefs.setBool(_mcpEnabledKey, value);
    notifyListeners();
  }

  Future<void> setSidebarCollapsed(bool value, SharedPreferences prefs) async {
    _sidebarCollapsed = value;
    await prefs.setBool(_sidebarCollapsedKey, value);
    notifyListeners();
  }

  Future<void> setRydEnabled(bool value, SharedPreferences prefs) async {
    _rydEnabled = value;
    await prefs.setBool(_rydKey, value);
    notifyListeners();
  }

  Future<void> setSponsorBlockEnabled(
    bool value,
    SharedPreferences prefs,
  ) async {
    _sponsorBlockEnabled = value;
    await prefs.setBool(_sponsorBlockKey, value);
    notifyListeners();
  }

  Future<void> setSponsorBlockAutoSkip(
    bool value,
    SharedPreferences prefs,
  ) async {
    _sponsorBlockAutoSkip = value;
    await prefs.setBool(_sponsorBlockAutoSkipKey, value);
    notifyListeners();
  }

  Future<void> setSponsorBlockCategories(
    Set<String> value,
    SharedPreferences prefs,
  ) async {
    _sponsorBlockCategories = Set.of(value);
    await prefs.setStringList(
      _sponsorBlockCategoriesKey,
      _sponsorBlockCategories.toList(),
    );
    notifyListeners();
  }

  Future<void> setDeArrowMode(
    DeArrowMode value,
    SharedPreferences prefs,
  ) async {
    _deArrowMode = value;
    await prefs.setString(_deArrowModeKey, value.name);
    notifyListeners();
  }

  Future<void> setUploadNotificationsEnabled(
    bool value,
    SharedPreferences prefs,
  ) async {
    _uploadNotificationsEnabled = value;
    await prefs.setBool(_uploadNotifyKey, value);
    notifyListeners();
  }

  Future<void> setUploadCheckIntervalMinutes(
    int value,
    SharedPreferences prefs,
  ) async {
    _uploadCheckIntervalMinutes = value;
    await prefs.setInt(_uploadIntervalKey, value);
    notifyListeners();
  }

  Future<void> setCaptionsEnabled(bool value, SharedPreferences prefs) async {
    _captionsEnabled = value;
    await prefs.setBool(_captionsEnabledKey, value);
    notifyListeners();
  }

  Future<void> setDefaultSpeed(double value, SharedPreferences prefs) async {
    _defaultSpeed = value;
    await prefs.setDouble(_defaultSpeedKey, value);
    notifyListeners();
  }

  Future<void> setPreferredQuality(int value, SharedPreferences prefs) async {
    _preferredQuality = value;
    await prefs.setInt(_preferredQualityKey, value);
    notifyListeners();
  }

  Future<void> setPreferredCodec(int value, SharedPreferences prefs) async {
    _preferredCodec = value;
    await prefs.setInt(_preferredCodecKey, value);
    notifyListeners();
  }

  Future<void> setAudioOnly(bool value, SharedPreferences prefs) async {
    _audioOnly = value;
    await prefs.setBool(_audioOnlyKey, value);
    notifyListeners();
  }

  Future<void> setHideShorts(bool value, SharedPreferences prefs) async {
    _hideShorts = value;
    await prefs.setBool(_hideShortsKey, value);
    notifyListeners();
  }

  Future<void> setHideWatched(bool value, SharedPreferences prefs) async {
    _hideWatched = value;
    await prefs.setBool(_hideWatchedKey, value);
    notifyListeners();
  }

  Future<void> setCaptionLanguage(
    String? value,
    SharedPreferences prefs,
  ) async {
    _captionLanguage = value ?? '';
    await prefs.setString(_captionLanguageKey, _captionLanguage);
    notifyListeners();
  }
}
