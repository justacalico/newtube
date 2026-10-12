import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_update.dart';
import '../../services/version_checker.dart';
import '../../state/app_state.dart';
import '../../state/settings_store.dart';

const languageNames = {
  'en_GB': 'Traditional English',
  'zh_Hans': '简体中文',
  'ru': 'Русский',
  'ga': 'Gaeilge',
};

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
        state.settings,
        state.history,
        state.searchHistory,
      ]),
      builder: (context, _) {
        final settings = state.settings;
        return ListView(
          children: [
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
