import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import '../widgets/video_grid.dart';
import '../widgets/video_list_tile.dart';
import 'watch_page.dart';

void openPlaylistPage(BuildContext context, PlaylistInfo playlist) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PlaylistPage(playlistId: playlist.id, summary: playlist),
    ),
  );
}

class PlaylistPage extends StatefulWidget {
  final String playlistId;
  final PlaylistInfo? summary;

  const PlaylistPage({super.key, required this.playlistId, this.summary});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  PlaylistInfo? _playlist;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final playlist = await AppScope.read(context).api
          .playlist(widget.playlistId);
      if (!mounted) return;
      setState(() {
        _playlist = playlist;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final playlist = _playlist;
    final token = playlist?.continuation;
    if (playlist == null || token == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final more = await AppScope.read(context).api
          .playlist(widget.playlistId, continuation: token);
      if (!mounted) return;
      setState(() {
        _playlist = playlist.withContinuation(more.videos, more.continuation);
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _openVideo(VideoInfo video) {
    final playlist = _playlist;
    final index = playlist?.videos.indexOf(video) ?? -1;
    openWatchPage(
      context,
      video,
      playlist: playlist,
      index: index < 0 ? null : index,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = AppScope.read(context);
    final playlist = _playlist ?? widget.summary;
    final loaded = _playlist;
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist?.title ?? ''),
        actions: [
          if (loaded != null)
            ListenableBuilder(
              listenable: state.playlists,
              builder: (context, _) {
                final saved = state.playlists.byId(loaded.id) != null;
                return IconButton(
                  tooltip: saved ? l10n.playlistSaved : l10n.savePlaylist,
                  icon: Icon(
                    saved ? Icons.playlist_add_check : Icons.playlist_add,
                  ),
                  onPressed: () =>
                      state.playlists.toggleSaved(loaded, state.prefs),
                );
              },
            ),
        ],
      ),
      body: FeedStateView(
        loading: _loading && playlist == null,
        error: _error,
        videos: playlist?.videos ?? const [],
        onRetry: _load,
        child: CustomScrollView(
          slivers: [
            if (playlist != null)
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
                        [
                          if (playlist.author.isNotEmpty) playlist.author,
                          l10n.videoCount(playlist.videoCount),
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            SliverList.builder(
              itemCount: playlist == null
                  ? 0
                  : playlist.videos.length +
                        (playlist.continuation != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= playlist!.videos.length) {
                  if (!_loadingMore) {
                    scheduleMicrotask(_loadMore);
                  }
                  return _loadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox.shrink();
                }
                final video = playlist.videos[index];
                return VideoListTile(
                  video: video,
                  onTap: () => _openVideo(video),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
