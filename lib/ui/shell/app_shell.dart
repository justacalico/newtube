import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../pages/history_page.dart';
import '../pages/home_page.dart';
import '../pages/search_page.dart';
import '../pages/settings_page.dart';
import '../pages/subscriptions_page.dart';
import 'title_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 800;

    final destinations = [
      (Icons.home_outlined, Icons.home, l10n.navHome),
      (
        Icons.subscriptions_outlined,
        Icons.subscriptions,
        l10n.navSubscriptions,
      ),
      (Icons.history_outlined, Icons.history, l10n.navHistory),
      (Icons.settings_outlined, Icons.settings, l10n.navSettings),
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
          AppTitleBar(title: l10n.appTitle, windowActions: state.windowActions),
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
            NavigationRail(
              selectedIndex: state.tabIndex,
              onDestinationSelected: state.selectTab,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.$1),
                    selectedIcon: Icon(d.$2),
                    label: Text(d.$3),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
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
              icon: Icon(d.$1),
              selectedIcon: Icon(d.$2),
              label: d.$3,
            ),
        ],
      ),
    );
  }
}
