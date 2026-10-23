import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import '../widgets/content_width.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
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

  Widget _createButton(BuildContext context, AppLocalizations l10n) =>
      FilledButton.tonalIcon(
        icon: const Icon(Icons.playlist_add),
        label: Text(l10n.newPlaylist),
        onPressed: () => _create(context),
      );

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: state.playlists,
      builder: (context, _) {
        final playlists = state.playlists.playlists;
        return ContentWidth(
          child: Column(
            children: [
              PageHeader(
                title: l10n.navPlaylists,
                actions: [
                  if (playlists.isNotEmpty) _createButton(context, l10n),
                ],
              ),
              Expanded(
                child: playlists.isEmpty
                    ? EmptyState(
                        icon: Icons.video_library_outlined,
                        title: l10n.playlistsEmpty,
                        hint: l10n.playlistsEmptyHint,
                        action: _createButton(context, l10n),
                      )
                    : ListView(
                        children: [
                          for (final playlist in playlists)
                            ListTile(
                              leading: SizedBox(
                                width: 96,
                                height: 54,
                                child: VideoThumbnail(
                                  url: playlist.thumbnailUrl,
                                  width: 96,
                                  height: 54,
                                  placeholderIcon: Icons.playlist_play,
                                ),
                              ),
                              title: Text(
                                playlist.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                [
                                  if (playlist.author.isNotEmpty)
                                    playlist.author,
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
                                  PopupMenuItem(
                                    value: 'rename',
                                    child: Text(l10n.rename),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(l10n.delete),
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => LocalPlaylistPage(
                                    playlistId: playlist.id,
                                  ),
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
