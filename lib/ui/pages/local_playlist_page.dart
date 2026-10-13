import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: state.playlists,
      builder: (context, _) {
        final playlist = state.playlists.byId(playlistId);
        return Scaffold(
          appBar: AppBar(title: Text(playlist?.title ?? '')),
          body: playlist == null || playlist.videos.isEmpty
              ? Center(child: Text(l10n.playlistEmpty))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                    SliverList.builder(
                      itemCount: playlist.videos.length,
                      itemBuilder: (context, index) {
                        final video = playlist.videos[index];
                        return VideoListTile(
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
                        );
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }
}
