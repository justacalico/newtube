import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = TestHttpOverrides();

  final loader = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
  await loader.load();

  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ?? '/home/calico/flutter';
  final iconFont = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (iconFont.existsSync()) {
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(iconFont.readAsBytesSync().buffer)));
    await iconLoader.load();
  }

  final cjkFont = File(
    '/usr/share/fonts/google-noto-sans-cjk-vf-fonts/NotoSansCJK-VF.ttc',
  );
  if (cjkFont.existsSync()) {
    final cjkLoader = FontLoader('Noto Sans CJK SC')
      ..addFont(Future.value(ByteData.view(cjkFont.readAsBytesSync().buffer)));
    await cjkLoader.load();
  }

  await testMain();
}
