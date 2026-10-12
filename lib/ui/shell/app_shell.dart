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

    final destinations = <SideNavDestination>[
      (
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: l10n.navHome,
      ),
      (
        icon: Icons.subscriptions_outlined,
        selectedIcon: Icons.subscriptions,
        label: l10n.navSubscriptions,
      ),
      (
        icon: Icons.history_outlined,
        selectedIcon: Icons.history,
        label: l10n.navHistory,
      ),
      (
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.navSettings,
      ),
    ];

    const pages = [
      HomePage(),
      SubscriptionsPage(),
      HistoryPage(),
      SettingsPage(),
    ];

    final search = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SearchBar(
        hintText: l10n.searchHint,
        leading: const Icon(Icons.search),
        onSubmitted: (query) {
          final q = query.trim();
          if (q.isEmpty) return;
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => SearchPage(query: q)));
        },
      ),
    );

    final body = Column(
      children: [
        if (isDesktopPlatform)
          AppTitleBar(
            title: l10n.appTitle,
            windowActions: state.windowActions,
            showControls: !wide,
          ),
        search,
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
              selectedIndex: state.tabIndex,
              onSelected: state.selectTab,
              destinations: destinations,
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
        selectedIndex: state.tabIndex,
        onDestinationSelected: state.selectTab,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
