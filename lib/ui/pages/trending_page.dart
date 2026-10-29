import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'feed_page.dart';

class TrendingPage extends StatelessWidget {
  const TrendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FeedPage(
      title: AppLocalizations.of(context).navTrending,
      fetch: (state) => state.api.trending(),
    );
  }
}
