// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'NewTube';

  @override
  String get navHome => 'Главная';

  @override
  String get navTrending => 'В тренде';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navSubscriptions => 'Подписки';

  @override
  String get navHistory => 'История';

  @override
  String get navSettings => 'Настройки';

  @override
  String get collapseSidebar => 'Свернуть боковую панель';

  @override
  String get expandSidebar => 'Развернуть боковую панель';

  @override
  String get searchHint => 'Поиск';

  @override
  String get loading => 'Загрузка…';

  @override
  String get errorLoading => 'Что-то пошло не так';

  @override
  String get retry => 'Повторить';

  @override
  String get noVideos => 'Видео не найдены';

  @override
  String get views => 'просмотров';

  @override
  String get relatedVideos => 'Похожие видео';

  @override
  String get description => 'Описание';

  @override
  String get subscribe => 'Подписаться';

  @override
  String get subscribed => 'Вы подписаны';

  @override
  String get subscribers => 'подписчиков';

  @override
  String get channelVideos => 'Видео';

  @override
  String get latestFromSubscriptions => 'Новое в подписках';

  @override
  String get channelsTitle => 'Каналы';

  @override
  String get noSubscriptions => 'Пока нет подписок';

  @override
  String get noSubscriptionsHint =>
      'Подпишитесь на каналы, и их новые видео появятся здесь.';

  @override
  String get unsubscribe => 'Отписаться';

  @override
  String get watchHistory => 'История просмотра';

  @override
  String get watched => 'Просмотрено';

  @override
  String get clearHistory => 'Очистить историю';

  @override
  String get clearHistoryConfirm =>
      'Будут удалены все просмотренные видео и поисковые запросы.';

  @override
  String get cancel => 'Отмена';

  @override
  String get clear => 'Очистить';

  @override
  String get noHistory => 'Вы ещё ничего не смотрели';

  @override
  String get noHistoryHint => 'Просмотренные видео будут показаны здесь.';

  @override
  String get noSearchHistory => 'Вы ещё ничего не искали';

  @override
  String get noSearchHistoryHint => 'Ваши запросы будут показаны здесь.';

  @override
  String get removeSearchEntry => 'Убрать';

  @override
  String get searchHistory => 'История поиска';

  @override
  String get searchHistoryHint => 'Запоминать поисковые запросы';

  @override
  String get searchHistoryOff => 'История поиска отключена';

  @override
  String get searchHistoryOffHint =>
      'Включите её в настройках, чтобы видеть запросы здесь.';

  @override
  String get filterSort => 'Сортировка';

  @override
  String get filterType => 'Тип';

  @override
  String get filterUploadDate => 'Дата загрузки';

  @override
  String get filterDuration => 'Длительность';

  @override
  String get sortRelevance => 'По релевантности';

  @override
  String get sortDate => 'По дате';

  @override
  String get sortViews => 'По просмотрам';

  @override
  String get sortRating => 'По оценке';

  @override
  String get typeAll => 'Все';

  @override
  String get typeVideo => 'Видео';

  @override
  String get typeChannel => 'Каналы';

  @override
  String get typePlaylist => 'Плейлисты';

  @override
  String get typeLive => 'Трансляции';

  @override
  String get uploadAny => 'За всё время';

  @override
  String get uploadHour => 'За час';

  @override
  String get uploadToday => 'Сегодня';

  @override
  String get uploadWeek => 'За неделю';

  @override
  String get uploadMonth => 'За месяц';

  @override
  String get uploadYear => 'За год';

  @override
  String get durationAny => 'Любая';

  @override
  String get durationShort => 'До 4 минут';

  @override
  String get durationMedium => '4-20 минут';

  @override
  String get durationLong => 'Больше 20 минут';

  @override
  String get theme => 'Тема';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeOled => 'OLED';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Системный';

  @override
  String get autoplay => 'Автовоспроизведение';

  @override
  String get autoplayHint =>
      'Автоматически воспроизводить видео и следующее за ним';

  @override
  String get audioOnly => 'Только аудио';

  @override
  String get audioOnlyHint => 'Воспроизводить только звуковую дорожку';

  @override
  String get defaultQuality => 'Качество по умолчанию';

  @override
  String get qualityAuto => 'Авто';

  @override
  String get qualityLowest => 'Минимальное';

  @override
  String get defaultSpeed => 'Скорость по умолчанию';

  @override
  String get chapters => 'Главы';

  @override
  String get live => 'Прямой эфир';

  @override
  String get upcoming => 'Скоро';

  @override
  String get statsForNerds => 'Статистика для сисадминов';

  @override
  String get statsVideo => 'Видео';

  @override
  String get statsAudio => 'Аудио';

  @override
  String get statsPosition => 'Позиция';

  @override
  String get statsBuffered => 'буфер';

  @override
  String get statsRate => 'Скорость';

  @override
  String get statsVolume => 'Громкость';

  @override
  String get showDislikes => 'Показывать дизлайки';

  @override
  String get showDislikesHint =>
      'Оценка дизлайков через Return YouTube Dislike';

  @override
  String get dislikes => 'дизлайков';

  @override
  String get share => 'Поделиться';

  @override
  String get copyLink => 'Копировать ссылку';

  @override
  String get copyLinkAtTime => 'Копировать ссылку с меткой времени';

  @override
  String get watchOnYouTube => 'Смотреть на YouTube';

  @override
  String get copiedToClipboard => 'Ссылка скопирована';

  @override
  String get showReplies => 'Показать ответы';

  @override
  String get hideReplies => 'Скрыть ответы';

  @override
  String get creator => 'Автор канала';

  @override
  String get commentsSort => 'Сортировка комментариев';

  @override
  String get commentsTop => 'Популярные';

  @override
  String get commentsNewest => 'Сначала новые';

  @override
  String get upNext => 'Следующее';

  @override
  String get playNow => 'Играть сейчас';

  @override
  String get videoFit => 'Масштаб видео';

  @override
  String get fitContain => 'По размеру';

  @override
  String get fitCover => 'Заполнить';

  @override
  String get fitFill => 'Растянуть';

  @override
  String get about => 'О программе';

  @override
  String get version => 'Версия';

  @override
  String get checkForUpdates => 'Проверить обновления';

  @override
  String get checkingUpdates => 'Проверка обновлений…';

  @override
  String get upToDate => 'У вас последняя версия';

  @override
  String get updateAvailable => 'Доступна новая версия';

  @override
  String get checkFailed => 'Не удалось проверить обновления';

  @override
  String get viewRelease => 'Открыть релиз';

  @override
  String get allReleases => 'Все релизы';

  @override
  String get sourceCode => 'Исходный код';

  @override
  String get licence => 'Лицензия';

  @override
  String get licenceText => 'GNU Affero General Public License v3.0';

  @override
  String get openVideo => 'Смотреть';

  @override
  String get replay => 'Повторить';

  @override
  String get nextVideo => 'Следующее видео';

  @override
  String get play => 'Воспроизвести';

  @override
  String get pause => 'Пауза';

  @override
  String get close => 'Закрыть';

  @override
  String get audio => 'Аудио';

  @override
  String get fullscreen => 'На весь экран';

  @override
  String get quality => 'Качество';

  @override
  String get playbackSpeed => 'Скорость воспроизведения';

  @override
  String get mute => 'Выключить звук';

  @override
  String get unmute => 'Включить звук';

  @override
  String get volume => 'Громкость';

  @override
  String get repeat => 'Повтор';

  @override
  String get repeatOff => 'Выкл.';

  @override
  String get repeatAll => 'Все';

  @override
  String get repeatOne => 'Одно видео';

  @override
  String get shuffle => 'В случайном порядке';

  @override
  String get speedNormal => 'Обычная';

  @override
  String get captions => 'Субтитры';

  @override
  String get captionsOff => 'Выкл.';

  @override
  String get searchResultsFor => 'Результаты';

  @override
  String get corsNoticeTitle => 'Видео заблокировано в браузере';

  @override
  String get corsNoticeBody =>
      'YouTube не разрешает прямые запросы из веб-приложений. Установите CORS-расширение или укажите прокси в настройках.';

  @override
  String get corsFirefox => 'Дополнение Firefox';

  @override
  String get corsChrome => 'Расширение Chrome';

  @override
  String get corsProxyLabel => 'Префикс CORS-прокси';

  @override
  String get corsProxyHint =>
      'URL видео добавляется в кодированном виде, например https://proxy.example/?url=';

  @override
  String get mcpServer => 'MCP-сервер';

  @override
  String get mcpServerHint =>
      'Разрешить ИИ-инструментам искать и воспроизводить видео';

  @override
  String get mcpServerFailed => 'Не удалось запустить MCP-сервер';

  @override
  String get mcpExport => 'Экспорт файла сервера';

  @override
  String get mcpExportHint => 'Сохранить .mcpb-файл для импорта клиентами';

  @override
  String mcpExportedTo(String path) {
    return 'Сохранено в $path';
  }

  @override
  String get mcpExportFailed => 'Не удалось сохранить экспорт';

  @override
  String get sleepTimer => 'Таймер сна';

  @override
  String sleepTimerMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минуты',
      many: '$count минут',
      few: '$count минуты',
      one: '$count минута',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerEndOfVideo => 'В конце видео';

  @override
  String get sleepTimerOff => 'Выкл';

  @override
  String get sponsorBlock => 'SponsorBlock';

  @override
  String get sponsorBlockHint => 'Пропускать спонсорские вставки в видео';

  @override
  String get sponsorBlockAutoSkip => 'Пропускать автоматически';

  @override
  String get sponsorBlockAutoSkipHint =>
      'Если выключено, показывать кнопку пропуска';

  @override
  String get sponsorBlockCategories => 'Категории для пропуска';

  @override
  String get skipSegment => 'Пропустить';

  @override
  String get done => 'Готово';

  @override
  String get sponsorCategorySponsor => 'Реклама';

  @override
  String get sponsorCategorySelfpromo => 'Самопиар';

  @override
  String get sponsorCategoryIntro => 'Вступление';

  @override
  String get sponsorCategoryOutro => 'Концовка';

  @override
  String get sponsorCategoryInteraction => 'Призыв к действию';

  @override
  String get sponsorCategoryMusicOfftopic => 'Музыка не по теме';

  @override
  String get deArrow => 'DeArrow';

  @override
  String get deArrowHint => 'Заголовки и обложки от сообщества';

  @override
  String get deArrowOff => 'Выкл';

  @override
  String get deArrowTitles => 'Только заголовки';

  @override
  String get deArrowThumbnails => 'Только обложки';

  @override
  String get deArrowBoth => 'Заголовки и обложки';

  @override
  String get comments => 'Комментарии';

  @override
  String get loadMoreComments => 'Загрузить ещё';

  @override
  String replyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ответа',
      many: '$count ответов',
      few: '$count ответа',
      one: '$count ответ',
    );
    return '$_temp0';
  }

  @override
  String get importSubscriptions => 'Импорт подписок';

  @override
  String get importSubscriptionsHint =>
      'Из файла OPML (NewPipe, FreeTube, Takeout)';

  @override
  String get exportSubscriptions => 'Экспорт подписок';

  @override
  String get exportSubscriptionsHint => 'Сохранить подписки в файл OPML';

  @override
  String subscriptionsImported(int imported, int failed) {
    return 'Импортировано каналов: $imported, ошибок: $failed';
  }

  @override
  String get subscriptionsImportFailed => 'Не удалось прочитать файл OPML';

  @override
  String subscriptionsExportedTo(String path) {
    return 'Подписки сохранены в $path';
  }

  @override
  String get subscriptionsExportFailed => 'Экспорт отменён или не удался';

  @override
  String get navWatchLater => 'Смотреть позже';

  @override
  String get watchLaterEmpty => 'Ничего не сохранено';

  @override
  String get watchLaterAdd => 'Смотреть позже';

  @override
  String get watchLaterRemove => 'Убрать из «Смотреть позже»';

  @override
  String videoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count видео',
      many: '$count видео',
      few: '$count видео',
      one: '$count видео',
    );
    return '$_temp0';
  }

  @override
  String playlistProgress(String playlist, int index, int total) {
    return '$playlist · $index/$total';
  }

  @override
  String get uploadNotifications => 'Уведомления о видео';

  @override
  String get uploadNotificationsHint =>
      'Уведомлять о новых видео у подписанных каналов';

  @override
  String get uploadCheckInterval => 'Проверять загрузки';

  @override
  String everyMinutes(int minutes) {
    return 'Каждые $minutes мин';
  }

  @override
  String get pictureInPicture => 'Картинка в картинке';

  @override
  String get navPlaylists => 'Плейлисты';

  @override
  String get playlistsEmpty => 'Плейлистов пока нет';

  @override
  String get playlistsEmptyHint =>
      'Создайте плейлист, чтобы упорядочить видео.';

  @override
  String get newPlaylist => 'Новый плейлист';

  @override
  String get playlistNameHint => 'Название плейлиста';

  @override
  String get create => 'Создать';

  @override
  String get rename => 'Переименовать';

  @override
  String get renamePlaylist => 'Переименовать плейлист';

  @override
  String get delete => 'Удалить';

  @override
  String get deletePlaylist => 'Удалить плейлист';

  @override
  String get deletePlaylistConfirm => 'Видео останутся в вашей истории.';

  @override
  String get addToPlaylist => 'Добавить в плейлист';

  @override
  String get removeFromPlaylist => 'Удалить из плейлиста';

  @override
  String get playlistEmpty => 'Этот плейлист пуст';

  @override
  String get savePlaylist => 'Сохранить плейлист';

  @override
  String get playlistSaved => 'Сохранено в ваших плейлистах';

  @override
  String get videoActions => 'Ещё';

  @override
  String get hideShorts => 'Скрыть Shorts';

  @override
  String get hideShortsHint => 'Убрать Shorts из лент и поиска';

  @override
  String get shortsBadge => 'SHORTS';
}
