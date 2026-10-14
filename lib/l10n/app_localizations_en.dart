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
  String get watched => 'Watched';

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
  String get autoplayHint => 'Play videos and the next video automatically';

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
  String get replay => 'Replay';

  @override
  String get nextVideo => 'Next video';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get close => 'Close';

  @override
  String get audio => 'Audio';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get quality => 'Quality';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get volume => 'Volume';

  @override
  String get speedNormal => 'Normal';

  @override
  String get captions => 'Captions';

  @override
  String get captionsOff => 'Off';

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

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String sleepTimerMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '$count minute',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerEndOfVideo => 'End of video';

  @override
  String get sleepTimerOff => 'Off';

  @override
  String get sponsorBlock => 'SponsorBlock';

  @override
  String get sponsorBlockHint => 'Skip sponsored segments in videos';

  @override
  String get sponsorBlockAutoSkip => 'Skip automatically';

  @override
  String get sponsorBlockAutoSkipHint =>
      'Show a skip button on the player instead when off';

  @override
  String get sponsorBlockCategories => 'Skipped categories';

  @override
  String get skipSegment => 'Skip';

  @override
  String get done => 'Done';

  @override
  String get sponsorCategorySponsor => 'Sponsor';

  @override
  String get sponsorCategorySelfpromo => 'Self-promotion';

  @override
  String get sponsorCategoryIntro => 'Intro';

  @override
  String get sponsorCategoryOutro => 'Outro';

  @override
  String get sponsorCategoryInteraction => 'Interaction reminder';

  @override
  String get sponsorCategoryMusicOfftopic => 'Off-topic music';

  @override
  String get deArrow => 'DeArrow';

  @override
  String get deArrowHint => 'Crowd-sourced titles and thumbnails';

  @override
  String get deArrowOff => 'Off';

  @override
  String get deArrowTitles => 'Titles only';

  @override
  String get deArrowThumbnails => 'Thumbnails only';

  @override
  String get deArrowBoth => 'Titles and thumbnails';

  @override
  String get comments => 'Comments';

  @override
  String get loadMoreComments => 'Load more comments';

  @override
  String replyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replies',
      one: '$count reply',
    );
    return '$_temp0';
  }

  @override
  String get importSubscriptions => 'Import subscriptions';

  @override
  String get importSubscriptionsHint =>
      'From an OPML file (NewPipe, FreeTube, Takeout)';

  @override
  String get exportSubscriptions => 'Export subscriptions';

  @override
  String get exportSubscriptionsHint => 'Save the subscription list as OPML';

  @override
  String subscriptionsImported(int imported, int failed) {
    return 'Imported $imported channels, $failed failed';
  }

  @override
  String get subscriptionsImportFailed => 'Could not read the OPML file';

  @override
  String subscriptionsExportedTo(String path) {
    return 'Subscriptions exported to $path';
  }

  @override
  String get subscriptionsExportFailed => 'Export cancelled or failed';

  @override
  String get navWatchLater => 'Watch later';

  @override
  String get watchLaterEmpty => 'Nothing saved for later';

  @override
  String get watchLaterAdd => 'Watch later';

  @override
  String get watchLaterRemove => 'Remove from Watch later';

  @override
  String videoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '$count video',
    );
    return '$_temp0';
  }

  @override
  String playlistProgress(String playlist, int index, int total) {
    return '$playlist · $index/$total';
  }

  @override
  String get uploadNotifications => 'Upload notifications';

  @override
  String get uploadNotificationsHint =>
      'Notify when subscribed channels post new videos';

  @override
  String get uploadCheckInterval => 'Check for uploads';

  @override
  String everyMinutes(int minutes) {
    return 'Every $minutes min';
  }

  @override
  String get pictureInPicture => 'Picture in picture';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get playlistsEmpty => 'No playlists yet';

  @override
  String get playlistsEmptyHint =>
      'Create a playlist to keep videos organised.';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String get playlistNameHint => 'Playlist name';

  @override
  String get create => 'Create';

  @override
  String get rename => 'Rename';

  @override
  String get renamePlaylist => 'Rename playlist';

  @override
  String get delete => 'Delete';

  @override
  String get deletePlaylist => 'Delete playlist';

  @override
  String get deletePlaylistConfirm => 'The videos stay in your history.';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String get removeFromPlaylist => 'Remove from playlist';

  @override
  String get playlistEmpty => 'This playlist is empty';

  @override
  String get savePlaylist => 'Save playlist';

  @override
  String get playlistSaved => 'Saved to your playlists';

  @override
  String get videoActions => 'More options';
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
  String get watched => 'Watched';

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
  String get autoplayHint => 'Play videos and the next video automatically';

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
  String get replay => 'Replay';

  @override
  String get nextVideo => 'Next video';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get close => 'Close';

  @override
  String get audio => 'Audio';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get quality => 'Quality';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get volume => 'Volume';

  @override
  String get speedNormal => 'Normal';

  @override
  String get captions => 'Captions';

  @override
  String get captionsOff => 'Off';

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

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String sleepTimerMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '$count minute',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerEndOfVideo => 'End of video';

  @override
  String get sleepTimerOff => 'Off';

  @override
  String get sponsorBlock => 'SponsorBlock';

  @override
  String get sponsorBlockHint => 'Skip sponsored segments in videos';

  @override
  String get sponsorBlockAutoSkip => 'Skip automatically';

  @override
  String get sponsorBlockAutoSkipHint =>
      'Show a skip button on the player instead when off';

  @override
  String get sponsorBlockCategories => 'Skipped categories';

  @override
  String get skipSegment => 'Skip';

  @override
  String get done => 'Done';

  @override
  String get sponsorCategorySponsor => 'Sponsor';

  @override
  String get sponsorCategorySelfpromo => 'Self-promotion';

  @override
  String get sponsorCategoryIntro => 'Intro';

  @override
  String get sponsorCategoryOutro => 'Outro';

  @override
  String get sponsorCategoryInteraction => 'Interaction reminder';

  @override
  String get sponsorCategoryMusicOfftopic => 'Off-topic music';

  @override
  String get deArrow => 'DeArrow';

  @override
  String get deArrowHint => 'Crowd-sourced titles and thumbnails';

  @override
  String get deArrowOff => 'Off';

  @override
  String get deArrowTitles => 'Titles only';

  @override
  String get deArrowThumbnails => 'Thumbnails only';

  @override
  String get deArrowBoth => 'Titles and thumbnails';

  @override
  String get comments => 'Comments';

  @override
  String get loadMoreComments => 'Load more comments';

  @override
  String replyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replies',
      one: '$count reply',
    );
    return '$_temp0';
  }

  @override
  String get importSubscriptions => 'Import subscriptions';

  @override
  String get importSubscriptionsHint =>
      'From an OPML file (NewPipe, FreeTube, Takeout)';

  @override
  String get exportSubscriptions => 'Export subscriptions';

  @override
  String get exportSubscriptionsHint => 'Save the subscription list as OPML';

  @override
  String subscriptionsImported(int imported, int failed) {
    return 'Imported $imported channels, $failed failed';
  }

  @override
  String get subscriptionsImportFailed => 'Could not read the OPML file';

  @override
  String subscriptionsExportedTo(String path) {
    return 'Subscriptions exported to $path';
  }

  @override
  String get subscriptionsExportFailed => 'Export cancelled or failed';

  @override
  String get navWatchLater => 'Watch later';

  @override
  String get watchLaterEmpty => 'Nothing saved for later';

  @override
  String get watchLaterAdd => 'Watch later';

  @override
  String get watchLaterRemove => 'Remove from Watch later';

  @override
  String videoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '$count video',
    );
    return '$_temp0';
  }

  @override
  String playlistProgress(String playlist, int index, int total) {
    return '$playlist · $index/$total';
  }

  @override
  String get uploadNotifications => 'Upload notifications';

  @override
  String get uploadNotificationsHint =>
      'Notify when subscribed channels post new videos';

  @override
  String get uploadCheckInterval => 'Check for uploads';

  @override
  String everyMinutes(int minutes) {
    return 'Every $minutes min';
  }

  @override
  String get pictureInPicture => 'Picture in picture';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get playlistsEmpty => 'No playlists yet';

  @override
  String get playlistsEmptyHint =>
      'Create a playlist to keep videos organised.';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String get playlistNameHint => 'Playlist name';

  @override
  String get create => 'Create';

  @override
  String get rename => 'Rename';

  @override
  String get renamePlaylist => 'Rename playlist';

  @override
  String get delete => 'Delete';

  @override
  String get deletePlaylist => 'Delete playlist';

  @override
  String get deletePlaylistConfirm => 'The videos stay in your history.';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String get removeFromPlaylist => 'Remove from playlist';

  @override
  String get playlistEmpty => 'This playlist is empty';

  @override
  String get savePlaylist => 'Save playlist';

  @override
  String get playlistSaved => 'Saved to your playlists';

  @override
  String get videoActions => 'More options';
}
