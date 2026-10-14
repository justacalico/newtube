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
  l.navSearch;
  l.navSubscriptions;
  l.navHistory;
  l.navSettings;
  l.collapseSidebar;
  l.expandSidebar;
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
  l.watched;
  l.clearHistory;
  l.clearHistoryConfirm;
  l.cancel;
  l.clear;
  l.noHistory;
  l.noHistoryHint;
  l.noSearchHistory;
  l.noSearchHistoryHint;
  l.removeSearchEntry;
  l.searchHistory;
  l.searchHistoryHint;
  l.searchHistoryOff;
  l.searchHistoryOffHint;
  l.theme;
  l.themeSystem;
  l.themeLight;
  l.themeDark;
  l.themeOled;
  l.language;
  l.languageSystem;
  l.autoplay;
  l.autoplayHint;
  l.audioOnly;
  l.audioOnlyHint;
  l.defaultQuality;
  l.qualityAuto;
  l.qualityLowest;
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
  l.replay;
  l.nextVideo;
  l.play;
  l.pause;
  l.close;
  l.audio;
  l.fullscreen;
  l.quality;
  l.playbackSpeed;
  l.mute;
  l.unmute;
  l.volume;
  l.repeat;
  l.repeatOff;
  l.repeatAll;
  l.repeatOne;
  l.shuffle;
  l.speedNormal;
  l.captions;
  l.captionsOff;
  l.sleepTimer;
  l.sleepTimerMinutes(5);
  l.sleepTimerEndOfVideo;
  l.sleepTimerOff;
  l.sponsorBlock;
  l.sponsorBlockHint;
  l.sponsorBlockAutoSkip;
  l.sponsorBlockAutoSkipHint;
  l.sponsorBlockCategories;
  l.skipSegment;
  l.done;
  l.sponsorCategorySponsor;
  l.sponsorCategorySelfpromo;
  l.sponsorCategoryIntro;
  l.sponsorCategoryOutro;
  l.sponsorCategoryInteraction;
  l.sponsorCategoryMusicOfftopic;
  l.deArrow;
  l.deArrowHint;
  l.deArrowOff;
  l.deArrowTitles;
  l.deArrowThumbnails;
  l.deArrowBoth;
  l.comments;
  l.loadMoreComments;
  l.replyCount(3);
  l.importSubscriptions;
  l.importSubscriptionsHint;
  l.exportSubscriptions;
  l.exportSubscriptionsHint;
  l.subscriptionsImported(2, 1);
  l.subscriptionsImportFailed;
  l.subscriptionsExportedTo('/tmp/x.opml');
  l.subscriptionsExportFailed;
  l.navWatchLater;
  l.watchLaterEmpty;
  l.watchLaterAdd;
  l.watchLaterRemove;
  l.videoCount(3);
  l.playlistProgress('P', 1, 2);
  l.uploadNotifications;
  l.uploadNotificationsHint;
  l.uploadCheckInterval;
  l.everyMinutes(30);
  l.pictureInPicture;
  l.corsNoticeTitle;
  l.corsNoticeBody;
  l.corsFirefox;
  l.corsChrome;
  l.corsProxyLabel;
  l.corsProxyHint;
  l.searchResultsFor;
  l.mcpServer;
  l.mcpServerHint;
  l.mcpServerFailed;
  l.mcpExport;
  l.mcpExportHint;
  l.mcpExportedTo('x');
  l.mcpExportFailed;
  l.navPlaylists;
  l.playlistsEmpty;
  l.playlistsEmptyHint;
  l.newPlaylist;
  l.playlistNameHint;
  l.create;
  l.rename;
  l.renamePlaylist;
  l.delete;
  l.deletePlaylist;
  l.deletePlaylistConfirm;
  l.addToPlaylist;
  l.removeFromPlaylist;
  l.playlistEmpty;
  l.savePlaylist;
  l.playlistSaved;
  l.videoActions;
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
