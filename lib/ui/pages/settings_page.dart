import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../state/settings_store.dart';
import 'about_page.dart';

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

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: state.settings,
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
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.about),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AboutPage()),
              ),
            ),
          ],
        );
      },
    );
  }
}
