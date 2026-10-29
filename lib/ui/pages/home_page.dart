import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/home_feed.dart';
import 'feed_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FeedPage(
      title: AppLocalizations.of(context).navHome,
      fetch: (state) => HomeFeed(
        api: state.api,
        history: state.history,
        subscriptions: state.subscriptions,
        searchHistory: state.searchHistory,
        watchLater: state.watchLater,
      ).fetch(),
    );
  }
}
