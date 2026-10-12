import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/l10n/app_localizations_en.dart';
import 'package:newtube/l10n/app_localizations_ga.dart';
import 'package:newtube/l10n/app_localizations_ru.dart';
import 'package:newtube/l10n/app_localizations_zh.dart';

void touchAll(AppLocalizations l) {
  l.appTitle;
  l.navHome;
  l.navSubscriptions;
  l.navHistory;
  l.navSettings;
  l.searchHint;
  l.loading;
  l.errorLoading;
  l.retry;
  l.noVideos;
  l.views;
  l.relatedVideos;
  l.description;
  l.subscribe;
  l.subscribed;
  l.subscribers;
  l.channelVideos;
  l.latestFromSubscriptions;
  l.channelsTitle;
  l.noSubscriptions;
  l.noSubscriptionsHint;
  l.unsubscribe;
  l.watchHistory;
  l.clearHistory;
  l.noHistory;
  l.noHistoryHint;
  l.theme;
  l.themeSystem;
  l.themeLight;
  l.themeDark;
  l.themeOled;
  l.language;
  l.languageSystem;
  l.autoplay;
  l.autoplayHint;
  l.about;
  l.version;
  l.checkForUpdates;
  l.checkingUpdates;
  l.upToDate;
  l.updateAvailable;
  l.checkFailed;
  l.viewRelease;
  l.allReleases;
  l.sourceCode;
  l.licence;
  l.licenceText;
  l.openVideo;
  l.audioOnly;
  l.fullscreen;
  l.quality;
  l.searchResultsFor;
}

void main() {
  test('every message resolves in every locale', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l = lookupAppLocalizations(locale);
      touchAll(l);
    }
    touchAll(AppLocalizationsEn());
    touchAll(AppLocalizationsEnGb());
    touchAll(AppLocalizationsZh());
    touchAll(AppLocalizationsZhHans());
    touchAll(AppLocalizationsRu());
    touchAll(AppLocalizationsGa());
  });

  test('delegate supports and loads all locales', () async {
    const delegate = AppLocalizations.delegate;
    for (final locale in AppLocalizations.supportedLocales) {
      expect(delegate.isSupported(locale), isTrue);
      touchAll(await delegate.load(locale));
    }
    expect(delegate.isSupported(const Locale('fr')), isFalse);
    expect(delegate.shouldReload(delegate), isFalse);
    expect(
      AppLocalizations.supportedLocales,
      contains(const Locale('en', 'GB')),
    );
  });

  test('locale resolution falls back to english', () {
    expect(
      lookupAppLocalizations(const Locale('en', 'GB')).appTitle,
      'NewTube',
    );
    expect(
      lookupAppLocalizations(const Locale('en', 'US')).appTitle,
      'NewTube',
    );
    expect(lookupAppLocalizations(const Locale('en')).appTitle, 'NewTube');
    expect(
      lookupAppLocalizations(const Locale('zh', 'CN')).appTitle,
      'NewTube',
    );
    expect(
      lookupAppLocalizations(const Locale('zh', 'TW')).appTitle,
      'NewTube',
    );
    expect(
      lookupAppLocalizations(const Locale('zh', 'Hans')).appTitle,
      'NewTube',
    );
    expect(
      () => lookupAppLocalizations(const Locale('xx', 'YY')),
      throwsFlutterError,
    );
  });
}
