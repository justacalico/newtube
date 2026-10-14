import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../widgets/video_list_tile.dart';
import 'watch_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: state.history,
      builder: (context, _) {
        var entries = state.history.entries;
        if (_filter.isNotEmpty) {
          final q = _filter.toLowerCase();
          entries = [
            for (final v in entries)
              if (v.title.toLowerCase().contains(q) ||
                  v.author.toLowerCase().contains(q))
                v,
          ];
        }
        if (state.history.entries.isEmpty) {
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

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n.filterHistory,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _filter = value),
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? Center(child: Text(l10n.noResults))
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final video = entries[i];
                        return Dismissible(
                          key: ValueKey('history-${video.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Theme.of(context).colorScheme.error,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) =>
                              state.history.remove(video.id, state.prefs),
                          child: _HistoryTile(
                            video: video,
                            state: state,
                            onTap: () => openWatchPage(context, video),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final VideoInfo video;
  final AppState state;
  final VoidCallback onTap;

  const _HistoryTile({
    required this.video,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pos = state.history.positionFor(video.id);
    final total = video.duration;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VideoListTile(
          video: video,
          onTap: onTap,
          trailing: IconButton(
            tooltip: l10n.removeFromHistory,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => state.history.remove(video.id, state.prefs),
          ),
        ),
        if (pos != null &&
            pos > Duration.zero &&
            total != null &&
            total > Duration.zero)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (pos.inMilliseconds / total.inMilliseconds).clamp(
                      0.0,
                      1.0,
                    ),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${formatDuration(pos)} / ${formatDuration(total)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
