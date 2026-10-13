import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/app_state.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/state/subscriptions_store.dart';
import 'package:newtube/ui/pages/channel_page.dart';
import 'package:newtube/ui/pages/history_page.dart';
import 'package:newtube/ui/pages/home_page.dart';
import 'package:newtube/ui/pages/search_page.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:newtube/ui/pages/subscriptions_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:newtube/ui/shell/app_shell.dart';

import 'fakes.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

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

  testWidgets('home page', (tester) async {
    await golden(tester, 'home_page', const HomePage());
  });

  testWidgets('app shell', (tester) async {
    await golden(
      tester,
      'app_shell',
      const AppShell(),
      state: await testState(windowActions: FakeWindowActions()),
    );
  });

  testWidgets('app shell collapsed', (tester) async {
    await golden(
      tester,
      'app_shell_collapsed',
      const AppShell(),
      state: await testState(
        settings: SettingsStore(sidebarCollapsed: true),
        windowActions: FakeWindowActions(),
      ),
    );
  });

  testWidgets('app shell mobile', (tester) async {
    await golden(
      tester,
      'app_shell_mobile',
      const AppShell(),
      size: const Size(400, 800),
      platform: TargetPlatform.android,
    );
  });

  testWidgets('search page', (tester) async {
    final api = FakeYouTubeApi(
      searchResults: const SearchResults(
        videos: testVideos,
        channels: [testChannel],
      ),
    );
    await golden(
      tester,
      'search_page',
      const SearchPage(),
      state: await testState(api: api),
      interact: (tester) async {
        await tester.enterText(find.byType(TextField), 'test');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('search page empty', (tester) async {
    await golden(tester, 'search_empty', const SearchPage());
  });

  testWidgets('search page history', (tester) async {
    await golden(
      tester,
      'search_history',
      const SearchPage(),
      state: await testState(
        initialPrefs: {'search_history': '["flutter tutorial","lofi beats"]'},
      ),
    );
  });

  testWidgets('watch page', (tester) async {
    final api = FakeYouTubeApi(related: testVideos);
    await golden(
      tester,
      'watch_page',
      WatchPage(video: testVideos.first),
      state: await testState(api: api),
    );
  });

  testWidgets('watch page in shell', (tester) async {
    await golden(
      tester,
      'watch_in_shell',
      const AppShell(),
      state: await testState(
        api: FakeYouTubeApi(feed: testVideos, related: testVideos),
        windowActions: FakeWindowActions(),
      ),
      interact: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(find.text('First video'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('channel page', (tester) async {
    final api = FakeYouTubeApi(uploads: testVideos);
    await golden(
      tester,
      'channel_page',
      const ChannelPage(channelId: 'c1'),
      state: await testState(api: api),
    );
  });

  testWidgets('subscriptions page', (tester) async {
    final api = FakeYouTubeApi(uploads: testVideos);
    await golden(
      tester,
      'subscriptions_page',
      const SubscriptionsPage(),
      state: await testState(
        api: api,
        subscriptions: SubscriptionsStore({'c1': testChannel}),
      ),
    );
  });

  testWidgets('subscriptions empty', (tester) async {
    await golden(tester, 'subscriptions_empty', const SubscriptionsPage());
  });

  testWidgets('history page', (tester) async {
    await golden(
      tester,
      'history_page',
      const HistoryPage(),
      state: await testState(
        initialPrefs: {
          'history': '[{"id":"v1","title":"First video","author":"Channel One","channelId":"c1","duration":201}]',
        },
      ),
    );
  });

  testWidgets('settings page', (tester) async {
    await golden(tester, 'settings_page', const SettingsPage());
  });

  testWidgets('settings page dark oled', (tester) async {
    await golden(
      tester,
      'settings_oled',
      const SettingsPage(),
      state: await testState(settings: SettingsStore(theme: AppTheme.oled)),
      platform: TargetPlatform.android,
      size: const Size(400, 800),
    );
  });

  testWidgets('settings page chinese', (tester) async {
    await golden(
      tester,
      'settings_page_zh',
      const SettingsPage(),
      state: await testState(
        settings: SettingsStore(locale: const Locale('zh', 'Hans')),
      ),
    );
  });
}
