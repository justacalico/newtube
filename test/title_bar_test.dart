import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/ui/shell/title_bar.dart';

import 'fakes.dart';

Widget _wrap(Widget child) => MaterialApp(
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('isDesktopPlatform flags desktop and not web/mobile', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    expect(isDesktopPlatform, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(isDesktopPlatform, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(isDesktopPlatform, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(isDesktopPlatform, isFalse);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(isDesktopPlatform, isFalse);
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    expect(isDesktopPlatform, isFalse);
  });

  testWidgets('traffic lights call window actions', (tester) async {
    final actions = FakeWindowActions();
    await tester.pumpWidget(
      _wrap(AppTitleBar(title: 'T', windowActions: actions)),
    );

    await tester.tap(find.byKey(const Key('titlebar.close')));
    await tester.tap(find.byKey(const Key('titlebar.minimize')));
    await tester.tap(find.byKey(const Key('titlebar.maximize')));
    expect(actions.closed, 1);
    expect(actions.minimized, 1);
    expect(actions.maximized, 1);
  });

  testWidgets('glyphs appear on hover', (tester) async {
    await tester.pumpWidget(_wrap(const AppTitleBar(title: 'T')));
    expect(find.byIcon(Icons.close), findsNothing);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(
      tester.getCenter(
        find
            .descendant(
              of: find.byType(AppTitleBar),
              matching: find.byType(MouseRegion),
            )
            .first,
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.close), findsOneWidget);
    await gesture.moveTo(const Offset(0, 500));
    await tester.pump();
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('double tap toggles maximize and drag starts drag', (
    tester,
  ) async {
    final actions = FakeWindowActions();
    await tester.pumpWidget(
      _wrap(AppTitleBar(title: 'T', windowActions: actions)),
    );

    await tester.tap(find.text('T'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.text('T'), warnIfMissed: false);
    await tester.pump();
    expect(actions.maximized, 1);

    await tester.drag(find.text('T'), const Offset(200, 0));
    await tester.pump();
    expect(actions.dragged, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 500));
  });
}
