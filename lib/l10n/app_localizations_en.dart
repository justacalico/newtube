// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NewTube';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navSubscriptions => 'Subscriptions';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get collapseSidebar => 'Collapse sidebar';

  @override
  String get expandSidebar => 'Expand sidebar';

  @override
  String get searchHint => 'Search';

  @override
  String get loading => 'Loading…';

  @override
  String get errorLoading => 'Something went wrong';

  @override
  String get retry => 'Retry';

  @override
  String get noVideos => 'No videos found';

  @override
  String get views => 'views';

  @override
  String get relatedVideos => 'Related videos';

  @override
  String get description => 'Description';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get subscribed => 'Subscribed';

  @override
  String get subscribers => 'subscribers';

  @override
  String get channelVideos => 'Videos';

  @override
  String get latestFromSubscriptions => 'Latest from your subscriptions';

  @override
  String get channelsTitle => 'Channels';

  @override
  String get noSubscriptions => 'No subscriptions yet';

  @override
  String get noSubscriptionsHint =>
      'Subscribe to channels to see their latest videos here.';

  @override
  String get unsubscribe => 'Unsubscribe';

  @override
  String get watchHistory => 'Watch history';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get clearHistoryConfirm =>
      'This removes all watched videos and searches.';

  @override
  String get cancel => 'Cancel';

  @override
  String get clear => 'Clear';

  @override
  String get noHistory => 'Nothing watched yet';

  @override
  String get noHistoryHint => 'Videos you watch will show up here.';

  @override
  String get noSearchHistory => 'No searches yet';

  @override
  String get noSearchHistoryHint => 'Searches you run will show up here.';

  @override
  String get removeSearchEntry => 'Remove';

  @override
  String get searchHistory => 'Search history';

  @override
  String get searchHistoryHint => 'Remember the searches you run';

  @override
  String get searchHistoryOff => 'Search history is off';

  @override
  String get searchHistoryOffHint =>
      'Turn it on in Settings to see your searches here.';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeOled => 'OLED';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get autoplay => 'Autoplay videos';

  @override
  String get autoplayHint => 'Start playback as soon as a video opens';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checkingUpdates => 'Checking for updates…';

  @override
  String get upToDate => 'You are up to date';

  @override
  String get updateAvailable => 'New version available';

  @override
  String get checkFailed => 'Could not check for updates';

  @override
  String get viewRelease => 'View release';

  @override
  String get allReleases => 'All releases';

  @override
  String get sourceCode => 'Source code';

  @override
  String get licence => 'Licence';

  @override
  String get licenceText => 'GNU Affero General Public Licence v3.0';

  @override
  String get openVideo => 'Play';

  @override
  String get audio => 'Audio';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get quality => 'Quality';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get speedNormal => 'Normal';

  @override
  String get searchResultsFor => 'Results';

  @override
  String get corsNoticeTitle => 'Videos are blocked in the browser';

  @override
  String get corsNoticeBody =>
      'YouTube does not allow direct requests from web apps. Install a CORS extension or set a proxy in Settings.';

  @override
  String get corsFirefox => 'Firefox add-on';

  @override
  String get corsChrome => 'Chrome extension';

  @override
  String get corsProxyLabel => 'CORS proxy prefix';

  @override
  String get corsProxyHint =>
      'The video URL is appended URL-encoded, for example https://proxy.example/?url=';

  @override
  String get mcpServer => 'MCP server';

  @override
  String get mcpServerHint => 'Allow AI tools to search and play videos';

  @override
  String get mcpServerFailed => 'Could not start the MCP server';

  @override
  String get mcpExport => 'Export server file';

  @override
  String get mcpExportHint => 'Save a .mcpb file clients can import';

  @override
  String mcpExportedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String get mcpExportFailed => 'Could not save the export';
}

/// The translations for English, as used in the United Kingdom (`en_GB`).
class AppLocalizationsEnGb extends AppLocalizationsEn {
  AppLocalizationsEnGb() : super('en_GB');

  @override
  String get appTitle => 'NewTube';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navSubscriptions => 'Subscriptions';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get collapseSidebar => 'Collapse sidebar';

  @override
  String get expandSidebar => 'Expand sidebar';

  @override
  String get searchHint => 'Search';

  @override
  String get loading => 'Loading…';

  @override
  String get errorLoading => 'Something went wrong';

  @override
  String get retry => 'Retry';

  @override
  String get noVideos => 'No videos found';

  @override
  String get views => 'views';

  @override
  String get relatedVideos => 'Related videos';

  @override
  String get description => 'Description';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get subscribed => 'Subscribed';

  @override
  String get subscribers => 'subscribers';

  @override
  String get channelVideos => 'Videos';

  @override
  String get latestFromSubscriptions => 'Latest from your subscriptions';

  @override
  String get channelsTitle => 'Channels';

  @override
  String get noSubscriptions => 'No subscriptions yet';

  @override
  String get noSubscriptionsHint =>
      'Subscribe to channels to see their latest videos here.';

  @override
  String get unsubscribe => 'Unsubscribe';

  @override
  String get watchHistory => 'Watch history';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get clearHistoryConfirm =>
      'This removes all watched videos and searches.';

  @override
  String get cancel => 'Cancel';

  @override
  String get clear => 'Clear';

  @override
  String get noHistory => 'Nothing watched yet';

  @override
  String get noHistoryHint => 'Videos you watch will show up here.';

  @override
  String get noSearchHistory => 'No searches yet';

  @override
  String get noSearchHistoryHint => 'Searches you run will show up here.';

  @override
  String get removeSearchEntry => 'Remove';

  @override
  String get searchHistory => 'Search history';

  @override
  String get searchHistoryHint => 'Remember the searches you run';

  @override
  String get searchHistoryOff => 'Search history is off';

  @override
  String get searchHistoryOffHint =>
      'Turn it on in Settings to see your searches here.';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeOled => 'OLED';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get autoplay => 'Autoplay videos';

  @override
  String get autoplayHint => 'Start playback as soon as a video opens';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checkingUpdates => 'Checking for updates…';

  @override
  String get upToDate => 'You are up to date';

  @override
  String get updateAvailable => 'New version available';

  @override
  String get checkFailed => 'Could not check for updates';

  @override
  String get viewRelease => 'View release';

  @override
  String get allReleases => 'All releases';

  @override
  String get sourceCode => 'Source code';

  @override
  String get licence => 'Licence';

  @override
  String get licenceText => 'GNU Affero General Public Licence v3.0';

  @override
  String get openVideo => 'Play';

  @override
  String get audio => 'Audio';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get quality => 'Quality';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get speedNormal => 'Normal';

  @override
  String get searchResultsFor => 'Results';

  @override
  String get corsNoticeTitle => 'Videos are blocked in the browser';

  @override
  String get corsNoticeBody =>
      'YouTube does not allow direct requests from web apps. Install a CORS extension or set a proxy in Settings.';

  @override
  String get corsFirefox => 'Firefox add-on';

  @override
  String get corsChrome => 'Chrome extension';

  @override
  String get corsProxyLabel => 'CORS proxy prefix';

  @override
  String get corsProxyHint =>
      'The video URL is appended URL-encoded, for example https://proxy.example/?url=';

  @override
  String get mcpServer => 'MCP server';

  @override
  String get mcpServerHint => 'Allow AI tools to search and play videos';

  @override
  String get mcpServerFailed => 'Could not start the MCP server';

  @override
  String get mcpExport => 'Export server file';

  @override
  String get mcpExportHint => 'Save a .mcpb file clients can import';

  @override
  String mcpExportedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String get mcpExportFailed => 'Could not save the export';
}
