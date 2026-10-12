import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../pages/history_page.dart';
import '../pages/home_page.dart';
import '../pages/search_page.dart';
import '../pages/settings_page.dart';
import '../pages/subscriptions_page.dart';
import 'side_nav.dart';
import 'title_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 800;

    const pages = [
      HomePage(),
      SearchPage(),
      SubscriptionsPage(),
      HistoryPage(),
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
              icon: Icons.search_outlined,
              selectedIcon: Icons.search,
              label: l10n.navSearch,
            ),
            page: 1,
          ),
          (
            destination: (
              icon: Icons.subscriptions_outlined,
              selectedIcon: Icons.subscriptions,
              label: l10n.navSubscriptions,
            ),
            page: 2,
          ),
          if (state.settings.searchHistoryEnabled)
            (
              destination: (
                icon: Icons.history_outlined,
                selectedIcon: Icons.history,
                label: l10n.navHistory,
              ),
              page: 3,
            ),
          (
            destination: (
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: l10n.navSettings,
            ),
            page: 4,
          ),
        ];

        final selected = destinations.indexWhere(
          (d) => d.page == state.tabIndex,
        );
        final index = selected < 0 ? destinations.length - 1 : selected;

        void onSelected(int i) => state.selectTab(destinations[i].page);

        final body = Column(
          children: [
            if (isDesktopPlatform)
              AppTitleBar(
                title: l10n.appTitle,
                windowActions: state.windowActions,
                showControls: !wide,
              ),
            Expanded(
              child: IndexedStack(index: state.tabIndex, children: pages),
            ),
          ],
        );

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                SideNav(
                  selectedIndex: index,
                  onSelected: onSelected,
                  destinations: [
                    for (final d in destinations) d.destination,
                  ],
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
          body: SafeArea(child: body),
          bottomNavigationBar: NavigationBar(
            labelBehavior:
                NavigationDestinationLabelBehavior.onlyShowSelected,
            selectedIndex: index,
            onDestinationSelected: onSelected,
            destinations: [
              for (final d in destinations)
                NavigationDestination(
                  icon: Icon(d.destination.icon),
                  selectedIcon: Icon(d.destination.selectedIcon),
                  label: d.destination.label,
                ),
            ],
          ),
        );
      },
    );
  }
}
