import 'dart:convert';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_update.dart';
import '../../services/mcp_export.dart';
import '../../services/mcp_server.dart';
import '../../services/backup.dart';
import '../../services/opml.dart';
import '../../utils/debug_log.dart';
import '../../services/version_checker.dart';
import '../../state/app_state.dart';
import '../../state/settings_store.dart';
import '../shell/title_bar.dart' show isDesktopPlatform;

const languageNames = {
  'en_GB': 'Traditional English',
  'zh_Hans': '简体中文',
  'ru': 'Русский',
  'ga': 'Gaeilge',
};

const sponsorBlockCategoryIds = [
  'sponsor',
  'selfpromo',
  'intro',
  'outro',
  'interaction',
  'music_offtopic',
  'preview',
  'filler',
  'exclusive_access',
  'chapter',
];

const sponsorBlockJumpCategory = 'poi_highlight';

String _localeKey(Locale locale) => locale.countryCode == null
    ? locale.languageCode
    : '${locale.languageCode}_${locale.countryCode}';

class _SettingsDropdown<T> extends StatelessWidget {
  const _SettingsDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        onChanged: onChanged,
        items: items,
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _version = '';
  bool _checking = false;
  bool _failed = false;
  AppUpdate? _result;

  @override
  void initState() {
    super.initState();
    AppScope.read(context).packageInfo().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  Future<void> _exportMcpb() async {
    final state = AppScope.read(context);
    final save = state.saveFile;
    if (save == null) return;
    final info = await state.packageInfo();
    final bundle = mcpbExport(
      name: 'newtube',
      version: info.version,
      url: state.mcpServer?.url ?? mcpDefaultUrl,
    );
    final path = await save('newtube.mcpb', bundle, extension: 'mcpb');
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path == null ? l10n.mcpExportFailed : l10n.mcpExportedTo(path),
        ),
      ),
    );
  }

  Future<void> _importSubscriptions() async {
    final state = AppScope.read(context);
    final open = state.openFile;
    if (open == null) return;
    final text = await open();
    if (!mounted || text == null) return;
    final l10n = AppLocalizations.of(context);
    try {
      final result = await importOpml(
        text,
        state.api,
        state.subscriptions,
        state.prefs,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.subscriptionsImported(result.imported, result.failed),
          ),
        ),
      );
    } catch (e) {
      debugLog('[settings] opml import failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.subscriptionsImportFailed)));
    }
  }

  Future<void> _manageHidden() async {
    final state = AppScope.read(context);
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: state.hidden,
        builder: (context, _) => AlertDialog(
          title: Text(l10n.hiddenItems),
          content: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final id in state.hidden.channels)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.person_off_outlined),
                    title: Text(id, maxLines: 1),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () =>
                          state.hidden.unhideChannel(id, state.prefs),
                    ),
                  ),
                for (final id in state.hidden.videos)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.visibility_off_outlined),
                    title: Text(id, maxLines: 1),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () =>
                          state.hidden.unhideVideo(id, state.prefs),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _manageGroups() async {
    final state = AppScope.read(context);
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: state.subscriptions,
        builder: (context, _) {
          final groups = state.subscriptions.groups;
          return AlertDialog(
            title: Text(l10n.manageGroups),
            content: groups.isEmpty
                ? Text(l10n.noGroup)
                : Wrap(
                    spacing: 8,
                    children: [
                      for (final g in groups)
                        InputChip(
                          label: Text(g),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () =>
                              state.subscriptions.deleteGroup(g, state.prefs),
                        ),
                    ],
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.close),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportBackup() async {
    final state = AppScope.read(context);
    final save = state.saveFile;
    if (save == null) return;
    final l10n = AppLocalizations.of(context);
    final path = await save(
      'newtube_backup.json',
      utf8.encode(exportBackup(state.prefs)),
      extension: 'json',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path == null ? l10n.exportCancelled : l10n.backupExportedTo(path),
        ),
      ),
    );
  }

  Future<void> _importBackup() async {
    final state = AppScope.read(context);
    final open = state.openFile;
    if (open == null) return;
    final text = await open();
    if (!mounted || text == null) return;
    final l10n = AppLocalizations.of(context);
    try {
      final count = await importBackup(text, state.prefs);
      await state.reloadStores();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.backupRestored(count))));
    } catch (e) {
      debugLog('[settings] backup import failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.backupImportFailed)));
    }
  }

  Future<void> _exportSubscriptions() async {
    final state = AppScope.read(context);
    final save = state.saveFile;
    if (save == null) return;
    final l10n = AppLocalizations.of(context);
    final path = await save(
      'newtube_subscriptions.opml',
      extension: 'opml',
      utf8.encode(buildOpml(state.subscriptions.channels)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path == null
              ? l10n.subscriptionsExportFailed
              : l10n.subscriptionsExportedTo(path),
        ),
      ),
    );
  }

  String _categoryLabel(AppLocalizations l10n, String id) => switch (id) {
    'selfpromo' => l10n.sponsorCategorySelfpromo,
    'intro' => l10n.sponsorCategoryIntro,
    'outro' => l10n.sponsorCategoryOutro,
    'interaction' => l10n.sponsorCategoryInteraction,
    'music_offtopic' => l10n.sponsorCategoryMusicOfftopic,
    'preview' => l10n.sponsorCategoryPreview,
    'filler' => l10n.sponsorCategoryFiller,
    'poi_highlight' => l10n.sponsorCategoryPoiHighlight,
    'exclusive_access' => l10n.sponsorCategoryExclusiveAccess,
    'chapter' => l10n.sponsorCategoryChapter,
    _ => l10n.sponsorCategorySponsor,
  };

  Future<void> _editSponsorBlockCategories() async {
    final state = AppScope.read(context);
    final l10n = AppLocalizations.of(context);
    final selected = {...state.settings.sponsorBlockCategories};
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(l10n.sponsorBlockCategories),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final id in [
                ...sponsorBlockCategoryIds,
                sponsorBlockJumpCategory,
              ])
                CheckboxListTile(
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(_categoryLabel(l10n, id)),
                  value: selected.contains(id),
                  onChanged: (checked) => setLocal(
                    () => checked == true
                        ? selected.add(id)
                        : selected.remove(id),
                  ),
                ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.done),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    state.settings.setSponsorBlockCategories(selected, state.prefs);
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _failed = false;
      _result = null;
    });
    final update = await AppScope.of(context).checkForUpdate();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _failed = update == null;
      _result = update;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final result = _result ?? state.update;

    return ListenableBuilder(
      listenable: Listenable.merge([
        state,
        state.settings,
        state.history,
        state.searchHistory,
      ]),
      builder: (context, _) {
        final settings = state.settings;
        final mcp = state.mcpServer;
        return ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.format_color_fill_outlined),
              title: Text(l10n.accentColor),
              subtitle: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final color in const [
                      0xFFD32F2F,
                      0xFF1976D2,
                      0xFF388E3C,
                      0xFFF57C00,
                      0xFF7B1FA2,
                      0xFF0097A7,
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 6, top: 6),
                        child: InkWell(
                          onTap: () =>
                              settings.setAccentColor(color, state.prefs),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(color),
                            child: settings.accentColor == color
                                ? const Icon(Icons.check, size: 14)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(l10n.theme),
              trailing: _SettingsDropdown<AppTheme>(
                value: settings.theme,
                onChanged: (theme) {
                  if (theme != null) settings.setTheme(theme, state.prefs);
                },
                items: [
                  DropdownMenuItem(
                    value: AppTheme.system,
                    child: Text(l10n.themeSystem),
                  ),
                  DropdownMenuItem(
                    value: AppTheme.light,
                    child: Text(l10n.themeLight),
                  ),
                  DropdownMenuItem(
                    value: AppTheme.dark,
                    child: Text(l10n.themeDark),
                  ),
                  DropdownMenuItem(
                    value: AppTheme.oled,
                    child: Text(l10n.themeOled),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.language),
              trailing: _SettingsDropdown<String>(
                value: settings.locale == null
                    ? 'system'
                    : _localeKey(settings.locale!),
                onChanged: (key) {
                  if (key == null) return;
                  if (key == 'system') {
                    settings.setLocale(null, state.prefs);
                    return;
                  }
                  for (final locale in supportedLocales) {
                    if (_localeKey(locale) == key) {
                      settings.setLocale(locale, state.prefs);
                      return;
                    }
                  }
                },
                items: [
                  DropdownMenuItem(
                    value: 'system',
                    child: Text(l10n.languageSystem),
                  ),
                  for (final locale in supportedLocales)
                    DropdownMenuItem(
                      value: _localeKey(locale),
                      child: Text(languageNames[_localeKey(locale)]!),
                    ),
                ],
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.play_circle_outline),
              title: Text(l10n.autoplay),
              subtitle: Text(l10n.autoplayHint),
              value: settings.autoplay,
              onChanged: (value) => settings.setAutoplay(value, state.prefs),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.headphones_outlined),
              title: Text(l10n.audioOnly),
              subtitle: Text(l10n.audioOnlyHint),
              value: settings.audioOnly,
              onChanged: (value) => settings.setAudioOnly(value, state.prefs),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.movie_outlined),
              title: Text(l10n.hideShorts),
              subtitle: Text(l10n.hideShortsHint),
              value: settings.hideShorts,
              onChanged: (value) => settings.setHideShorts(value, state.prefs),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.visibility_off_outlined),
              title: Text(l10n.hideWatched),
              subtitle: Text(l10n.hideWatchedHint),
              value: settings.hideWatched,
              onChanged: (value) => settings.setHideWatched(value, state.prefs),
            ),
            ListTile(
              leading: const Icon(Icons.view_list_outlined),
              title: Text(l10n.feedLayout),
              trailing: _SettingsDropdown<int>(
                value: settings.feedDensity,
                onChanged: (value) {
                  if (value != null) {
                    settings.setFeedDensity(value, state.prefs);
                  }
                },
                items: [
                  DropdownMenuItem(value: 0, child: Text(l10n.feedGrid)),
                  DropdownMenuItem(value: 1, child: Text(l10n.feedList)),
                  DropdownMenuItem(value: 2, child: Text(l10n.feedCompact)),
                ],
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.data_saver_off_outlined),
              title: Text(l10n.dataSaver),
              subtitle: Text(l10n.dataSaverHint),
              value: settings.dataSaver,
              onChanged: (value) => settings.setDataSaver(value, state.prefs),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.comment_outlined),
              title: Text(l10n.showComments),
              value: settings.showComments,
              onChanged: (value) =>
                  settings.setShowComments(value, state.prefs),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.video_library_outlined),
              title: Text(l10n.showRelated),
              value: settings.showRelated,
              onChanged: (value) => settings.setShowRelated(value, state.prefs),
            ),
            ListTile(
              leading: const Icon(Icons.high_quality_outlined),
              title: Text(l10n.defaultQuality),
              trailing: _SettingsDropdown<int>(
                value: settings.preferredQuality,
                onChanged: (value) {
                  if (value != null) {
                    settings.setPreferredQuality(value, state.prefs);
                  }
                },
                items: [
                  DropdownMenuItem(value: 0, child: Text(l10n.qualityAuto)),
                  for (final pixels in const [2160, 1440, 1080, 720, 480, 360])
                    DropdownMenuItem(value: pixels, child: Text('${pixels}p')),
                  DropdownMenuItem(value: -1, child: Text(l10n.qualityLowest)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: Text(l10n.preferredCodec),
              trailing: _SettingsDropdown<int>(
                value: settings.preferredCodec,
                onChanged: (value) {
                  if (value != null) {
                    settings.setPreferredCodec(value, state.prefs);
                  }
                },
                items: [
                  DropdownMenuItem(value: 0, child: Text(l10n.codecAuto)),
                  DropdownMenuItem(value: 1, child: Text(l10n.codecAvc)),
                  DropdownMenuItem(value: 2, child: Text(l10n.codecVp9)),
                  DropdownMenuItem(value: 3, child: Text(l10n.codecAv1)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.speed),
              title: Text(l10n.defaultSpeed),
              trailing: _SettingsDropdown<double>(
                value: settings.defaultSpeed,
                onChanged: (value) {
                  if (value != null) {
                    settings.setDefaultSpeed(value, state.prefs);
                  }
                },
                items: [
                  for (final rate in const [
                    0.25,
                    0.5,
                    0.75,
                    1.0,
                    1.25,
                    1.5,
                    1.75,
                    2.0,
                  ])
                    DropdownMenuItem(
                      value: rate,
                      child: Text(rate == 1.0 ? l10n.speedNormal : '${rate}x'),
                    ),
                ],
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.thumb_down_outlined),
              title: Text(l10n.showDislikes),
              subtitle: Text(l10n.showDislikesHint),
              value: settings.rydEnabled,
              onChanged: (value) => settings.setRydEnabled(value, state.prefs),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.content_cut_outlined),
              title: Text(l10n.sponsorBlock),
              subtitle: Text(l10n.sponsorBlockHint),
              value: settings.sponsorBlockEnabled,
              onChanged: (value) =>
                  settings.setSponsorBlockEnabled(value, state.prefs),
            ),
            if (settings.sponsorBlockEnabled) ...[
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: SwitchListTile(
                  secondary: const Icon(Icons.fast_forward_outlined),
                  title: Text(l10n.sponsorBlockAutoSkip),
                  subtitle: Text(l10n.sponsorBlockAutoSkipHint),
                  value: settings.sponsorBlockAutoSkip,
                  onChanged: (value) =>
                      settings.setSponsorBlockAutoSkip(value, state.prefs),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(l10n.sponsorBlockCategories),
                  subtitle: Text(
                    [
                      for (final id in sponsorBlockCategoryIds)
                        if (settings.sponsorBlockCategories.contains(id))
                          _categoryLabel(l10n, id),
                    ].join(', '),
                  ),
                  onTap: _editSponsorBlockCategories,
                ),
              ),
            ],
            if (state.openFile != null)
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: Text(l10n.importSubscriptions),
                subtitle: Text(l10n.importSubscriptionsHint),
                onTap: _importSubscriptions,
              ),
            if (state.saveFile != null)
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: Text(l10n.exportSubscriptions),
                subtitle: Text(l10n.exportSubscriptionsHint),
                onTap: _exportSubscriptions,
              ),
            if (state.saveFile != null)
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: Text(l10n.exportBackup),
                subtitle: Text(l10n.exportBackupHint),
                onTap: _exportBackup,
              ),
            ListenableBuilder(
              listenable: state.hidden,
              builder: (context, _) {
                final count =
                    state.hidden.videos.length + state.hidden.channels.length;
                if (count == 0) return const SizedBox.shrink();
                return ListTile(
                  leading: const Icon(Icons.visibility_off),
                  title: Text(l10n.hiddenItems),
                  subtitle: Text('$count'),
                  onTap: () => _manageHidden(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_work_outlined),
              title: Text(l10n.manageGroups),
              subtitle: Text(l10n.subscriptionGroups),
              onTap: _manageGroups,
            ),
            if (state.openFile != null)
              ListTile(
                leading: const Icon(Icons.settings_backup_restore),
                title: Text(l10n.importBackup),
                subtitle: Text(l10n.importBackupHint),
                onTap: _importBackup,
              ),
            ListTile(
              leading: const Icon(Icons.title_outlined),
              title: Text(l10n.deArrow),
              subtitle: Text(l10n.deArrowHint),
              trailing: _SettingsDropdown<DeArrowMode>(
                value: settings.deArrowMode,
                onChanged: (mode) {
                  if (mode != null) settings.setDeArrowMode(mode, state.prefs);
                },
                items: [
                  DropdownMenuItem(
                    value: DeArrowMode.off,
                    child: Text(l10n.deArrowOff),
                  ),
                  DropdownMenuItem(
                    value: DeArrowMode.titles,
                    child: Text(l10n.deArrowTitles),
                  ),
                  DropdownMenuItem(
                    value: DeArrowMode.thumbnails,
                    child: Text(l10n.deArrowThumbnails),
                  ),
                  DropdownMenuItem(
                    value: DeArrowMode.both,
                    child: Text(l10n.deArrowBoth),
                  ),
                ],
              ),
            ),
            if (state.uploads != null) ...[
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: Text(l10n.uploadNotifications),
                subtitle: Text(l10n.uploadNotificationsHint),
                value: settings.uploadNotificationsEnabled,
                onChanged: (value) =>
                    settings.setUploadNotificationsEnabled(value, state.prefs),
              ),
              if (settings.uploadNotificationsEnabled)
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(l10n.uploadCheckInterval),
                  trailing: _SettingsDropdown<int>(
                    value: settings.uploadCheckIntervalMinutes,
                    onChanged: (minutes) {
                      if (minutes != null) {
                        settings.setUploadCheckIntervalMinutes(
                          minutes,
                          state.prefs,
                        );
                      }
                    },
                    items: [
                      for (final minutes in const [15, 30, 60, 120])
                        DropdownMenuItem(
                          value: minutes,
                          child: Text(l10n.everyMinutes(minutes)),
                        ),
                    ],
                  ),
                ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.swap_calls_outlined),
              title: Text(l10n.fallbackBackend),
              subtitle: Text(l10n.fallbackBackendHint),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                initialValue: settings.fallbackBackend,
                decoration: const InputDecoration(hintText: 'https://yewtu.be'),
                onChanged: (value) =>
                    settings.setFallbackBackend(value, state.prefs),
              ),
            ),
            if (!state.isWeb) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.vpn_lock_outlined),
                title: Text(l10n.networkProxy),
                subtitle: Text(l10n.networkProxyHint),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  initialValue: settings.networkProxy,
                  decoration: const InputDecoration(
                    hintText: 'socks5://127.0.0.1:9050',
                  ),
                  onChanged: (value) =>
                      settings.setNetworkProxy(value, state.prefs),
                ),
              ),
            ],
            if (state.isWeb) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.public),
                title: Text(l10n.corsProxyLabel),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextFormField(
                    initialValue: settings.proxyPrefix,
                    decoration: InputDecoration(
                      hintText: 'https://proxy.example/?url=',
                      helperText: l10n.corsProxyHint,
                    ),
                    onChanged: (value) =>
                        settings.setProxyPrefix(value, state.prefs),
                  ),
                ),
              ),
            ],
            if (isDesktopPlatform) ...[
              SwitchListTile(
                secondary: const Icon(Icons.hub_outlined),
                title: Text(l10n.mcpServer),
                subtitle: Text(
                  mcp != null && mcp.running
                      ? mcp.url!
                      : state.mcpError != null
                      ? l10n.mcpServerFailed
                      : l10n.mcpServerHint,
                ),
                value: settings.mcpEnabled,
                onChanged: (value) =>
                    settings.setMcpEnabled(value, state.prefs),
              ),
              if (settings.mcpEnabled)
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: Text(l10n.mcpExport),
                  subtitle: Text(l10n.mcpExportHint),
                  onTap: _exportMcpb,
                ),
            ],
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                l10n.navHistory,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.history_toggle_off),
              title: Text(l10n.searchHistory),
              subtitle: Text(l10n.searchHistoryHint),
              value: settings.searchHistoryEnabled,
              onChanged: (value) =>
                  settings.setSearchHistoryEnabled(value, state.prefs),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.clearHistory),
              enabled:
                  state.history.entries.isNotEmpty ||
                  state.searchHistory.entries.isNotEmpty,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.clearHistory),
                    content: Text(l10n.clearHistoryConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.clear),
                      ),
                    ],
                  ),
                );
                if (confirmed ?? false) {
                  state.history.clear(state.prefs);
                  state.searchHistory.clear(state.prefs);
                }
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                l10n.about,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 16),
            Image.asset('assets/icon/icon_256.png', width: 64, height: 64),
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Center(child: Text('${l10n.version} $_version')),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.system_update_alt),
              title: Text(l10n.checkForUpdates),
              subtitle: _checking
                  ? Text(l10n.checkingUpdates)
                  : _failed
                  ? Text(l10n.checkFailed)
                  : result == null
                  ? null
                  : result.updateAvailable
                  ? Text('${l10n.updateAvailable}: ${result.latestVersion}')
                  : Text(l10n.upToDate),
              trailing: _checking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _checking ? null : _check,
            ),
            if (result != null && result.updateAvailable)
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(l10n.viewRelease),
                onTap: () => state.launch(Uri.parse(result.releaseUrl)),
              ),
            ListTile(
              leading: const Icon(Icons.new_releases_outlined),
              title: Text(l10n.allReleases),
              onTap: () => state.launch(Uri.parse(VersionChecker.releasesUrl)),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: Text(l10n.sourceCode),
              onTap: () => state.launch(
                Uri.parse('https://gitlab.com/HttpAnimations/newtube'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.licence),
              subtitle: Text(l10n.licenceText),
              onTap: () => state.launch(
                Uri.parse('https://www.gnu.org/licenses/agpl-3.0.html'),
              ),
            ),
          ],
        );
      },
    );
  }
}
