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
      'Начинать воспроизведение сразу после открытия видео';

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
  String get audio => 'Аудио';

  @override
  String get fullscreen => 'На весь экран';

  @override
  String get quality => 'Качество';

  @override
  String get playbackSpeed => 'Скорость воспроизведения';

  @override
  String get speedNormal => 'Обычная';

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
}
