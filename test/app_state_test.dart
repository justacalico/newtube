import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/app_update.dart';
import 'package:newtube/services/version_checker.dart';

import 'fakes.dart';

void main() {
  test('selectTab notifies only on change', () async {
    final state = await testState();
    var notified = 0;
    state.addListener(() => notified++);
    state.selectTab(0);
    expect(notified, 0);
    state.selectTab(2);
    expect(state.tabIndex, 2);
    expect(notified, 1);
  });

  test('checkForUpdate caches result and dedupes concurrent calls', () async {
    final checker = FakeVersionChecker(
      result: const AppUpdate(
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        updateAvailable: true,
        releaseUrl: 'https://x',
      ),
    );
    final state = await testState(versionChecker: checker);
    final a = state.checkForUpdate();
    final b = state.checkForUpdate();
    expect(identical(a, b), isTrue);
    final update = await a;
    expect(update!.updateAvailable, isTrue);
    expect(state.update, update);
  });

  test('checkForUpdate returns null on failure', () async {
    final state = await testState(
      versionChecker: FakeVersionChecker(fail: true),
    );
    expect(await state.checkForUpdate(), isNull);
    expect(state.update, isNull);
  });

  test('second identical check does not notify', () async {
    final checker = FakeVersionChecker();
    final state = await testState(versionChecker: checker);
    await state.checkForUpdate();
    var notified = 0;
    state.addListener(() => notified++);
    await state.checkForUpdate();
    expect(notified, 0);
  });

  test('changed result notifies listeners', () async {
    final checker = FakeVersionChecker();
    final state = await testState(versionChecker: checker);
    var notified = 0;
    state.addListener(() => notified++);
    checker.result = const AppUpdate(
      currentVersion: '1.2.3',
      latestVersion: '9.9.9',
      updateAvailable: true,
      releaseUrl: VersionChecker.releasesUrl,
    );
    await state.checkForUpdate();
    expect(notified, 1);
  });
}
