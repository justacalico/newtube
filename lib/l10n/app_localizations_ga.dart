// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Irish (`ga`).
class AppLocalizationsGa extends AppLocalizations {
  AppLocalizationsGa([String locale = 'ga']) : super(locale);

  @override
  String get appTitle => 'NewTube';

  @override
  String get navHome => 'Baile';

  @override
  String get navSearch => 'Cuardaigh';

  @override
  String get navSubscriptions => 'Síntiúis';

  @override
  String get navHistory => 'Stair';

  @override
  String get navSettings => 'Socruithe';

  @override
  String get collapseSidebar => 'Fill an barra taobh';

  @override
  String get expandSidebar => 'Leathnaigh an barra taobh';

  @override
  String get searchHint => 'Cuardaigh';

  @override
  String get loading => 'Ag lódáil…';

  @override
  String get errorLoading => 'Chuaigh rud éigin mícheart';

  @override
  String get retry => 'Bain triail eile as';

  @override
  String get noVideos => 'Níor aimsíodh aon fhíseán';

  @override
  String get views => 'amharc';

  @override
  String get relatedVideos => 'Físeáin ghaolmhara';

  @override
  String get description => 'Cur síos';

  @override
  String get subscribe => 'Liostáil';

  @override
  String get subscribed => 'Liostáilte';

  @override
  String get subscribers => 'síntíusóir';

  @override
  String get channelVideos => 'Físeáin';

  @override
  String get latestFromSubscriptions => 'An t-is déanaí ó do shíntiúis';

  @override
  String get channelsTitle => 'Cainéil';

  @override
  String get noSubscriptions => 'Níl aon síntiús agat fós';

  @override
  String get noSubscriptionsHint =>
      'Liostáil le cainéil le feiceáil a bhfíseáin is déanaí anseo.';

  @override
  String get unsubscribe => 'Díliostáil';

  @override
  String get watchHistory => 'Stair breathnaithe';

  @override
  String get clearHistory => 'Glan an stair';

  @override
  String get clearHistoryConfirm =>
      'Bainfear gach físeán breathnaithe agus cuardach.';

  @override
  String get cancel => 'Cealaigh';

  @override
  String get clear => 'Glan';

  @override
  String get noHistory => 'Níl aon rud feite agat fós';

  @override
  String get noHistoryHint => 'Taispeánfar na físeáin a fheachann tú anseo.';

  @override
  String get noSearchHistory => 'Níl aon rud cuardaithe agat fós';

  @override
  String get noSearchHistoryHint =>
      'Taispeánfar na cuardaigh a dhéanann tú anseo.';

  @override
  String get removeSearchEntry => 'Bain';

  @override
  String get searchHistory => 'Stair chuardaigh';

  @override
  String get searchHistoryHint => 'Meabhraigh na cuardaigh a dhéanann tú';

  @override
  String get searchHistoryOff => 'Tá stair chuardaigh múchtha';

  @override
  String get searchHistoryOffHint =>
      'Cas air i Socruithe le do chuardaigh a fheiceáil anseo.';

  @override
  String get theme => 'Téama';

  @override
  String get themeSystem => 'Córas';

  @override
  String get themeLight => 'Éadrom';

  @override
  String get themeDark => 'Dorcha';

  @override
  String get themeOled => 'OLED';

  @override
  String get language => 'Teanga';

  @override
  String get languageSystem => 'Córas';

  @override
  String get autoplay => 'Seinnt fhíseáin go huathoibríoch';

  @override
  String get autoplayHint =>
      'Tosaigh an t-athsheinm chomh luath agus a osclaítear físeán';

  @override
  String get about => 'Faoi';

  @override
  String get version => 'Leagan';

  @override
  String get checkForUpdates => 'Seiceáil le haghaidh nuashonruithe';

  @override
  String get checkingUpdates => 'Ag seiceáil le haghaidh nuashonruithe…';

  @override
  String get upToDate => 'Tá tú cothrom le dáta';

  @override
  String get updateAvailable => 'Tá leagan nua ar fáil';

  @override
  String get checkFailed => 'Níorbh fhéidir nuashonruithe a sheiceáil';

  @override
  String get viewRelease => 'Amharc ar an eisiúint';

  @override
  String get allReleases => 'Gach eisiúint';

  @override
  String get sourceCode => 'Cód foinseach';

  @override
  String get licence => 'Ceadúnas';

  @override
  String get licenceText => 'GNU Affero General Public Licence v3.0';

  @override
  String get openVideo => 'Seinn';

  @override
  String get audio => 'Fuaim';

  @override
  String get fullscreen => 'Lánscáileán';

  @override
  String get quality => 'Cáilíocht';

  @override
  String get playbackSpeed => 'Luas athsheinnte';

  @override
  String get speedNormal => 'Gnáth';

  @override
  String get searchResultsFor => 'Torthaí';

  @override
  String get corsNoticeTitle => 'Tá físeáin bacaithe sa bhrabhsálaí';

  @override
  String get corsNoticeBody =>
      'Ní cheadaíonn YouTube iarratais dhíreacha ó aipeanna gréasáin. Suiteáil síneadh CORS nó socraigh seachfhreastalaí i Socruithe.';

  @override
  String get corsFirefox => 'Breiseán Firefox';

  @override
  String get corsChrome => 'Síneadh Chrome';

  @override
  String get corsProxyLabel => 'Réimír sheachfhreastalaí CORS';

  @override
  String get corsProxyHint =>
      'Cuirtear URL an fhíse leis i bhfoirm ionchódaithe, mar shampla https://proxy.example/?url=';

  @override
  String get mcpServer => 'Freastalaí MCP';

  @override
  String get mcpServerHint =>
      'Lig d\'uirlisí AI físeáin a chuardach agus a sheinm';

  @override
  String get mcpServerFailed => 'Níorbh fhéidir an freastalaí MCP a thosú';

  @override
  String get mcpExport => 'Easpórtáil comhad an fhreastalaí';

  @override
  String get mcpExportHint =>
      'Sábháil comhad .mcpb ar féidir le cliaint é a iompórtáil';

  @override
  String mcpExportedTo(String path) {
    return 'Sábháilte go $path';
  }

  @override
  String get mcpExportFailed => 'Níorbh fhéidir an t-easpórtáil a shábháil';

  @override
  String get sleepTimer => 'Amchodlata';

  @override
  String sleepTimerMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nóiméad',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerEndOfVideo => 'Deireadh an fhíseáin';

  @override
  String get sleepTimerOff => 'Múchta';

  @override
  String get sponsorBlock => 'SponsorBlock';

  @override
  String get sponsorBlockHint => 'Scip míreanna urraithe sna físeáin';

  @override
  String get sponsorBlockAutoSkip => 'Scip go huathoibríoch';

  @override
  String get sponsorBlockAutoSkipHint =>
      'Taispeáin cnaipe scipeála ar an seinnteoir mura bhfuil sé ar siúl';

  @override
  String get sponsorBlockCategories => 'Catagóirí le scipeáil';

  @override
  String get skipSegment => 'Scip';

  @override
  String get done => 'Déanta';

  @override
  String get sponsorCategorySponsor => 'Urraíocht';

  @override
  String get sponsorCategorySelfpromo => 'Féinbholscaireacht';

  @override
  String get sponsorCategoryIntro => 'Intreoir';

  @override
  String get sponsorCategoryOutro => 'Coda deiridh';

  @override
  String get sponsorCategoryInteraction => 'Meabhrúchán idirghnímh';

  @override
  String get sponsorCategoryMusicOfftopic => 'Ceol neamhábhartha';

  @override
  String get deArrow => 'DeArrow';

  @override
  String get deArrowHint => 'Teidil agus mionsamhlacha ón bpobal';

  @override
  String get deArrowOff => 'Múchta';

  @override
  String get deArrowTitles => 'Teidil amháin';

  @override
  String get deArrowThumbnails => 'Mionsamhlacha amháin';

  @override
  String get deArrowBoth => 'Teidil agus mionsamhlacha';

  @override
  String get comments => 'Tráchtanna';

  @override
  String get loadMoreComments => 'Luchtaigh tuilleadh tráchtanna';

  @override
  String replyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count freagra',
    );
    return '$_temp0';
  }

  @override
  String get importSubscriptions => 'Iompórtáil síntiúis';

  @override
  String get importSubscriptionsHint =>
      'Ó chomhad OPML (NewPipe, FreeTube, Takeout)';

  @override
  String get exportSubscriptions => 'Easpórtáil síntiúis';

  @override
  String get exportSubscriptionsHint => 'Sábháil an liosta síntiús mar OPML';

  @override
  String subscriptionsImported(int imported, int failed) {
    return 'Iompórtáladh $imported cainéal, theip ar $failed';
  }

  @override
  String get subscriptionsImportFailed =>
      'Níorbh fhéidir an comhad OPML a léamh';

  @override
  String subscriptionsExportedTo(String path) {
    return 'Síntiúis easpórtáilte chuig $path';
  }

  @override
  String get subscriptionsExportFailed => 'Cealaíodh nó theip ar an easpórtáil';

  @override
  String get navWatchLater => 'Féach níos déanaí';

  @override
  String get watchLaterEmpty => 'Níl aon rud sábháilte';

  @override
  String get watchLaterAdd => 'Féach níos déanaí';

  @override
  String get watchLaterRemove => 'Bain as Féach níos déanaí';

  @override
  String videoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count físeán',
      many: '$count bhfíseán',
      few: '$count físeán',
      two: '$count físeán',
      one: '$count físeán',
    );
    return '$_temp0';
  }

  @override
  String playlistProgress(String playlist, int index, int total) {
    return '$playlist · $index/$total';
  }

  @override
  String get uploadNotifications => 'Fógraí uaslódála';

  @override
  String get uploadNotificationsHint =>
      'Cuir in iúl nuair a uaslódálann cainéil físeáin nua';

  @override
  String get uploadCheckInterval => 'Seiceáil uaslódáil';

  @override
  String everyMinutes(int minutes) {
    return 'Gach $minutes nóiméad';
  }
}
