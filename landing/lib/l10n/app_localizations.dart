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

/// Callers can lookup localized strings with an instance of LandingLocalizations
/// returned by `LandingLocalizations.of(context)`.
///
/// Applications need to include `LandingLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: LandingLocalizations.localizationsDelegates,
///   supportedLocales: LandingLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the LandingLocalizations.supportedLocales
/// property.
abstract class LandingLocalizations {
  LandingLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static LandingLocalizations of(BuildContext context) {
    return Localizations.of<LandingLocalizations>(
      context,
      LandingLocalizations,
    )!;
  }

  static const LocalizationsDelegate<LandingLocalizations> delegate =
      _LandingLocalizationsDelegate();

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

  /// No description provided for @tagline.
  ///
  /// In en_GB, this message translates to:
  /// **'Watch YouTube without the ads, the tracking or the clutter.'**
  String get tagline;

  /// No description provided for @download.
  ///
  /// In en_GB, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @openApp.
  ///
  /// In en_GB, this message translates to:
  /// **'Open the web app'**
  String get openApp;

  /// No description provided for @features.
  ///
  /// In en_GB, this message translates to:
  /// **'Why NewTube'**
  String get features;

  /// No description provided for @featurePrivacy.
  ///
  /// In en_GB, this message translates to:
  /// **'Private by design'**
  String get featurePrivacy;

  /// No description provided for @featurePrivacyText.
  ///
  /// In en_GB, this message translates to:
  /// **'No account needed. Your subscriptions and history stay on your device.'**
  String get featurePrivacyText;

  /// No description provided for @featurePlatforms.
  ///
  /// In en_GB, this message translates to:
  /// **'Every platform'**
  String get featurePlatforms;

  /// No description provided for @featurePlatformsText.
  ///
  /// In en_GB, this message translates to:
  /// **'Android, iOS, Linux, Windows and macOS, all from one codebase.'**
  String get featurePlatformsText;

  /// No description provided for @featurePlayer.
  ///
  /// In en_GB, this message translates to:
  /// **'A real player'**
  String get featurePlayer;

  /// No description provided for @featurePlayerText.
  ///
  /// In en_GB, this message translates to:
  /// **'Quality selection, audio-only mode and a proper fullscreen.'**
  String get featurePlayerText;

  /// No description provided for @featureSubs.
  ///
  /// In en_GB, this message translates to:
  /// **'Local subscriptions'**
  String get featureSubs;

  /// No description provided for @featureSubsText.
  ///
  /// In en_GB, this message translates to:
  /// **'Follow channels without signing in to anything.'**
  String get featureSubsText;

  /// No description provided for @screenshots.
  ///
  /// In en_GB, this message translates to:
  /// **'Screenshots'**
  String get screenshots;

  /// No description provided for @downloads.
  ///
  /// In en_GB, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @downloadsHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Grab the latest release for your platform straight from GitLab.'**
  String get downloadsHint;

  /// No description provided for @viewOnGitLab.
  ///
  /// In en_GB, this message translates to:
  /// **'View releases on GitLab'**
  String get viewOnGitLab;

  /// No description provided for @loadReleasesFailed.
  ///
  /// In en_GB, this message translates to:
  /// **'Could not load releases'**
  String get loadReleasesFailed;

  /// No description provided for @retry.
  ///
  /// In en_GB, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @releasedOn.
  ///
  /// In en_GB, this message translates to:
  /// **'Released'**
  String get releasedOn;

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

  /// No description provided for @sourceCode.
  ///
  /// In en_GB, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// No description provided for @appSectionTitle.
  ///
  /// In en_GB, this message translates to:
  /// **'Try it in your browser'**
  String get appSectionTitle;

  /// No description provided for @appSectionText.
  ///
  /// In en_GB, this message translates to:
  /// **'The full app runs on the web too.'**
  String get appSectionText;
}

class _LandingLocalizationsDelegate
    extends LocalizationsDelegate<LandingLocalizations> {
  const _LandingLocalizationsDelegate();

  @override
  Future<LandingLocalizations> load(Locale locale) {
    return SynchronousFuture<LandingLocalizations>(
      lookupLandingLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ga', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_LandingLocalizationsDelegate old) => false;
}

LandingLocalizations lookupLandingLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return LandingLocalizationsZhHans();
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
            return LandingLocalizationsEnGb();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LandingLocalizationsEn();
    case 'ga':
      return LandingLocalizationsGa();
    case 'ru':
      return LandingLocalizationsRu();
    case 'zh':
      return LandingLocalizationsZh();
  }

  throw FlutterError(
    'LandingLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
