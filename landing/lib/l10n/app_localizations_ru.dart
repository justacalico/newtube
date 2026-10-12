// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class LandingLocalizationsRu extends LandingLocalizations {
  LandingLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get tagline => 'Смотрите YouTube без рекламы, слежки и лишнего.';

  @override
  String get download => 'Скачать';

  @override
  String get openApp => 'Открыть веб-версию';

  @override
  String get features => 'Почему NewTube';

  @override
  String get featurePrivacy => 'Приватность по умолчанию';

  @override
  String get featurePrivacyText =>
      'Аккаунт не нужен. Подписки и история хранятся на устройстве.';

  @override
  String get featurePlatforms => 'Все платформы';

  @override
  String get featurePlatformsText =>
      'Android, iOS, Linux, Windows и macOS из одной кодовой базы.';

  @override
  String get featurePlayer => 'Настоящий плеер';

  @override
  String get featurePlayerText =>
      'Выбор качества, режим только аудио и полноценный полный экран.';

  @override
  String get featureSubs => 'Локальные подписки';

  @override
  String get featureSubsText => 'Подписывайтесь на каналы без входа в аккаунт.';

  @override
  String get screenshots => 'Скриншоты';

  @override
  String get downloads => 'Загрузки';

  @override
  String get downloadsHint =>
      'Скачайте последний релиз для вашей платформы прямо с GitLab.';

  @override
  String get viewOnGitLab => 'Все релизы на GitLab';

  @override
  String get loadReleasesFailed => 'Не удалось загрузить релизы';

  @override
  String get retry => 'Повторить';

  @override
  String get releasedOn => 'Выпущено';

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
  String get sourceCode => 'Исходный код';

  @override
  String get appSectionTitle => 'Попробуйте в браузере';

  @override
  String get appSectionText => 'Приложение целиком работает и в вебе.';
}
