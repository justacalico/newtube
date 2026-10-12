import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube_landing/main.dart';
import 'package:newtube_landing/releases.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('landing page renders hero and sections', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const LandingApp());
    await tester.pumpAndSettle();
    expect(find.text('NewTube'), findsWidgets);
    expect(find.text('Download'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Screenshots'), 200);
    expect(find.text('Screenshots'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Downloads'), 400);
    expect(find.text('Downloads'), findsOneWidget);
  });

  test('ReleasesService parses releases', () async {
    final client = MockClient((_) async => http.Response(
        '[{"tag_name":"v1.0.0","name":"v1.0.0","released_at":"2026-01-01T00:00:00Z",'
        '"assets":{"links":[{"name":"app.apk","url":"https://x/apk"}]}}]',
        200));
    final releases = await ReleasesService(client).fetch();
    expect(releases.single.tag, 'v1.0.0');
    expect(releases.single.assets.single.name, 'app.apk');
  });

  test('ReleasesService throws on non-200', () {
    final client = MockClient((_) async => http.Response('err', 500));
    expect(ReleasesService(client).fetch, throwsException);
  });
}
