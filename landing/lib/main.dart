import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'page.dart';

void main() {
  runApp(const LandingApp());
}

enum LandingTheme { system, light, dark, oled }

const landingLocales = [
  Locale('en', 'GB'),
  Locale('zh', 'Hans'),
  Locale('ru'),
  Locale('ga'),
];

class LandingApp extends StatefulWidget {
  const LandingApp({super.key});

  @override
  State<LandingApp> createState() => _LandingAppState();
}

class _LandingAppState extends State<LandingApp> {
  LandingTheme _theme = LandingTheme.system;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _theme = LandingTheme.values
                .asNameMap()[prefs.getString('theme')] ??
            LandingTheme.system;
        final loc = prefs.getString('locale');
        if (loc != null) {
          for (final l in landingLocales) {
            if ('${l.languageCode}_${l.countryCode ?? ''}' == loc) {
              _locale = l;
            }
          }
        }
      });
    });
  }

  Future<void> _setTheme(LandingTheme theme) async {
    setState(() => _theme = theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme.name);
  }

  Future<void> _setLocale(Locale? locale) async {
    setState(() => _locale = locale);
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove('locale');
    } else {
      await prefs.setString(
          'locale', '${locale.languageCode}_${locale.countryCode ?? ''}');
    }
  }

  ThemeData _buildTheme(Brightness brightness, {bool oled = false}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFD32F2F),
      brightness: brightness,
    );
    final theme = ThemeData(colorScheme: scheme, useMaterial3: true);
    if (!oled) return theme;
    return theme.copyWith(
      scaffoldBackgroundColor: Colors.black,
      cardTheme: theme.cardTheme.copyWith(color: const Color(0xFF141414)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NewTube',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme:
          _buildTheme(Brightness.dark, oled: _theme == LandingTheme.oled),
      themeMode: switch (_theme) {
        LandingTheme.system => ThemeMode.system,
        LandingTheme.light => ThemeMode.light,
        LandingTheme.dark || LandingTheme.oled => ThemeMode.dark,
      },
      locale: _locale,
      supportedLocales: LandingLocalizations.supportedLocales,
      localizationsDelegates: const [
        LandingLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: LandingPage(
        theme: _theme,
        onThemeChanged: _setTheme,
        onLocaleChanged: _setLocale,
      ),
    );
  }
}
