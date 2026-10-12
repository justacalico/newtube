import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/app_update.dart';
import 'package:newtube/services/version_checker.dart';
import 'package:newtube/ui/pages/about_page.dart';

import 'fakes.dart';

void main() {
  testWidgets('shows version and up-to-date result', (tester) async {
    final state = await testState();
    await pumpPage(tester, state, const AboutPage());
    await tester.pumpAndSettle();

    expect(find.text('Version 1.2.3'), findsOneWidget);
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.text('You are up to date'), findsOneWidget);
  });

  testWidgets('shows update available with release link', (tester) async {
    final launched = <Uri>[];
    final checker = FakeVersionChecker(
      result: const AppUpdate(
        currentVersion: '1.2.3',
        latestVersion: '2.0.0',
        updateAvailable: true,
        releaseUrl:
            'https://gitlab.com/HttpAnimations/newtube/-/releases/v2.0.0',
      ),
    );
    final state = await testState(versionChecker: checker, launched: launched);
    await pumpPage(tester, state, const AboutPage());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.text('New version available: 2.0.0'), findsOneWidget);

    await tester.tap(find.text('View release'));
    expect(launched.single.toString(), endsWith('/releases/v2.0.0'));
  });

  testWidgets('shows failure feedback', (tester) async {
    final state = await testState(
      versionChecker: FakeVersionChecker(fail: true),
    );
    await pumpPage(tester, state, const AboutPage());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.text('Could not check for updates'), findsOneWidget);
  });

  testWidgets('launches releases, source and licence links', (tester) async {
    final launched = <Uri>[];
    final state = await testState(launched: launched);
    await pumpPage(tester, state, const AboutPage());
    await tester.pumpAndSettle();

    await tester.tap(find.text('All releases'));
    await tester.tap(find.text('Source code'));
    await tester.tap(find.text('Licence'));
    await tester.pump();
    expect(launched.map((u) => u.toString()), [
      VersionChecker.releasesUrl,
      'https://gitlab.com/HttpAnimations/newtube',
      'https://www.gnu.org/licenses/agpl-3.0.html',
    ]);
  });
}
