import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'state/app_state.dart';
import 'state/settings_store.dart';
import 'ui/shell/app_shell.dart';

class NewtubeApp extends StatelessWidget {
  const NewtubeApp({super.key});

  ThemeData _theme(
    Brightness brightness, {
    bool oled = false,
    int seedColor = 0xFFD32F2F,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Color(seedColor),
      brightness: brightness,
    );
    final theme = ThemeData(colorScheme: scheme, fontFamily: 'Inter');
    if (!oled) return theme;
    return theme.copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: scheme.copyWith(
        surface: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: Colors.black,
        surfaceContainer: Colors.black,
        surfaceContainerHigh: Colors.black,
        surfaceContainerHighest: Colors.black,
        surfaceTint: Colors.transparent,
      ),
      cardTheme: theme.cardTheme.copyWith(color: const Color(0xFF111111)),
      dialogTheme: theme.dialogTheme.copyWith(backgroundColor: Colors.black),
    );
  }

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
          theme: _theme(
            Brightness.light,
            seedColor: state.settings.accentColor,
          ),
          darkTheme: _theme(
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
