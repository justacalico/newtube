import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/app.dart';
import 'package:newtube/models/app_update.dart';
import 'package:newtube/state/app_state.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/version_checker.dart';
import 'package:newtube/ui/pages/search_page.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';

import 'fakes.dart';

void main() {
  test('AppUpdate equality and hashCode', () {
    const a = AppUpdate(
      currentVersion: '1',
      latestVersion: '2',
      updateAvailable: true,
      releaseUrl: 'u',
    );
    const b = AppUpdate(
      currentVersion: '1',
      latestVersion: '2',
      updateAvailable: true,
      releaseUrl: 'u',
    );
    const c = AppUpdate(currentVersion: '9');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == c, isFalse);
  });

  test('VideoInfo copyWith overrides only given fields', () {
    const video = VideoInfo(
      id: 'a',
      title: 't',
      author: 'x',
      channelId: 'c',
    );
    final same = video.copyWith();
    expect(same.author, 'x');
    expect(same.channelId, 'c');
    final copy = video.copyWith(
      author: 'y',
      channelId: 'c2',
      title: 't2',
      id: 'b',
      thumbnailUrl: 'u',
      duration: const Duration(seconds: 3),
      viewCount: 7,
      uploaded: '1d',
    );
    expect(copy.id, 'b');
    expect(copy.title, 't2');
    expect(copy.author, 'y');
    expect(copy.channelId, 'c2');
    expect(copy.thumbnailUrl, 'u');
    expect(copy.duration, const Duration(seconds: 3));
    expect(copy.viewCount, 7);
    expect(copy.uploaded, '1d');
  });

  test('VersionCheckException formats its message', () {
    expect(
      const VersionCheckException('oops').toString(),
      'VersionCheckException: oops',
    );
  });

  testWidgets('NewtubeApp accepts a key', (tester) async {
    final state = await testState();
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: NewtubeApp(key: UniqueKey()),
      ),
    );
    await tester.pump();
  });

  testWidgets('checking spinner shows while check in flight', (tester) async {
    final gate = Completer<AppUpdate>();
    final checker = _GatedChecker(gate);
    final state = await testState(versionChecker: checker);
    await pumpPage(tester, state, const SettingsPage());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Check for updates'), 200);
    await tester.tap(find.text('Check for updates'));
    await tester.pump();
    expect(find.text('Checking for updates…'), findsOneWidget);
    gate.complete(const AppUpdate(currentVersion: '1.2.3'));
    await tester.pumpAndSettle();
    expect(find.text('You are up to date'), findsOneWidget);
  });

  testWidgets('search page error retries', (tester) async {
    final api = FakeYouTubeApi()..error = 'down';
    final state = await testState(api: api);
    await pumpPage(tester, state, const SearchPage());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'x');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);
    api.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No videos found'), findsOneWidget);
  });

  testWidgets('search video card opens channel page', (tester) async {
    final api = FakeYouTubeApi(
      searchResults: const SearchResults(videos: testVideos),
      uploads: testVideos,
    );
    final state = await testState(api: api);
    await pumpPage(tester, state, const SearchPage());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'x');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Channel One').first);
    await tester.pumpAndSettle();
    expect(find.text('54.3K subscribers'), findsOneWidget);
  });

  testWidgets('disposing during load disposes the player', (tester) async {
    final player = FakePlayerController()..openGate = Completer<void>();
    final state = await testState(api: FakeYouTubeApi(), player: player);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(player.opened, isNotEmpty);
    expect(player.disposed, isFalse);

    await pumpPage(tester, state, const SizedBox());
    player.openGate!.complete();
    await tester.pumpAndSettle();
    expect(player.disposed, isTrue);
  });

  testWidgets('back gesture exits fullscreen', (tester) async {
    final state = await testState(api: FakeYouTubeApi());
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.fullscreen));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('A video description'), findsOneWidget);
  });

  testWidgets('related video replaces watch page', (tester) async {
    const related = VideoInfo(
      id: 'v9',
      title: 'Related pick',
      author: 'Other',
      channelId: 'c9',
      duration: Duration(minutes: 1),
    );
    final api = FakeYouTubeApi(related: const [related]);
    final state = await testState(api: api);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    expect(find.text('1:00'), findsOneWidget);
    await tester.ensureVisible(find.text('Related pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Related pick'));
    await tester.pumpAndSettle();
    expect(find.text('Related pick'), findsWidgets);
  });
}

class _GatedChecker extends FakeVersionChecker {
  final Completer<AppUpdate> gate;
  _GatedChecker(this.gate);

  @override
  Future<AppUpdate> check(String currentVersion) => gate.future;
}
