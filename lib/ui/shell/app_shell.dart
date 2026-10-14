import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../models/video_info.dart';
import '../../models/youtube_route.dart';
import '../pages/channel_page.dart';
import '../pages/downloads_page.dart';
import '../pages/history_page.dart';
import '../pages/home_page.dart';
import '../pages/playlist_page.dart';
import '../pages/playlists_page.dart';
import '../pages/search_page.dart';
import '../pages/settings_page.dart';
import '../pages/subscriptions_page.dart';
import '../pages/trending_page.dart';
import '../pages/watch_later_page.dart';
import '../pages/watch_page.dart';
import '../widgets/mini_player.dart';
import 'side_nav.dart';
import 'title_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _contentNavigator = GlobalKey<NavigatorState>();
  late final AppState _state;
  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    _state = AppScope.read(context)..addListener(_openRequestedVideo);
    _links = _state.links?.links.listen(_openUri);
    unawaited(
      _state.links?.initial.then((uri) {
        if (uri != null) _openUri(uri);
      }),
    );
  }

  @override
  void dispose() {
    unawaited(_links?.cancel());
    _state.removeListener(_openRequestedVideo);
    super.dispose();
  }

  void _openUri(Uri uri) {
    if (!looksLikeYouTubeLink(uri.toString())) return;
    _openLink(uri.toString());
  }

  Future<void> _openLink(String url) async {
    var route = parseYouTubeLink(url);
    route ??= await _state.api.resolveUrl(url);
    if (!mounted || route == null) return;
    final videoId = route.videoId;
    final playlistId = route.playlistId;
    final channelId = route.channelId;
    if (videoId != null) {
      _contentNavigator.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => WatchPage(
            video: VideoInfo(
              id: videoId,
              title: '',
              author: '',
              channelId: '',
              thumbnailUrl: null,
            ),
            startSeconds: route?.startSeconds ?? 0,
          ),
        ),
      );
    } else if (playlistId != null) {
      _contentNavigator.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => PlaylistPage(playlistId: playlistId),
        ),
      );
    } else if (channelId != null) {
      _contentNavigator.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => ChannelPage(channelId: channelId),
        ),
      );
    }
  }

  void _openRequestedVideo() {
    final video = _state.watchRequest;
    if (video == null) return;
    _state.clearWatchRequest();
    _contentNavigator.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => WatchPage(video: video)),
    );
  }

  void _expandMiniPlayer() {
    final session = _state.playback;
    final video = session.video;
    if (video == null) return;
    _contentNavigator.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => WatchPage(
          video: video,
          playlist: session.playlist,
          index: session.index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 800;

    const pages = [
      HomePage(),
      TrendingPage(),
      SearchPage(),
      SubscriptionsPage(),
      HistoryPage(),
      WatchLaterPage(),
      PlaylistsPage(),
      DownloadsPage(),
      SettingsPage(),
    ];

    return ListenableBuilder(
      listenable: state.settings,
      builder: (context, _) {
        final destinations = <({SideNavDestination destination, int page})>[
          (
            destination: (
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: l10n.navHome,
            ),
            page: 0,
          ),
          (
            destination: (
              icon: Icons.trending_up,
              selectedIcon: Icons.trending_up,
              label: l10n.navTrending,
            ),
            page: 1,
          ),
          (
            destination: (
              icon: Icons.search_outlined,
              selectedIcon: Icons.search,
              label: l10n.navSearch,
            ),
            page: 2,
          ),
          (
            destination: (
              icon: Icons.subscriptions_outlined,
              selectedIcon: Icons.subscriptions,
              label: l10n.navSubscriptions,
            ),
            page: 3,
          ),
          if (state.settings.searchHistoryEnabled)
            (
              destination: (
                icon: Icons.history_outlined,
                selectedIcon: Icons.history,
                label: l10n.navHistory,
              ),
              page: 4,
            ),
          (
            destination: (
              icon: Icons.watch_later_outlined,
              selectedIcon: Icons.watch_later,
              label: l10n.navWatchLater,
            ),
            page: 5,
          ),
          (
            destination: (
              icon: Icons.video_library_outlined,
              selectedIcon: Icons.video_library,
              label: l10n.navPlaylists,
            ),
            page: 6,
          ),
          (
            destination: (
              icon: Icons.download_outlined,
              selectedIcon: Icons.download,
              label: l10n.downloadsNav,
            ),
            page: 7,
          ),
          (
            destination: (
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: l10n.navSettings,
            ),
            page: 8,
          ),
        ];

        final mobileBar = destinations.length > 5
            ? destinations.sublist(0, 4)
            : destinations;

        final selected = destinations.indexWhere(
          (d) => d.page == state.tabIndex,
        );
        final index = selected < 0 ? destinations.length - 1 : selected;

        void onSelected(int i) {
          _contentNavigator.currentState?.popUntil((route) => route.isFirst);
          state.selectTab(destinations[i].page);
        }

        final body = Column(
          children: [
            if (isDesktopPlatform)
              AppTitleBar(
                title: l10n.appTitle,
                windowActions: state.windowActions,
                showControls: !wide,
              ),
            Expanded(
              child: Navigator(
                key: _contentNavigator,
                observers: [watchRouteObserver],
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (context) => Material(
                    type: MaterialType.transparency,
                    child: IndexedStack(
                      index: AppScope.of(context).tabIndex,
                      children: pages,
                    ),
                  ),
                ),
              ),
            ),
            MiniPlayer(session: state.playback, onExpand: _expandMiniPlayer),
          ],
        );

        if (wide) {
          final collapsed = state.settings.sidebarCollapsed;
          return Scaffold(
            body: Row(
              children: [
                SideNav(
                  selectedIndex: index,
                  onSelected: onSelected,
                  destinations: [for (final d in destinations) d.destination],
                  footerCount: 1,
                  collapsed: collapsed,
                  onToggleCollapsed: () => state.settings.setSidebarCollapsed(
                    !collapsed,
                    state.prefs,
                  ),
                  toggleLabel: collapsed
                      ? l10n.expandSidebar
                      : l10n.collapseSidebar,
                  header: isDesktopPlatform
                      ? SizedBox(
                          height: 28,
                          child: Row(
                            children: [
                              TrafficLights(actions: state.windowActions),
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onPanStart: (_) =>
                                      state.windowActions?.startDrag(),
                                  onDoubleTap: () =>
                                      state.windowActions?.toggleMaximize(),
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          drawer: mobileBar.length < destinations.length
              ? Drawer(
                  child: SafeArea(
                    child: ListView(
                      children: [
                        for (var i = 0; i < destinations.length; i++)
                          ListTile(
                            leading: Icon(destinations[i].destination.icon),
                            title: Text(destinations[i].destination.label),
                            selected: i == index,
                            onTap: () {
                              Navigator.of(context).pop();
                              onSelected(i);
                            },
                          ),
                      ],
                    ),
                  ),
                )
              : null,
          body: SafeArea(child: body),
          bottomNavigationBar: ValueListenableBuilder<bool>(
            valueListenable: state.pipActions?.pipMode ?? ValueNotifier(false),
            builder: (context, pip, _) => pip
                ? const SizedBox.shrink()
                : Builder(
                    builder: (context) => NavigationBar(
                      labelBehavior:
                          NavigationDestinationLabelBehavior.onlyShowSelected,
                      selectedIndex: index < mobileBar.length
                          ? index
                          : mobileBar.length,
                      onDestinationSelected: (i) => i >= mobileBar.length
                          ? Scaffold.of(context).openDrawer()
                          : onSelected(i),
                      destinations: [
                        for (final d in mobileBar)
                          NavigationDestination(
                            icon: Icon(d.destination.icon),
                            selectedIcon: Icon(d.destination.selectedIcon),
                            label: d.destination.label,
                          ),
                        if (mobileBar.length < destinations.length)
                          NavigationDestination(
                            icon: const Icon(Icons.menu),
                            label: l10n.navMore,
                          ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
