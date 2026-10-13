import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../widgets/video_list_tile.dart';
import 'watch_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: state.history,
      builder: (context, _) {
        final entries = state.history.entries;
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.noHistory,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(l10n.noHistoryHint),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final video = entries[i];
            return VideoListTile(
              video: video,
              onTap: () => openWatchPage(context, video),
            );
          },
        );
      },
    );
  }
}
