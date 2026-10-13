import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import '../widgets/playlist_dialogs.dart';
import '../widgets/thumbnail.dart';
import 'local_playlist_page.dart';

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  Future<void> _create(BuildContext context) async {
    final state = AppScope.read(context);
    final title = await promptPlaylistTitle(context);
    if (title == null || title.isEmpty) return;
    await state.playlists.create(title, state.prefs);
  }

  Future<void> _rename(BuildContext context, PlaylistInfo playlist) async {
    final state = AppScope.read(context);
    final title = await promptPlaylistTitle(
      context,
      initialValue: playlist.title,
    );
    if (title == null || title.isEmpty) return;
    await state.playlists.rename(playlist.id, title, state.prefs);
  }

  Future<void> _delete(BuildContext context, PlaylistInfo playlist) async {
    final state = AppScope.read(context);
    if (await confirmDeletePlaylist(context)) {
      await state.playlists.delete(playlist.id, state.prefs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: state.playlists,
      builder: (context, _) {
        final playlists = state.playlists.playlists;
        final newTile = ListTile(
          leading: const Icon(Icons.playlist_add),
          title: Text(l10n.newPlaylist),
          onTap: () => _create(context),
        );
        if (playlists.isEmpty) {
          return Column(
            children: [
              newTile,
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.playlistsEmpty,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.playlistsEmptyHint),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        return ListView(
          children: [
            newTile,
            for (final playlist in playlists)
              ListTile(
                leading: SizedBox(
                  width: 96,
                  height: 54,
                  child: VideoThumbnail(
                    url: playlist.thumbnailUrl,
                    width: 96,
                    height: 54,
                  ),
                ),
                title: Text(
                  playlist.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    if (playlist.author.isNotEmpty) playlist.author,
                    l10n.videoCount(playlist.videos.length),
                  ].join(' · '),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) => switch (action) {
                    'rename' => _rename(context, playlist),
                    _ => _delete(context, playlist),
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
                    PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LocalPlaylistPage(playlistId: playlist.id),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
