import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../widgets/thumbnail.dart';
import 'download_player_page.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = AppScope.read(context);
    return ListenableBuilder(
      listenable: state.downloadsStore,
      builder: (context, _) {
        final entries = state.downloadsStore.entries;
        if (entries.isEmpty) {
          return Center(child: Text(l10n.noDownloads));
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(
              l10n.downloads,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final entry in entries)
              ListTile(
                leading: VideoThumbnail(
                  url: entry.video.thumbnailUrl,
                  width: 96,
                  height: 54,
                  borderRadius: BorderRadius.circular(6),
                ),
                title: Text(
                  entry.video.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${entry.video.author} · ${formatBytes(entry.bytes)}',
                  maxLines: 1,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.deleteDownload,
                  onPressed: () =>
                      state.downloadsStore.remove(entry.video.id, state.prefs),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DownloadPlayerPage(entry: entry),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
