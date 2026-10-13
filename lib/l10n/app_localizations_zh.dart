// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'NewTube';

  @override
  String get navHome => '首页';

  @override
  String get navSearch => '搜索';

  @override
  String get navSubscriptions => '订阅';

  @override
  String get navHistory => '历史记录';

  @override
  String get navSettings => '设置';

  @override
  String get collapseSidebar => '收起侧边栏';

  @override
  String get expandSidebar => '展开侧边栏';

  @override
  String get searchHint => '搜索';

  @override
  String get loading => '加载中…';

  @override
  String get errorLoading => '出错了';

  @override
  String get retry => '重试';

  @override
  String get noVideos => '没有找到视频';

  @override
  String get views => '次观看';

  @override
  String get relatedVideos => '相关视频';

  @override
  String get description => '简介';

  @override
  String get subscribe => '订阅';

  @override
  String get subscribed => '已订阅';

  @override
  String get subscribers => '位订阅者';

  @override
  String get channelVideos => '视频';

  @override
  String get latestFromSubscriptions => '订阅的最新视频';

  @override
  String get channelsTitle => '频道';

  @override
  String get noSubscriptions => '还没有订阅';

  @override
  String get noSubscriptionsHint => '订阅频道后，他们的最新视频会显示在这里。';

  @override
  String get unsubscribe => '取消订阅';

  @override
  String get watchHistory => '观看历史';

  @override
  String get clearHistory => '清除历史记录';

  @override
  String get clearHistoryConfirm => '将删除所有观看记录和搜索记录。';

  @override
  String get cancel => '取消';

  @override
  String get clear => '清除';

  @override
  String get noHistory => '还没有观看记录';

  @override
  String get noHistoryHint => '你看过的视频会显示在这里。';

  @override
  String get noSearchHistory => '还没有搜索记录';

  @override
  String get noSearchHistoryHint => '你搜索过的内容会显示在这里。';

  @override
  String get removeSearchEntry => '移除';

  @override
  String get searchHistory => '搜索历史';

  @override
  String get searchHistoryHint => '记住你搜索过的内容';

  @override
  String get searchHistoryOff => '搜索历史已关闭';

  @override
  String get searchHistoryOffHint => '在设置中开启后，你的搜索会显示在这里。';

  @override
  String get theme => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeOled => 'OLED 纯黑';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get autoplay => '自动播放视频';

  @override
  String get autoplayHint => '打开视频后立即开始播放';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get checkingUpdates => '正在检查更新…';

  @override
  String get upToDate => '已是最新版本';

  @override
  String get updateAvailable => '有新版本可用';

  @override
  String get checkFailed => '无法检查更新';

  @override
  String get viewRelease => '查看该版本';

  @override
  String get allReleases => '所有版本';

  @override
  String get sourceCode => '源代码';

  @override
  String get licence => '许可证';

  @override
  String get licenceText => 'GNU Affero 通用公共许可证 v3.0';

  @override
  String get openVideo => '播放';

  @override
  String get audio => '音频';

  @override
  String get fullscreen => '全屏';

  @override
  String get quality => '画质';

  @override
  String get playbackSpeed => '播放速度';

  @override
  String get speedNormal => '正常';

  @override
  String get searchResultsFor => '搜索结果';

  @override
  String get corsNoticeTitle => '视频在浏览器里被拦截';

  @override
  String get corsNoticeBody => 'YouTube 不允许网页应用直接请求。请安装 CORS 扩展，或在设置中填写代理。';

  @override
  String get corsFirefox => 'Firefox 扩展';

  @override
  String get corsChrome => 'Chrome 扩展';

  @override
  String get corsProxyLabel => 'CORS 代理前缀';

  @override
  String get corsProxyHint =>
      '视频地址会以 URL 编码形式附加，例如 https://proxy.example/?url=';

  @override
  String get mcpServer => 'MCP 服务器';

  @override
  String get mcpServerHint => '允许 AI 工具搜索和播放视频';

  @override
  String get mcpServerFailed => '无法启动 MCP 服务器';

  @override
  String get mcpExport => '导出服务器文件';

  @override
  String get mcpExportHint => '保存客户端可导入的 .mcpb 文件';

  @override
  String mcpExportedTo(String path) {
    return '已保存到 $path';
  }

  @override
  String get mcpExportFailed => '无法保存导出文件';

  @override
  String get sleepTimer => '睡眠定时器';

  @override
  String sleepTimerMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerEndOfVideo => '视频播完时';

  @override
  String get sleepTimerOff => '关闭';

  @override
  String get sponsorBlock => 'SponsorBlock';

  @override
  String get sponsorBlockHint => '跳过视频中的赞助片段';

  @override
  String get sponsorBlockAutoSkip => '自动跳过';

  @override
  String get sponsorBlockAutoSkipHint => '关闭时在播放器上显示跳过按钮';

  @override
  String get sponsorBlockCategories => '跳过的片段类别';

  @override
  String get skipSegment => '跳过';

  @override
  String get done => '完成';

  @override
  String get sponsorCategorySponsor => '赞助';

  @override
  String get sponsorCategorySelfpromo => '自我推广';

  @override
  String get sponsorCategoryIntro => '片头';

  @override
  String get sponsorCategoryOutro => '片尾';

  @override
  String get sponsorCategoryInteraction => '互动提醒';

  @override
  String get sponsorCategoryMusicOfftopic => '离题音乐';

  @override
  String get deArrow => 'DeArrow';

  @override
  String get deArrowHint => '社区贡献的标题和缩略图';

  @override
  String get deArrowOff => '关闭';

  @override
  String get deArrowTitles => '仅标题';

  @override
  String get deArrowThumbnails => '仅缩略图';

  @override
  String get deArrowBoth => '标题和缩略图';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appTitle => 'NewTube';

  @override
  String get navHome => '首页';

  @override
  String get navSearch => '搜索';

  @override
  String get navSubscriptions => '订阅';

  @override
  String get navHistory => '历史记录';

  @override
  String get navSettings => '设置';

  @override
  String get collapseSidebar => '收起侧边栏';

  @override
  String get expandSidebar => '展开侧边栏';

  @override
  String get searchHint => '搜索';

  @override
  String get loading => '加载中…';

  @override
  String get errorLoading => '出错了';

  @override
  String get retry => '重试';

  @override
  String get noVideos => '没有找到视频';

  @override
  String get views => '次观看';

  @override
  String get relatedVideos => '相关视频';

  @override
  String get description => '简介';

  @override
  String get subscribe => '订阅';

  @override
  String get subscribed => '已订阅';

  @override
  String get subscribers => '位订阅者';

  @override
  String get channelVideos => '视频';

  @override
  String get latestFromSubscriptions => '订阅的最新视频';

  @override
  String get channelsTitle => '频道';

  @override
  String get noSubscriptions => '还没有订阅';

  @override
  String get noSubscriptionsHint => '订阅频道后，他们的最新视频会显示在这里。';

  @override
  String get unsubscribe => '取消订阅';

  @override
  String get watchHistory => '观看历史';

  @override
  String get clearHistory => '清除历史记录';

  @override
  String get clearHistoryConfirm => '将删除所有观看记录和搜索记录。';

  @override
  String get cancel => '取消';

  @override
  String get clear => '清除';

  @override
  String get noHistory => '还没有观看记录';

  @override
  String get noHistoryHint => '你看过的视频会显示在这里。';

  @override
  String get noSearchHistory => '还没有搜索记录';

  @override
  String get noSearchHistoryHint => '你搜索过的内容会显示在这里。';

  @override
  String get removeSearchEntry => '移除';

  @override
  String get searchHistory => '搜索历史';

  @override
  String get searchHistoryHint => '记住你搜索过的内容';

  @override
  String get searchHistoryOff => '搜索历史已关闭';

  @override
  String get searchHistoryOffHint => '在设置中开启后，你的搜索会显示在这里。';

  @override
  String get theme => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeOled => 'OLED 纯黑';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get autoplay => '自动播放视频';

  @override
  String get autoplayHint => '打开视频后立即开始播放';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get checkingUpdates => '正在检查更新…';

  @override
  String get upToDate => '已是最新版本';

  @override
  String get updateAvailable => '有新版本可用';

  @override
  String get checkFailed => '无法检查更新';

  @override
  String get viewRelease => '查看该版本';

  @override
  String get allReleases => '所有版本';

  @override
  String get sourceCode => '源代码';

  @override
  String get licence => '许可证';

  @override
  String get licenceText => 'GNU Affero 通用公共许可证 v3.0';

  @override
  String get openVideo => '播放';

  @override
  String get audio => '音频';

  @override
  String get fullscreen => '全屏';

  @override
  String get quality => '画质';

  @override
  String get playbackSpeed => '播放速度';

  @override
  String get speedNormal => '正常';

  @override
  String get searchResultsFor => '搜索结果';

  @override
  String get corsNoticeTitle => '视频在浏览器里被拦截';

  @override
  String get corsNoticeBody => 'YouTube 不允许网页应用直接请求。请安装 CORS 扩展，或在设置中填写代理。';

  @override
  String get corsFirefox => 'Firefox 扩展';

  @override
  String get corsChrome => 'Chrome 扩展';

  @override
  String get corsProxyLabel => 'CORS 代理前缀';

  @override
  String get corsProxyHint =>
      '视频地址会以 URL 编码形式附加，例如 https://proxy.example/?url=';

  @override
  String get mcpServer => 'MCP 服务器';

  @override
  String get mcpServerHint => '允许 AI 工具搜索和播放视频';

  @override
  String get mcpServerFailed => '无法启动 MCP 服务器';

  @override
  String get mcpExport => '导出服务器文件';

  @override
  String get mcpExportHint => '保存客户端可导入的 .mcpb 文件';

  @override
  String mcpExportedTo(String path) {
    return '已保存到 $path';
  }

  @override
  String get mcpExportFailed => '无法保存导出文件';

  @override
  String get sleepTimer => '睡眠定时器';

  @override
  String sleepTimerMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerEndOfVideo => '视频播完时';

  @override
  String get sleepTimerOff => '关闭';

  @override
  String get sponsorBlock => 'SponsorBlock';

  @override
  String get sponsorBlockHint => '跳过视频中的赞助片段';

  @override
  String get sponsorBlockAutoSkip => '自动跳过';

  @override
  String get sponsorBlockAutoSkipHint => '关闭时在播放器上显示跳过按钮';

  @override
  String get sponsorBlockCategories => '跳过的片段类别';

  @override
  String get skipSegment => '跳过';

  @override
  String get done => '完成';

  @override
  String get sponsorCategorySponsor => '赞助';

  @override
  String get sponsorCategorySelfpromo => '自我推广';

  @override
  String get sponsorCategoryIntro => '片头';

  @override
  String get sponsorCategoryOutro => '片尾';

  @override
  String get sponsorCategoryInteraction => '互动提醒';

  @override
  String get sponsorCategoryMusicOfftopic => '离题音乐';

  @override
  String get deArrow => 'DeArrow';

  @override
  String get deArrowHint => '社区贡献的标题和缩略图';

  @override
  String get deArrowOff => '关闭';

  @override
  String get deArrowTitles => '仅标题';

  @override
  String get deArrowThumbnails => '仅缩略图';

  @override
  String get deArrowBoth => '标题和缩略图';
}
