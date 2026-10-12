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

  /// No description provided for @clearWatchHistory.
  ///
  /// In en_GB, this message translates to:
  /// **'Clear watch history'**
  String get clearWatchHistory;

  /// No description provided for @clearSearchHistory.
  ///
  /// In en_GB, this message translates to:
  /// **'Clear search history'**
  String get clearSearchHistory;

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
  /// **'Start playback as soon as a video opens'**
  String get autoplayHint;

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

  /// No description provided for @audioOnly.
  ///
  /// In en_GB, this message translates to:
  /// **'Audio only'**
  String get audioOnly;

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
