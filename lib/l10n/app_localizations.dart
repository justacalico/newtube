import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ga.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'GB'),
    Locale('ga'),
    Locale('ru'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en_GB, this message translates to:
  /// **'NewTube'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en_GB, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTrending.
  ///
  /// In en_GB, this message translates to:
  /// **'Trending'**
  String get navTrending;

  /// No description provided for @navSearch.
  ///
  /// In en_GB, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navSubscriptions.
  ///
  /// In en_GB, this message translates to:
  /// **'Subscriptions'**
  String get navSubscriptions;

  /// No description provided for @navHistory.
  ///
  /// In en_GB, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en_GB, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @collapseSidebar.
  ///
  /// In en_GB, this message translates to:
  /// **'Collapse sidebar'**
  String get collapseSidebar;

  /// No description provided for @expandSidebar.
  ///
  /// In en_GB, this message translates to:
  /// **'Expand sidebar'**
  String get expandSidebar;

  /// No description provided for @searchHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @loading.
  ///
  /// In en_GB, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @errorLoading.
  ///
  /// In en_GB, this message translates to:
  /// **'Something went wrong'**
  String get errorLoading;

  /// No description provided for @retry.
  ///
  /// In en_GB, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noVideos.
  ///
  /// In en_GB, this message translates to:
  /// **'No videos found'**
  String get noVideos;

  /// No description provided for @views.
  ///
  /// In en_GB, this message translates to:
  /// **'views'**
  String get views;

  /// No description provided for @relatedVideos.
  ///
  /// In en_GB, this message translates to:
  /// **'Related videos'**
  String get relatedVideos;

  /// No description provided for @description.
  ///
  /// In en_GB, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @subscribe.
  ///
  /// In en_GB, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @subscribed.
  ///
  /// In en_GB, this message translates to:
  /// **'Subscribed'**
  String get subscribed;

  /// No description provided for @subscribers.
  ///
  /// In en_GB, this message translates to:
  /// **'subscribers'**
  String get subscribers;

  /// No description provided for @channelVideos.
  ///
  /// In en_GB, this message translates to:
  /// **'Videos'**
  String get channelVideos;

  /// No description provided for @latestFromSubscriptions.
  ///
  /// In en_GB, this message translates to:
  /// **'Latest from your subscriptions'**
  String get latestFromSubscriptions;

  /// No description provided for @channelsTitle.
  ///
  /// In en_GB, this message translates to:
  /// **'Channels'**
  String get channelsTitle;

  /// No description provided for @noSubscriptions.
  ///
  /// In en_GB, this message translates to:
  /// **'No subscriptions yet'**
  String get noSubscriptions;

  /// No description provided for @noSubscriptionsHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Subscribe to channels to see their latest videos here.'**
  String get noSubscriptionsHint;

  /// No description provided for @unsubscribe.
  ///
  /// In en_GB, this message translates to:
  /// **'Unsubscribe'**
  String get unsubscribe;

  /// No description provided for @watchHistory.
  ///
  /// In en_GB, this message translates to:
  /// **'Watch history'**
  String get watchHistory;

  /// No description provided for @watched.
  ///
  /// In en_GB, this message translates to:
  /// **'Watched'**
  String get watched;

  /// No description provided for @clearHistory.
  ///
  /// In en_GB, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In en_GB, this message translates to:
  /// **'This removes all watched videos and searches.'**
  String get clearHistoryConfirm;

  /// No description provided for @cancel.
  ///
  /// In en_GB, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @clear.
  ///
  /// In en_GB, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @noHistory.
  ///
  /// In en_GB, this message translates to:
  /// **'Nothing watched yet'**
  String get noHistory;

  /// No description provided for @noHistoryHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Videos you watch will show up here.'**
  String get noHistoryHint;

  /// No description provided for @noSearchHistory.
  ///
  /// In en_GB, this message translates to:
  /// **'No searches yet'**
  String get noSearchHistory;

  /// No description provided for @noSearchHistoryHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Searches you run will show up here.'**
  String get noSearchHistoryHint;

  /// No description provided for @removeSearchEntry.
  ///
  /// In en_GB, this message translates to:
  /// **'Remove'**
  String get removeSearchEntry;

  /// No description provided for @searchHistory.
  ///
  /// In en_GB, this message translates to:
  /// **'Search history'**
  String get searchHistory;

  /// No description provided for @searchHistoryHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Remember the searches you run'**
  String get searchHistoryHint;

  /// No description provided for @searchHistoryOff.
  ///
  /// In en_GB, this message translates to:
  /// **'Search history is off'**
  String get searchHistoryOff;

  /// No description provided for @searchHistoryOffHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Turn it on in Settings to see your searches here.'**
  String get searchHistoryOffHint;

  /// No description provided for @filterSort.
  ///
  /// In en_GB, this message translates to:
  /// **'Sort'**
  String get filterSort;

  /// No description provided for @filterType.
  ///
  /// In en_GB, this message translates to:
  /// **'Type'**
  String get filterType;

  /// No description provided for @filterUploadDate.
  ///
  /// In en_GB, this message translates to:
  /// **'Upload date'**
  String get filterUploadDate;

  /// No description provided for @filterDuration.
  ///
  /// In en_GB, this message translates to:
  /// **'Duration'**
  String get filterDuration;

  /// No description provided for @sortRelevance.
  ///
  /// In en_GB, this message translates to:
  /// **'Relevance'**
  String get sortRelevance;

  /// No description provided for @sortDate.
  ///
  /// In en_GB, this message translates to:
  /// **'Upload date'**
  String get sortDate;

  /// No description provided for @sortViews.
  ///
  /// In en_GB, this message translates to:
  /// **'View count'**
  String get sortViews;

  /// No description provided for @sortRating.
  ///
  /// In en_GB, this message translates to:
  /// **'Rating'**
  String get sortRating;

  /// No description provided for @typeAll.
  ///
  /// In en_GB, this message translates to:
  /// **'All'**
  String get typeAll;

  /// No description provided for @typeVideo.
  ///
  /// In en_GB, this message translates to:
  /// **'Videos'**
  String get typeVideo;

  /// No description provided for @typeChannel.
  ///
  /// In en_GB, this message translates to:
  /// **'Channels'**
  String get typeChannel;

  /// No description provided for @typePlaylist.
  ///
  /// In en_GB, this message translates to:
  /// **'Playlists'**
  String get typePlaylist;

  /// No description provided for @typeLive.
  ///
  /// In en_GB, this message translates to:
  /// **'Live'**
  String get typeLive;

  /// No description provided for @uploadAny.
  ///
  /// In en_GB, this message translates to:
  /// **'Any time'**
  String get uploadAny;

  /// No description provided for @uploadHour.
  ///
  /// In en_GB, this message translates to:
  /// **'Last hour'**
  String get uploadHour;

  /// No description provided for @uploadToday.
  ///
  /// In en_GB, this message translates to:
  /// **'Today'**
  String get uploadToday;

  /// No description provided for @uploadWeek.
  ///
  /// In en_GB, this message translates to:
  /// **'This week'**
  String get uploadWeek;

  /// No description provided for @uploadMonth.
  ///
  /// In en_GB, this message translates to:
  /// **'This month'**
  String get uploadMonth;

  /// No description provided for @uploadYear.
  ///
  /// In en_GB, this message translates to:
  /// **'This year'**
  String get uploadYear;

  /// No description provided for @durationAny.
  ///
  /// In en_GB, this message translates to:
  /// **'Any duration'**
  String get durationAny;

  /// No description provided for @durationShort.
  ///
  /// In en_GB, this message translates to:
  /// **'Under 4 minutes'**
  String get durationShort;

  /// No description provided for @durationMedium.
  ///
  /// In en_GB, this message translates to:
  /// **'4-20 minutes'**
  String get durationMedium;

  /// No description provided for @durationLong.
  ///
  /// In en_GB, this message translates to:
  /// **'Over 20 minutes'**
  String get durationLong;

  /// No description provided for @theme.
  ///
  /// In en_GB, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en_GB, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en_GB, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en_GB, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeOled.
  ///
  /// In en_GB, this message translates to:
  /// **'OLED'**
  String get themeOled;

  /// No description provided for @language.
  ///
  /// In en_GB, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en_GB, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @autoplay.
  ///
  /// In en_GB, this message translates to:
  /// **'Autoplay videos'**
  String get autoplay;

  /// No description provided for @autoplayHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Play videos and the next video automatically'**
  String get autoplayHint;

  /// No description provided for @audioOnly.
  ///
  /// In en_GB, this message translates to:
  /// **'Audio only'**
  String get audioOnly;

  /// No description provided for @audioOnlyHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Play just the audio track and keep the artwork on screen'**
  String get audioOnlyHint;

  /// No description provided for @defaultQuality.
  ///
  /// In en_GB, this message translates to:
  /// **'Default video quality'**
  String get defaultQuality;

  /// No description provided for @qualityAuto.
  ///
  /// In en_GB, this message translates to:
  /// **'Auto'**
  String get qualityAuto;

  /// No description provided for @qualityLowest.
  ///
  /// In en_GB, this message translates to:
  /// **'Lowest'**
  String get qualityLowest;

  /// No description provided for @defaultSpeed.
  ///
  /// In en_GB, this message translates to:
  /// **'Default playback speed'**
  String get defaultSpeed;

  /// No description provided for @chapters.
  ///
  /// In en_GB, this message translates to:
  /// **'Chapters'**
  String get chapters;

  /// No description provided for @live.
  ///
  /// In en_GB, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @upcoming.
  ///
  /// In en_GB, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @statsForNerds.
  ///
  /// In en_GB, this message translates to:
  /// **'Stats for nerds'**
  String get statsForNerds;

  /// No description provided for @statsVideo.
  ///
  /// In en_GB, this message translates to:
  /// **'Video'**
  String get statsVideo;

  /// No description provided for @statsAudio.
  ///
  /// In en_GB, this message translates to:
  /// **'Audio'**
  String get statsAudio;

  /// No description provided for @statsPosition.
  ///
  /// In en_GB, this message translates to:
  /// **'Position'**
  String get statsPosition;

  /// No description provided for @statsBuffered.
  ///
  /// In en_GB, this message translates to:
  /// **'buffered'**
  String get statsBuffered;

  /// No description provided for @statsRate.
  ///
  /// In en_GB, this message translates to:
  /// **'Speed'**
  String get statsRate;

  /// No description provided for @statsVolume.
  ///
  /// In en_GB, this message translates to:
  /// **'Volume'**
  String get statsVolume;

  /// No description provided for @showDislikes.
  ///
  /// In en_GB, this message translates to:
  /// **'Show dislike counts'**
  String get showDislikes;

  /// No description provided for @showDislikesHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Estimated dislikes via Return YouTube Dislike'**
  String get showDislikesHint;

  /// No description provided for @dislikes.
  ///
  /// In en_GB, this message translates to:
  /// **'dislikes'**
  String get dislikes;

  /// No description provided for @share.
  ///
  /// In en_GB, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copyLink.
  ///
  /// In en_GB, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @copyLinkAtTime.
  ///
  /// In en_GB, this message translates to:
  /// **'Copy link at current time'**
  String get copyLinkAtTime;

  /// No description provided for @watchOnYouTube.
  ///
  /// In en_GB, this message translates to:
  /// **'Watch on YouTube'**
  String get watchOnYouTube;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en_GB, this message translates to:
  /// **'Link copied'**
  String get copiedToClipboard;

  /// No description provided for @showReplies.
  ///
  /// In en_GB, this message translates to:
  /// **'Show replies'**
  String get showReplies;

  /// No description provided for @hideReplies.
  ///
  /// In en_GB, this message translates to:
  /// **'Hide replies'**
  String get hideReplies;

  /// No description provided for @creator.
  ///
  /// In en_GB, this message translates to:
  /// **'Creator'**
  String get creator;

  /// No description provided for @commentsSort.
  ///
  /// In en_GB, this message translates to:
  /// **'Sort comments'**
  String get commentsSort;

  /// No description provided for @commentsTop.
  ///
  /// In en_GB, this message translates to:
  /// **'Top'**
  String get commentsTop;

  /// No description provided for @commentsNewest.
  ///
  /// In en_GB, this message translates to:
  /// **'Newest'**
  String get commentsNewest;

  /// No description provided for @upNext.
  ///
  /// In en_GB, this message translates to:
  /// **'Up next'**
  String get upNext;

  /// No description provided for @playNow.
  ///
  /// In en_GB, this message translates to:
  /// **'Play now'**
  String get playNow;

  /// No description provided for @videoFit.
  ///
  /// In en_GB, this message translates to:
  /// **'Video fit'**
  String get videoFit;

  /// No description provided for @fitContain.
  ///
  /// In en_GB, this message translates to:
  /// **'Fit'**
  String get fitContain;

  /// No description provided for @fitCover.
  ///
  /// In en_GB, this message translates to:
  /// **'Zoom to fill'**
  String get fitCover;

  /// No description provided for @fitFill.
  ///
  /// In en_GB, this message translates to:
  /// **'Stretch'**
  String get fitFill;

  /// No description provided for @about.
  ///
  /// In en_GB, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en_GB, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @checkForUpdates.
  ///
  /// In en_GB, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @checkingUpdates.
  ///
  /// In en_GB, this message translates to:
  /// **'Checking for updates…'**
  String get checkingUpdates;

  /// No description provided for @upToDate.
  ///
  /// In en_GB, this message translates to:
  /// **'You are up to date'**
  String get upToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In en_GB, this message translates to:
  /// **'New version available'**
  String get updateAvailable;

  /// No description provided for @checkFailed.
  ///
  /// In en_GB, this message translates to:
  /// **'Could not check for updates'**
  String get checkFailed;

  /// No description provided for @viewRelease.
  ///
  /// In en_GB, this message translates to:
  /// **'View release'**
  String get viewRelease;

  /// No description provided for @allReleases.
  ///
  /// In en_GB, this message translates to:
  /// **'All releases'**
  String get allReleases;

  /// No description provided for @sourceCode.
  ///
  /// In en_GB, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// No description provided for @licence.
  ///
  /// In en_GB, this message translates to:
  /// **'Licence'**
  String get licence;

  /// No description provided for @licenceText.
  ///
  /// In en_GB, this message translates to:
  /// **'GNU Affero General Public Licence v3.0'**
  String get licenceText;

  /// No description provided for @openVideo.
  ///
  /// In en_GB, this message translates to:
  /// **'Play'**
  String get openVideo;

  /// No description provided for @replay.
  ///
  /// In en_GB, this message translates to:
  /// **'Replay'**
  String get replay;

  /// No description provided for @nextVideo.
  ///
  /// In en_GB, this message translates to:
  /// **'Next video'**
  String get nextVideo;

  /// No description provided for @play.
  ///
  /// In en_GB, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en_GB, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @close.
  ///
  /// In en_GB, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @audio.
  ///
  /// In en_GB, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @fullscreen.
  ///
  /// In en_GB, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// No description provided for @quality.
  ///
  /// In en_GB, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @playbackSpeed.
  ///
  /// In en_GB, this message translates to:
  /// **'Playback speed'**
  String get playbackSpeed;

  /// No description provided for @mute.
  ///
  /// In en_GB, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en_GB, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @volume.
  ///
  /// In en_GB, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @repeat.
  ///
  /// In en_GB, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatOff.
  ///
  /// In en_GB, this message translates to:
  /// **'Off'**
  String get repeatOff;

  /// No description provided for @repeatAll.
  ///
  /// In en_GB, this message translates to:
  /// **'All'**
  String get repeatAll;

  /// No description provided for @repeatOne.
  ///
  /// In en_GB, this message translates to:
  /// **'One'**
  String get repeatOne;

  /// No description provided for @shuffle.
  ///
  /// In en_GB, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @speedNormal.
  ///
  /// In en_GB, this message translates to:
  /// **'Normal'**
  String get speedNormal;

  /// No description provided for @captions.
  ///
  /// In en_GB, this message translates to:
  /// **'Captions'**
  String get captions;

  /// No description provided for @captionsOff.
  ///
  /// In en_GB, this message translates to:
  /// **'Off'**
  String get captionsOff;

  /// No description provided for @searchResultsFor.
  ///
  /// In en_GB, this message translates to:
  /// **'Results'**
  String get searchResultsFor;

  /// No description provided for @corsNoticeTitle.
  ///
  /// In en_GB, this message translates to:
  /// **'Videos are blocked in the browser'**
  String get corsNoticeTitle;

  /// No description provided for @corsNoticeBody.
  ///
  /// In en_GB, this message translates to:
  /// **'YouTube does not allow direct requests from web apps. Install a CORS extension or set a proxy in Settings.'**
  String get corsNoticeBody;

  /// No description provided for @corsFirefox.
  ///
  /// In en_GB, this message translates to:
  /// **'Firefox add-on'**
  String get corsFirefox;

  /// No description provided for @corsChrome.
  ///
  /// In en_GB, this message translates to:
  /// **'Chrome extension'**
  String get corsChrome;

  /// No description provided for @corsProxyLabel.
  ///
  /// In en_GB, this message translates to:
  /// **'CORS proxy prefix'**
  String get corsProxyLabel;

  /// No description provided for @corsProxyHint.
  ///
  /// In en_GB, this message translates to:
  /// **'The video URL is appended URL-encoded, for example https://proxy.example/?url='**
  String get corsProxyHint;

  /// No description provided for @mcpServer.
  ///
  /// In en_GB, this message translates to:
  /// **'MCP server'**
  String get mcpServer;

  /// No description provided for @mcpServerHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Allow AI tools to search and play videos'**
  String get mcpServerHint;

  /// No description provided for @mcpServerFailed.
  ///
  /// In en_GB, this message translates to:
  /// **'Could not start the MCP server'**
  String get mcpServerFailed;

  /// No description provided for @mcpExport.
  ///
  /// In en_GB, this message translates to:
  /// **'Export server file'**
  String get mcpExport;

  /// No description provided for @mcpExportHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Save a .mcpb file clients can import'**
  String get mcpExportHint;

  /// No description provided for @mcpExportedTo.
  ///
  /// In en_GB, this message translates to:
  /// **'Saved to {path}'**
  String mcpExportedTo(String path);

  /// No description provided for @mcpExportFailed.
  ///
  /// In en_GB, this message translates to:
  /// **'Could not save the export'**
  String get mcpExportFailed;

  /// No description provided for @sleepTimer.
  ///
  /// In en_GB, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// No description provided for @sleepTimerMinutes.
  ///
  /// In en_GB, this message translates to:
  /// **'{count, plural, one{{count} minute} other{{count} minutes}}'**
  String sleepTimerMinutes(int count);

  /// No description provided for @sleepTimerEndOfVideo.
  ///
  /// In en_GB, this message translates to:
  /// **'End of video'**
  String get sleepTimerEndOfVideo;

  /// No description provided for @sleepTimerOff.
  ///
  /// In en_GB, this message translates to:
  /// **'Off'**
  String get sleepTimerOff;

  /// No description provided for @sponsorBlock.
  ///
  /// In en_GB, this message translates to:
  /// **'SponsorBlock'**
  String get sponsorBlock;

  /// No description provided for @sponsorBlockHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Skip sponsored segments in videos'**
  String get sponsorBlockHint;

  /// No description provided for @sponsorBlockAutoSkip.
  ///
  /// In en_GB, this message translates to:
  /// **'Skip automatically'**
  String get sponsorBlockAutoSkip;

  /// No description provided for @sponsorBlockAutoSkipHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Show a skip button on the player instead when off'**
  String get sponsorBlockAutoSkipHint;

  /// No description provided for @sponsorBlockCategories.
  ///
  /// In en_GB, this message translates to:
  /// **'Skipped categories'**
  String get sponsorBlockCategories;

  /// No description provided for @skipSegment.
  ///
  /// In en_GB, this message translates to:
  /// **'Skip'**
  String get skipSegment;

  /// No description provided for @done.
  ///
  /// In en_GB, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @sponsorCategorySponsor.
  ///
  /// In en_GB, this message translates to:
  /// **'Sponsor'**
  String get sponsorCategorySponsor;

  /// No description provided for @sponsorCategorySelfpromo.
  ///
  /// In en_GB, this message translates to:
  /// **'Self-promotion'**
  String get sponsorCategorySelfpromo;

  /// No description provided for @sponsorCategoryIntro.
  ///
  /// In en_GB, this message translates to:
  /// **'Intro'**
  String get sponsorCategoryIntro;

  /// No description provided for @sponsorCategoryOutro.
  ///
  /// In en_GB, this message translates to:
  /// **'Outro'**
  String get sponsorCategoryOutro;

  /// No description provided for @sponsorCategoryInteraction.
  ///
  /// In en_GB, this message translates to:
  /// **'Interaction reminder'**
  String get sponsorCategoryInteraction;

  /// No description provided for @sponsorCategoryMusicOfftopic.
  ///
  /// In en_GB, this message translates to:
  /// **'Off-topic music'**
  String get sponsorCategoryMusicOfftopic;

  /// No description provided for @deArrow.
  ///
  /// In en_GB, this message translates to:
  /// **'DeArrow'**
  String get deArrow;

  /// No description provided for @deArrowHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Crowd-sourced titles and thumbnails'**
  String get deArrowHint;

  /// No description provided for @deArrowOff.
  ///
  /// In en_GB, this message translates to:
  /// **'Off'**
  String get deArrowOff;

  /// No description provided for @deArrowTitles.
  ///
  /// In en_GB, this message translates to:
  /// **'Titles only'**
  String get deArrowTitles;

  /// No description provided for @deArrowThumbnails.
  ///
  /// In en_GB, this message translates to:
  /// **'Thumbnails only'**
  String get deArrowThumbnails;

  /// No description provided for @deArrowBoth.
  ///
  /// In en_GB, this message translates to:
  /// **'Titles and thumbnails'**
  String get deArrowBoth;

  /// No description provided for @comments.
  ///
  /// In en_GB, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @loadMoreComments.
  ///
  /// In en_GB, this message translates to:
  /// **'Load more comments'**
  String get loadMoreComments;

  /// No description provided for @replyCount.
  ///
  /// In en_GB, this message translates to:
  /// **'{count, plural, one{{count} reply} other{{count} replies}}'**
  String replyCount(int count);

  /// No description provided for @importSubscriptions.
  ///
  /// In en_GB, this message translates to:
  /// **'Import subscriptions'**
  String get importSubscriptions;

  /// No description provided for @importSubscriptionsHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Import subscriptions from OPML or a YouTube Takeout CSV'**
  String get importSubscriptionsHint;

  /// No description provided for @exportSubscriptions.
  ///
  /// In en_GB, this message translates to:
  /// **'Export subscriptions'**
  String get exportSubscriptions;

  /// No description provided for @exportSubscriptionsHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Save the subscription list as OPML'**
  String get exportSubscriptionsHint;

  /// No description provided for @subscriptionsImported.
  ///
  /// In en_GB, this message translates to:
  /// **'Imported {imported} channels, {failed} failed'**
  String subscriptionsImported(int imported, int failed);

  /// No description provided for @subscriptionsImportFailed.
  ///
  /// In en_GB, this message translates to:
  /// **'Could not read the OPML file'**
  String get subscriptionsImportFailed;

  /// No description provided for @subscriptionsExportedTo.
  ///
  /// In en_GB, this message translates to:
  /// **'Subscriptions exported to {path}'**
  String subscriptionsExportedTo(String path);

  /// No description provided for @subscriptionsExportFailed.
  ///
  /// In en_GB, this message translates to:
  /// **'Export cancelled or failed'**
  String get subscriptionsExportFailed;

  /// No description provided for @navWatchLater.
  ///
  /// In en_GB, this message translates to:
  /// **'Watch later'**
  String get navWatchLater;

  /// No description provided for @watchLaterEmpty.
  ///
  /// In en_GB, this message translates to:
  /// **'Nothing saved for later'**
  String get watchLaterEmpty;

  /// No description provided for @watchLaterAdd.
  ///
  /// In en_GB, this message translates to:
  /// **'Watch later'**
  String get watchLaterAdd;

  /// No description provided for @watchLaterRemove.
  ///
  /// In en_GB, this message translates to:
  /// **'Remove from Watch later'**
  String get watchLaterRemove;

  /// No description provided for @videoCount.
  ///
  /// In en_GB, this message translates to:
  /// **'{count, plural, one{{count} video} other{{count} videos}}'**
  String videoCount(int count);

  /// No description provided for @playlistProgress.
  ///
  /// In en_GB, this message translates to:
  /// **'{playlist} · {index}/{total}'**
  String playlistProgress(String playlist, int index, int total);

  /// No description provided for @uploadNotifications.
  ///
  /// In en_GB, this message translates to:
  /// **'Upload notifications'**
  String get uploadNotifications;

  /// No description provided for @uploadNotificationsHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Notify when subscribed channels post new videos'**
  String get uploadNotificationsHint;

  /// No description provided for @uploadCheckInterval.
  ///
  /// In en_GB, this message translates to:
  /// **'Check for uploads'**
  String get uploadCheckInterval;

  /// No description provided for @everyMinutes.
  ///
  /// In en_GB, this message translates to:
  /// **'Every {minutes} min'**
  String everyMinutes(int minutes);

  /// No description provided for @pictureInPicture.
  ///
  /// In en_GB, this message translates to:
  /// **'Picture in picture'**
  String get pictureInPicture;

  /// No description provided for @navPlaylists.
  ///
  /// In en_GB, this message translates to:
  /// **'Playlists'**
  String get navPlaylists;

  /// No description provided for @playlistsEmpty.
  ///
  /// In en_GB, this message translates to:
  /// **'No playlists yet'**
  String get playlistsEmpty;

  /// No description provided for @playlistsEmptyHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Create a playlist to keep videos organised.'**
  String get playlistsEmptyHint;

  /// No description provided for @newPlaylist.
  ///
  /// In en_GB, this message translates to:
  /// **'New playlist'**
  String get newPlaylist;

  /// No description provided for @playlistNameHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Playlist name'**
  String get playlistNameHint;

  /// No description provided for @create.
  ///
  /// In en_GB, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @rename.
  ///
  /// In en_GB, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renamePlaylist.
  ///
  /// In en_GB, this message translates to:
  /// **'Rename playlist'**
  String get renamePlaylist;

  /// No description provided for @delete.
  ///
  /// In en_GB, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deletePlaylist.
  ///
  /// In en_GB, this message translates to:
  /// **'Delete playlist'**
  String get deletePlaylist;

  /// No description provided for @deletePlaylistConfirm.
  ///
  /// In en_GB, this message translates to:
  /// **'The videos stay in your history.'**
  String get deletePlaylistConfirm;

  /// No description provided for @addToPlaylist.
  ///
  /// In en_GB, this message translates to:
  /// **'Add to playlist'**
  String get addToPlaylist;

  /// No description provided for @removeFromPlaylist.
  ///
  /// In en_GB, this message translates to:
  /// **'Remove from playlist'**
  String get removeFromPlaylist;

  /// No description provided for @playlistEmpty.
  ///
  /// In en_GB, this message translates to:
  /// **'This playlist is empty'**
  String get playlistEmpty;

  /// No description provided for @savePlaylist.
  ///
  /// In en_GB, this message translates to:
  /// **'Save playlist'**
  String get savePlaylist;

  /// No description provided for @playlistSaved.
  ///
  /// In en_GB, this message translates to:
  /// **'Saved to your playlists'**
  String get playlistSaved;

  /// No description provided for @videoActions.
  ///
  /// In en_GB, this message translates to:
  /// **'More options'**
  String get videoActions;

  /// No description provided for @hideShorts.
  ///
  /// In en_GB, this message translates to:
  /// **'Hide Shorts'**
  String get hideShorts;

  /// No description provided for @hideShortsHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Filter Shorts out of feeds and search'**
  String get hideShortsHint;

  /// No description provided for @shortsBadge.
  ///
  /// In en_GB, this message translates to:
  /// **'SHORTS'**
  String get shortsBadge;

  /// No description provided for @downloads.
  ///
  /// In en_GB, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @noDownloads.
  ///
  /// In en_GB, this message translates to:
  /// **'No downloads yet'**
  String get noDownloads;

  /// No description provided for @deleteDownload.
  ///
  /// In en_GB, this message translates to:
  /// **'Delete download'**
  String get deleteDownload;

  /// No description provided for @download.
  ///
  /// In en_GB, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloadVideo.
  ///
  /// In en_GB, this message translates to:
  /// **'Download video'**
  String get downloadVideo;

  /// No description provided for @downloadAudio.
  ///
  /// In en_GB, this message translates to:
  /// **'Download audio only'**
  String get downloadAudio;

  /// No description provided for @downloadedTo.
  ///
  /// In en_GB, this message translates to:
  /// **'Saved to {path}'**
  String downloadedTo(String path);

  /// No description provided for @downloadFailed.
  ///
  /// In en_GB, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @pickDownloadStream.
  ///
  /// In en_GB, this message translates to:
  /// **'Pick a quality to download'**
  String get pickDownloadStream;

  /// No description provided for @downloadsNav.
  ///
  /// In en_GB, this message translates to:
  /// **'Downloads'**
  String get downloadsNav;

  /// No description provided for @playlistName.
  ///
  /// In en_GB, this message translates to:
  /// **'Playlist name'**
  String get playlistName;

  /// No description provided for @save.
  ///
  /// In en_GB, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @shufflePlay.
  ///
  /// In en_GB, this message translates to:
  /// **'Shuffle play'**
  String get shufflePlay;

  /// No description provided for @exportPlaylist.
  ///
  /// In en_GB, this message translates to:
  /// **'Export playlist'**
  String get exportPlaylist;

  /// No description provided for @exportCancelled.
  ///
  /// In en_GB, this message translates to:
  /// **'Export cancelled'**
  String get exportCancelled;

  /// No description provided for @exportedTo.
  ///
  /// In en_GB, this message translates to:
  /// **'Exported to {path}'**
  String exportedTo(String path);

  /// No description provided for @resumedFrom.
  ///
  /// In en_GB, this message translates to:
  /// **'Resumed from {position}'**
  String resumedFrom(String position);

  /// No description provided for @startOver.
  ///
  /// In en_GB, this message translates to:
  /// **'Start over'**
  String get startOver;

  /// No description provided for @continueWatching.
  ///
  /// In en_GB, this message translates to:
  /// **'Continue watching'**
  String get continueWatching;

  /// No description provided for @filterHistory.
  ///
  /// In en_GB, this message translates to:
  /// **'Filter history'**
  String get filterHistory;

  /// No description provided for @removeFromHistory.
  ///
  /// In en_GB, this message translates to:
  /// **'Remove from history'**
  String get removeFromHistory;

  /// No description provided for @noResults.
  ///
  /// In en_GB, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @markWatched.
  ///
  /// In en_GB, this message translates to:
  /// **'Mark as watched'**
  String get markWatched;

  /// No description provided for @markUnwatched.
  ///
  /// In en_GB, this message translates to:
  /// **'Mark as unwatched'**
  String get markUnwatched;

  /// No description provided for @refreshFeed.
  ///
  /// In en_GB, this message translates to:
  /// **'Refresh'**
  String get refreshFeed;

  /// No description provided for @hideWatched.
  ///
  /// In en_GB, this message translates to:
  /// **'Hide watched'**
  String get hideWatched;

  /// No description provided for @hideWatchedHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Filter watched videos out of feeds and search'**
  String get hideWatchedHint;

  /// No description provided for @playNext.
  ///
  /// In en_GB, this message translates to:
  /// **'Play next'**
  String get playNext;

  /// No description provided for @addToQueue.
  ///
  /// In en_GB, this message translates to:
  /// **'Add to queue'**
  String get addToQueue;

  /// No description provided for @queued.
  ///
  /// In en_GB, this message translates to:
  /// **'Added to queue'**
  String get queued;

  /// No description provided for @queuedNext.
  ///
  /// In en_GB, this message translates to:
  /// **'Will play next'**
  String get queuedNext;

  /// No description provided for @exportBackup.
  ///
  /// In en_GB, this message translates to:
  /// **'Export backup'**
  String get exportBackup;

  /// No description provided for @exportBackupHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Save all app data to a file'**
  String get exportBackupHint;

  /// No description provided for @importBackup.
  ///
  /// In en_GB, this message translates to:
  /// **'Import backup'**
  String get importBackup;

  /// No description provided for @importBackupHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Restore app data from a file'**
  String get importBackupHint;

  /// No description provided for @backupRestored.
  ///
  /// In en_GB, this message translates to:
  /// **'Restored {count} settings'**
  String backupRestored(int count);

  /// No description provided for @backupImportFailed.
  ///
  /// In en_GB, this message translates to:
  /// **'Could not import the backup'**
  String get backupImportFailed;

  /// No description provided for @backupExportedTo.
  ///
  /// In en_GB, this message translates to:
  /// **'Backup saved to {path}'**
  String backupExportedTo(String path);

  /// No description provided for @allChannels.
  ///
  /// In en_GB, this message translates to:
  /// **'All channels'**
  String get allChannels;

  /// No description provided for @subscriptionGroups.
  ///
  /// In en_GB, this message translates to:
  /// **'Subscription groups'**
  String get subscriptionGroups;

  /// No description provided for @manageGroups.
  ///
  /// In en_GB, this message translates to:
  /// **'Manage groups'**
  String get manageGroups;

  /// No description provided for @newGroup.
  ///
  /// In en_GB, this message translates to:
  /// **'New group'**
  String get newGroup;

  /// No description provided for @groupName.
  ///
  /// In en_GB, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @channelGroup.
  ///
  /// In en_GB, this message translates to:
  /// **'Group'**
  String get channelGroup;

  /// No description provided for @noGroup.
  ///
  /// In en_GB, this message translates to:
  /// **'No group'**
  String get noGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In en_GB, this message translates to:
  /// **'Delete group'**
  String get deleteGroup;

  /// No description provided for @renameGroup.
  ///
  /// In en_GB, this message translates to:
  /// **'Rename group'**
  String get renameGroup;

  /// No description provided for @channelNotify.
  ///
  /// In en_GB, this message translates to:
  /// **'Upload notifications'**
  String get channelNotify;

  /// No description provided for @sponsorCategoryPreview.
  ///
  /// In en_GB, this message translates to:
  /// **'Preview / recap'**
  String get sponsorCategoryPreview;

  /// No description provided for @sponsorCategoryFiller.
  ///
  /// In en_GB, this message translates to:
  /// **'Filler'**
  String get sponsorCategoryFiller;

  /// No description provided for @sponsorCategoryPoiHighlight.
  ///
  /// In en_GB, this message translates to:
  /// **'Point of interest (jump)'**
  String get sponsorCategoryPoiHighlight;

  /// No description provided for @sponsorCategoryExclusiveAccess.
  ///
  /// In en_GB, this message translates to:
  /// **'Exclusive access / self-promo banner'**
  String get sponsorCategoryExclusiveAccess;

  /// No description provided for @sponsorCategoryChapter.
  ///
  /// In en_GB, this message translates to:
  /// **'Chapter (community-labelled)'**
  String get sponsorCategoryChapter;

  /// No description provided for @jumpToHighlight.
  ///
  /// In en_GB, this message translates to:
  /// **'Jump to highlight'**
  String get jumpToHighlight;

  /// No description provided for @networkProxy.
  ///
  /// In en_GB, this message translates to:
  /// **'Network proxy'**
  String get networkProxy;

  /// No description provided for @networkProxyHint.
  ///
  /// In en_GB, this message translates to:
  /// **'SOCKS5 or HTTP proxy, applied on restart'**
  String get networkProxyHint;

  /// No description provided for @preferredCodec.
  ///
  /// In en_GB, this message translates to:
  /// **'Preferred codec'**
  String get preferredCodec;

  /// No description provided for @codecAuto.
  ///
  /// In en_GB, this message translates to:
  /// **'Auto'**
  String get codecAuto;

  /// No description provided for @codecAvc.
  ///
  /// In en_GB, this message translates to:
  /// **'AVC (H.264)'**
  String get codecAvc;

  /// No description provided for @codecVp9.
  ///
  /// In en_GB, this message translates to:
  /// **'VP9'**
  String get codecVp9;

  /// No description provided for @codecAv1.
  ///
  /// In en_GB, this message translates to:
  /// **'AV1'**
  String get codecAv1;

  /// No description provided for @channelTabVideos.
  ///
  /// In en_GB, this message translates to:
  /// **'Videos'**
  String get channelTabVideos;

  /// No description provided for @channelTabShorts.
  ///
  /// In en_GB, this message translates to:
  /// **'Shorts'**
  String get channelTabShorts;

  /// No description provided for @channelTabPlaylists.
  ///
  /// In en_GB, this message translates to:
  /// **'Playlists'**
  String get channelTabPlaylists;

  /// No description provided for @channelTabAbout.
  ///
  /// In en_GB, this message translates to:
  /// **'About'**
  String get channelTabAbout;

  /// No description provided for @searchThisChannel.
  ///
  /// In en_GB, this message translates to:
  /// **'Search this channel'**
  String get searchThisChannel;

  /// No description provided for @noPlaylists.
  ///
  /// In en_GB, this message translates to:
  /// **'No playlists'**
  String get noPlaylists;

  /// No description provided for @noAboutInfo.
  ///
  /// In en_GB, this message translates to:
  /// **'No channel info'**
  String get noAboutInfo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ga', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'GB':
            return AppLocalizationsEnGb();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ga':
      return AppLocalizationsGa();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
