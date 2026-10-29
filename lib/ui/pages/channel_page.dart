import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import '../../utils/feed_filter.dart';
import '../../utils/format.dart';
import '../layout.dart';
import '../widgets/content_width.dart';
import '../widgets/subscribe_button.dart';
import '../widgets/thumbnail.dart';
import '../widgets/video_grid.dart';
import 'playlist_page.dart';
import 'watch_page.dart';

void openChannelPage(BuildContext context, String channelId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => ChannelPage(channelId: channelId)),
  );
}

class ChannelPage extends StatefulWidget {
  final String channelId;

  const ChannelPage({super.key, required this.channelId});

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  ChannelInfo? _channel;
  List<VideoInfo> _videos = const [];
  List<VideoInfo> _shorts = const [];
  List<PlaylistInfo> _playlists = const [];
  ChannelAbout? _about;
  List<VideoInfo>? _searchResults;
  bool _searching = false;
  bool _loading = true;
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
      final api = AppScope.read(context).api;
      final channel = await api.channel(widget.channelId);
      final results = await Future.wait([
        api.channelVideos(widget.channelId),
        api
            .channelShorts(widget.channelId)
            .catchError((_) => const <VideoInfo>[]),
        api
            .channelPlaylists(widget.channelId)
            .catchError((_) => const <PlaylistInfo>[]),
        api
            .channelAbout(widget.channelId)
            .then<ChannelAbout?>((a) => a)
            .catchError((_) => null),
      ]);
      final videos = [
        for (final v in results[0] as List<VideoInfo>)
          if (v.author.isEmpty) v.copyWith(author: channel.name) else v,
      ];
      final shorts = results[1] as List<VideoInfo>;
      final playlists = results[2] as List<PlaylistInfo>;
      final about = results[3] as ChannelAbout?;
      if (!mounted) return;
      setState(() {
        _channel = channel;
        _videos = videos;
        _shorts = shorts;
        _playlists = playlists;
        _about = about;
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

  void _openVideo(VideoInfo video) => openWatchPage(context, video);

  Widget _filteredGrid(List<VideoInfo> videos) {
    final state = AppScope.read(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        state.hidden,
        state.history,
        state.settings,
      ]),
      builder: (context, _) => VideoGrid(
        videos: visibleVideos(videos, state.settings, state),
        onVideoTap: _openVideo,
      ),
    );
  }

  Future<void> _runSearch(String query) async {
    final api = AppScope.read(context).api;
    final results = await api.channelSearch(widget.channelId, query);
    if (!mounted) return;
    setState(() => _searchResults = results);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final channel = _channel;
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(hintText: l10n.searchThisChannel),
                onSubmitted: _runSearch,
              )
            : null,
        actions: [
          IconButton(
            tooltip: _searching ? l10n.close : l10n.searchThisChannel,
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _searchResults = null;
            }),
          ),
        ],
      ),
      body: ContentWidth(
        maxWidth: feedMaxWidth,
        child: Column(
          children: [
            if (channel != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    VideoThumbnail(
                      url: channel.thumbnailUrl,
                      width: 48,
                      height: 48,
                      borderRadius: BorderRadius.circular(24),
                      placeholderIcon: Icons.person_outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            channel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (channel.subscribers != null)
                            Text(
                              '${formatViewCount(channel.subscribers!, l10n.localeName)} ${l10n.subscribers}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    SubscribeButton(channel: channel),
                  ],
                ),
              ),
            Expanded(
              child: FeedStateView(
                loading: _loading,
                error: _error,
                videos: _videos.isEmpty && _shorts.isEmpty && _playlists.isEmpty
                    ? const []
                    : _videos,
                onRetry: _load,
                child: _searchResults != null
                    ? VideoGrid(videos: _searchResults!, onVideoTap: _openVideo)
                    : DefaultTabController(
                        length: 4,
                        child: Column(
                          children: [
                            TabBar(
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              tabs: [
                                Tab(text: l10n.channelTabVideos),
                                Tab(text: l10n.channelTabShorts),
                                Tab(text: l10n.channelTabPlaylists),
                                Tab(text: l10n.channelTabAbout),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _filteredGrid(_videos),
                                  _filteredGrid(_shorts),
                                  _PlaylistTab(playlists: _playlists),
                                  _AboutTab(about: _about),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistTab extends StatelessWidget {
  final List<PlaylistInfo> playlists;

  const _PlaylistTab({required this.playlists});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (playlists.isEmpty) return Center(child: Text(l10n.noPlaylists));
    return ListView(
      children: [
        for (final playlist in playlists)
          ListTile(
            leading: const Icon(Icons.playlist_play),
            title: Text(
              playlist.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: playlist.videoCount > 0
                ? Text(l10n.videoCount(playlist.videoCount))
                : null,
            onTap: () => openPlaylistPage(context, playlist),
          ),
      ],
    );
  }
}

class _AboutTab extends StatelessWidget {
  final ChannelAbout? about;

  const _AboutTab({required this.about});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final a = about;
    if (a == null ||
        (a.description.isEmpty &&
            a.joinedText.isEmpty &&
            a.subscriberCountText == null &&
            a.videoCountText == null &&
            a.viewCountText == null)) {
      return Center(child: Text(l10n.noAboutInfo));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (a.description.isNotEmpty) SelectableText(a.description),
        const SizedBox(height: 12),
        if (a.subscriberCountText != null) Text(a.subscriberCountText!),
        if (a.videoCountText != null) Text(a.videoCountText!),
        if (a.viewCountText != null) Text(a.viewCountText!),
        if (a.joinedText.isNotEmpty) Text(a.joinedText),
      ],
    );
  }
}
