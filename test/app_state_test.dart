import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/app_update.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/version_checker.dart';
import 'package:newtube/state/settings_store.dart';

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

  test('watch request notifies and clears', () async {
    final state = await testState();
    var notified = 0;
    state.addListener(() => notified++);
    state.requestWatch(testVideos.first);
    expect(state.watchRequest, testVideos.first);
    expect(notified, 1);
    state.clearWatchRequest();
    expect(state.watchRequest, isNull);
  });

  test('creates and starts the MCP server when enabled', () async {
    final fake = FakeMcpServer();
    void Function(VideoInfo)? onPlay;
    final state = await testState(
      settings: SettingsStore(mcpEnabled: true),
      createMcpServer: ({required api, required version, onPlayVideo}) {
        onPlay = onPlayVideo;
        return fake;
      },
    );
    await pumpEventQueue();
    expect(state.mcpServer, fake);
    expect(fake.running, isTrue);
    expect(state.mcpError, isNull);

    onPlay!(testVideos.first);
    expect(state.watchRequest, testVideos.first);
    state.clearWatchRequest();

    await state.settings.setMcpEnabled(false, state.prefs);
    await pumpEventQueue();
    expect(fake.running, isFalse);

    await state.settings.setMcpEnabled(true, state.prefs);
    await pumpEventQueue();
    expect(fake.running, isTrue);
  });

  test('reports an error when the MCP server fails to start', () async {
    final fake = FakeMcpServer()..startError = 'port busy';
    final state = await testState(
      settings: SettingsStore(mcpEnabled: true),
      createMcpServer: ({required api, required version, onPlayVideo}) => fake,
    );
    await pumpEventQueue();
    expect(fake.running, isFalse);
    expect(state.mcpError, 'port busy');

    fake.startError = null;
    await state.settings.setMcpEnabled(false, state.prefs);
    await state.settings.setMcpEnabled(true, state.prefs);
    await pumpEventQueue();
    expect(state.mcpError, isNull);
    expect(fake.running, isTrue);
  });

  test('creates the MCP server even when package info fails', () async {
    var captured = '';
    final state = await testState(
      packageInfo: () async => throw StateError('no plugin'),
      createMcpServer: ({required api, required version, onPlayVideo}) {
        captured = version;
        return FakeMcpServer();
      },
    );
    await pumpEventQueue();
    expect(state.mcpServer, isNotNull);
    expect(captured, 'dev');
  });
}
