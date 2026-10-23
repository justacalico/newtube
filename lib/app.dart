import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'state/app_state.dart';
import 'state/settings_store.dart';
import 'ui/shell/app_shell.dart';
import 'ui/theme.dart';

class NewtubeApp extends StatelessWidget {
  const NewtubeApp({super.key});

  ThemeMode _themeMode(AppTheme theme) => switch (theme) {
    AppTheme.system => ThemeMode.system,
    AppTheme.light => ThemeMode.light,
    AppTheme.dark || AppTheme.oled => ThemeMode.dark,
  };

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListenableBuilder(
      listenable: state.settings,
      builder: (context, _) {
        final oled = state.settings.theme == AppTheme.oled;
        return MaterialApp(
          title: 'NewTube',
          theme: newtubeTheme(
            Brightness.light,
            seedColor: state.settings.accentColor,
          ),
          darkTheme: newtubeTheme(
            Brightness.dark,
            oled: oled,
            seedColor: state.settings.accentColor,
          ),
          themeMode: _themeMode(state.settings.theme),
          locale: state.settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AppShell(),
        );
      },
    );
  }
}
