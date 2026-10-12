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
              trailing: DropdownButton<AppTheme>(
                value: settings.theme,
                underline: const SizedBox(),
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
              trailing: DropdownButton<String>(
                value: settings.locale == null
                    ? 'system'
                    : _localeKey(settings.locale!),
                underline: const SizedBox(),
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
