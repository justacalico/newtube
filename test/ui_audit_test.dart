import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/app_state.dart';
import 'package:newtube/state/downloads_store.dart';
import 'package:newtube/state/playlists_store.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/state/subscriptions_store.dart';
import 'package:newtube/state/watch_later_store.dart';
import 'package:newtube/ui/pages/channel_page.dart';
import 'package:newtube/ui/pages/downloads_page.dart';
import 'package:newtube/ui/pages/history_page.dart';
import 'package:newtube/ui/pages/home_page.dart';
import 'package:newtube/ui/pages/local_playlist_page.dart';
import 'package:newtube/ui/pages/playlist_page.dart';
import 'package:newtube/ui/pages/playlists_page.dart';
import 'package:newtube/ui/pages/search_page.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:newtube/ui/pages/subscriptions_page.dart';
import 'package:newtube/ui/pages/trending_page.dart';
import 'package:newtube/ui/pages/watch_later_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:newtube/ui/shell/app_shell.dart';

import 'fakes.dart';
import 'golden_util.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  const sizes = {
    'desktop': Size(1440, 900),
    'tablet': Size(800, 1280),
    'phone': Size(390, 844),
    'small': Size(360, 640),
  };

  void audit(
    String name,
    Widget page, {
    Future<AppState> Function()? state,
    FutureOr<void> Function(WidgetTester tester)? interact,
  }) {
    for (final entry in sizes.entries) {
      final desktop = entry.key == 'desktop';
      testWidgets('$name ${entry.key}', (tester) async {
        await golden(
          tester,
          'audit/${name}_${entry.key}',
          page,
          size: entry.value,
          platform: desktop ? TargetPlatform.linux : TargetPlatform.android,
          state: await state?.call(),
          interact: interact,
        );
      });
    }
  }

  Future<AppState> feedState() => testState(
    api: FakeYouTubeApi(feed: testVideos, related: testVideos),
    windowActions: FakeWindowActions(),
  );

  audit('home', const HomePage(), state: feedState);

  audit(
    'app_shell',
    const AppShell(),
    state: () => testState(
      api: FakeYouTubeApi(feed: testVideos, related: testVideos),
      windowActions: FakeWindowActions(),
    ),
  );

  audit(
    'mini_player',
    const AppShell(),
    state: () => testState(
      api: FakeYouTubeApi(feed: testVideos, related: testVideos),
      player: FakePlayerController(),
      windowActions: FakeWindowActions(),
    ),
    interact: (tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.text('First video'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
    },
  );

  audit('search_empty', const SearchPage());

  audit(
    'search_results',
    const SearchPage(),
    state: () => testState(
      api: FakeYouTubeApi(
        searchResults: const SearchResults(
          videos: testVideos,
          channels: [testChannel],
        ),
      ),
    ),
    interact: (tester) async {
      await tester.enterText(find.byType(TextField), 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    },
  );

  audit(
    'search_history',
    const SearchPage(),
    state: () => testState(
      initialPrefs: {'search_history': '["flutter tutorial","lofi beats"]'},
    ),
  );

  audit(
    'watch',
    WatchPage(video: testVideos.first),
    state: () => testState(api: FakeYouTubeApi(related: testVideos)),
  );

  audit(
    'channel',
    const ChannelPage(channelId: 'c1'),
    state: () => testState(api: FakeYouTubeApi(uploads: testVideos)),
  );

  audit(
    'subscriptions',
    const SubscriptionsPage(),
    state: () => testState(
      api: FakeYouTubeApi(uploads: testVideos),
      subscriptions: SubscriptionsStore({'c1': testChannel}),
    ),
  );

  audit('subscriptions_empty', const SubscriptionsPage());

  audit(
    'history',
    const HistoryPage(),
    state: () => testState(
      initialPrefs: {
        'history': '[{"id":"v1","title":"First video","author":"Channel One","channelId":"c1","duration":201}]',
      },
    ),
  );

  audit('settings', const SettingsPage());

  audit(
    'playlists',
    const PlaylistsPage(),
    state: () => testState(
      playlists: PlaylistsStore([
        const PlaylistInfo(
          id: 'p1',
          title: 'Favourites mix',
          author: 'Channel One',
          videos: testVideos,
        ),
      ]),
    ),
  );

  audit('playlists_empty', const PlaylistsPage());

  audit(
    'local_playlist',
    const LocalPlaylistPage(playlistId: 'p1'),
    state: () => testState(
      playlists: PlaylistsStore([
        const PlaylistInfo(
          id: 'p1',
          title: 'Favourites mix',
          author: 'Channel One',
          videos: testVideos,
        ),
      ]),
    ),
  );

  audit(
    'playlist',
    const PlaylistPage(playlistId: 'pl1'),
    state: () => testState(),
  );

  audit(
    'watch_later',
    const WatchLaterPage(),
    state: () => testState(
      watchLater: WatchLaterStore({for (final v in testVideos) v.id: v}),
    ),
  );

  audit(
    'downloads',
    const DownloadsPage(),
    state: () => testState(
      downloadsStore: DownloadsStore([
        DownloadEntry(video: testVideos.first, path: '/x/v1.mp4', bytes: 2048),
      ]),
    ),
  );

  audit('downloads_empty', const DownloadsPage());

  testWidgets('app shell narrow desktop', (tester) async {
    await golden(
      tester,
      'audit/app_shell_narrow',
      const AppShell(),
      size: const Size(600, 800),
      state: await testState(
        api: FakeYouTubeApi(feed: testVideos),
        windowActions: FakeWindowActions(),
      ),
    );
  });

  testWidgets('app shell mobile zh', (tester) async {
    await golden(
      tester,
      'audit/app_shell_zh',
      const AppShell(),
      size: const Size(390, 844),
      platform: TargetPlatform.android,
      state: await testState(
        api: FakeYouTubeApi(feed: testVideos),
        windowActions: FakeWindowActions(),
        settings: SettingsStore(locale: const Locale('zh', 'Hans')),
      ),
    );
  });

  testWidgets('downloads empty zh', (tester) async {
    await golden(
      tester,
      'audit/downloads_empty_zh',
      const DownloadsPage(),
      state: await testState(
        settings: SettingsStore(locale: const Locale('zh', 'Hans')),
      ),
    );
  });

  audit(
    'trending',
    const TrendingPage(),
    state: () => testState(api: FakeYouTubeApi(trendingFeed: testVideos)),
  );
}
