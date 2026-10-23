import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import '../widgets/content_width.dart';
import '../widgets/video_list_tile.dart';
import 'watch_page.dart';

class LocalPlaylistPage extends StatelessWidget {
  final String playlistId;

  const LocalPlaylistPage({super.key, required this.playlistId});

  void _openVideo(BuildContext context, PlaylistInfo playlist, int index) {
    openWatchPage(
      context,
      playlist.videos[index],
      playlist: playlist,
      index: index,
    );
  }

  void _rename(BuildContext context, PlaylistInfo playlist) {
    final state = AppScope.read(context);
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: playlist.title);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renamePlaylist),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.playlistName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                state.playlists.rename(playlist.id, title, state.prefs);
              }
              Navigator.of(context).pop();
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _shufflePlay(BuildContext context, PlaylistInfo playlist) {
    final state = AppScope.read(context);
    state.playback.shuffle = true;
    final start = Random().nextInt(playlist.videos.length);
    _openVideo(context, playlist, start);
  }

  Future<void> _export(BuildContext context, PlaylistInfo playlist) async {
    final state = AppScope.read(context);
    final l10n = AppLocalizations.of(context);
    final urls = playlist.videos
        .map((v) => 'https://www.youtube.com/watch?v=${v.id}')
        .join('\n');
    final messenger = ScaffoldMessenger.of(context);
    final save = state.saveFile;
    if (save != null) {
      final path = await save(
        '${playlist.title}.txt',
        Uint8List.fromList(urls.codeUnits),
        extension: 'txt',
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            path == null ? l10n.exportCancelled : l10n.exportedTo(path),
          ),
        ),
      );
    } else {
      state.share?.share(urls);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: state.playlists,
      builder: (context, _) {
        final playlist = state.playlists.byId(playlistId);
        return Scaffold(
          appBar: AppBar(
            actions: [
              if (playlist != null) ...[
                IconButton(
                  tooltip: l10n.shufflePlay,
                  icon: const Icon(Icons.shuffle),
                  onPressed: () => _shufflePlay(context, playlist),
                ),
                IconButton(
                  tooltip: l10n.renamePlaylist,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _rename(context, playlist),
                ),
                IconButton(
                  tooltip: l10n.exportPlaylist,
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _export(context, playlist),
                ),
              ],
            ],
          ),
          body: playlist == null || playlist.videos.isEmpty
              ? Center(child: Text(l10n.playlistEmpty))
              : ContentWidth(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playlist.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.videoCount(playlist.videos.length),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverReorderableList(
                        itemCount: playlist.videos.length,
                        onReorderItem: (from, to) => state.playlists.moveVideo(
                          playlist.id,
                          from,
                          to,
                          state.prefs,
                        ),
                        itemBuilder: (context, index) {
                          final video = playlist.videos[index];
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey('pl-$index-${video.id}'),
                            index: index,
                            child: VideoListTile(
                              video: video,
                              trailing: IconButton(
                                tooltip: l10n.removeFromPlaylist,
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => state.playlists.removeVideo(
                                  playlist.id,
                                  video.id,
                                  state.prefs,
                                ),
                              ),
                              onTap: () => _openVideo(context, playlist, index),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
