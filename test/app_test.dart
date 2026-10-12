import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/app.dart';
import 'package:newtube/state/app_state.dart';
import 'package:newtube/state/settings_store.dart';

import 'fakes.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<MaterialApp> pumpApp(
    WidgetTester tester,
    AppState state, {
    Size size = const Size(1200, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(state: state, child: const NewtubeApp()));
    await tester.pumpAndSettle();
    return tester.widget(find.byType(MaterialApp));
  }

  testWidgets('builds with system theme by default', (tester) async {
    final app = await pumpApp(tester, await testState());
    expect(app.themeMode, ThemeMode.system);
    expect(app.title, 'NewTube');
    expect(find.text('Home'), findsWidgets);
  });

  testWidgets('respects each theme mode', (tester) async {
    for (final (theme, mode) in [
      (AppTheme.light, ThemeMode.light),
      (AppTheme.dark, ThemeMode.dark),
      (AppTheme.oled, ThemeMode.dark),
    ]) {
      final state = await testState(settings: SettingsStore(theme: theme));
      final app = await pumpApp(tester, state);
      expect(app.themeMode, mode);
      if (theme == AppTheme.oled) {
        expect(app.darkTheme!.scaffoldBackgroundColor, Colors.black);
        expect(app.darkTheme!.colorScheme.surfaceContainerLow, Colors.black);
        expect(app.darkTheme!.colorScheme.surfaceContainer, Colors.black);
        expect(app.darkTheme!.colorScheme.surfaceTint, Colors.transparent);
      }
    }
  });

  testWidgets('applies stored locale', (tester) async {
    final state = await testState(
      settings: SettingsStore(locale: const Locale('zh', 'Hans')),
    );
    final app = await pumpApp(tester, state);
    expect(app.locale, const Locale('zh', 'Hans'));
    expect(find.text('订阅'), findsWidgets);
  });

  testWidgets('renders in russian and irish', (tester) async {
    for (final locale in [const Locale('ru'), const Locale('ga')]) {
      final state = await testState(settings: SettingsStore(locale: locale));
      await pumpApp(tester, state, size: const Size(400, 800));
    }
  });
}
