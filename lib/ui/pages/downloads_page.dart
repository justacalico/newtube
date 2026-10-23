import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../widgets/content_width.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
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
        return ContentWidth(
          child: Column(
            children: [
              PageHeader(title: l10n.downloads),
              Expanded(
                child: entries.isEmpty
                    ? EmptyState(
                        icon: Icons.download_outlined,
                        title: l10n.noDownloads,
                        hint: l10n.noDownloadsHint,
                      )
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          for (final entry in entries)
                            ListTile(
                              leading: VideoThumbnail(
                                url: entry.video.thumbnailUrl,
                                width: 96,
                                height: 54,
                              ),
                              title: Text(
                                entry.video.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${entry.video.author} · ${formatBytes(entry.bytes)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: l10n.deleteDownload,
                                onPressed: () => state.downloadsStore.remove(
                                  entry.video.id,
                                  state.prefs,
                                ),
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      DownloadPlayerPage(entry: entry),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
