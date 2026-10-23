import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/state/app_state.dart';

import 'fakes.dart';

Future<void> golden(
  WidgetTester tester,
  String name,
  Widget page, {
  Size size = const Size(1280, 800),
  AppState? state,
  TargetPlatform platform = TargetPlatform.linux,
  FutureOr<void> Function(WidgetTester tester)? interact,
}) async {
  debugDefaultTargetPlatformOverride = platform;
  final s = state ?? await testState();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await pumpPage(tester, s, page, size: size);
  await interact?.call(tester);
  await tester.runAsync(() async {
    for (final element in tester.elementList(find.byType(Image))) {
      final provider = (element.widget as Image).image;
      if (provider is AssetImage) await precacheImage(provider, element);
    }
  });
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
  debugDefaultTargetPlatformOverride = null;
}
