import 'dart:async';

import '../../models/search_filter.dart';
import '../../models/youtube_route.dart';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../services/youtube_api.dart';
import '../../state/app_state.dart';
import '../layout.dart';
import '../widgets/content_width.dart';
import '../widgets/thumbnail.dart';
import '../../utils/feed_filter.dart';
import '../widgets/empty_state.dart';
import '../widgets/video_grid.dart';
import 'channel_page.dart';
import 'playlist_page.dart' show PlaylistPage, openPlaylistPage;
import 'watch_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';
  SearchResults _results = const SearchResults();
  var _filter = const SearchFilter();
  bool _loading = false;
  Object? _error;
  List<String> _suggestions = const [];
  Timer? _suggestionDebounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _suggestionDebounce?.cancel();
    _suggestionDebounce = Timer(const Duration(milliseconds: 250), _suggest);
    if (mounted) setState(() {});
  }

  Future<void> _suggest() async {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      if (mounted && _suggestions.isNotEmpty) {
        setState(() => _suggestions = const []);
      }
      return;
    }
    final state = AppScope.read(context);
    try {
      final suggestions = await state.api.searchSuggestions(q);
      if (!mounted || _controller.text.trim() != q) return;
      setState(() => _suggestions = suggestions);
    } catch (_) {}
  }

  List<Widget> _suggestionTiles(String q) {
    final history = _searchHistoryMatches(q);
    return [
      for (final entry in history)
        ListTile(
          leading: const Icon(Icons.history, size: 18),
          title: Text(entry),
          onTap: () => _searchFromHistory(entry), // coverage:ignore-line
        ),
      for (final suggestion in _suggestions)
        if (!history.contains(suggestion))
          ListTile(
            leading: const Icon(Icons.search, size: 18),
            title: Text(suggestion),
            onTap: () => _searchFromHistory(suggestion),
          ),
    ];
  }

  List<String> _searchHistoryMatches(String q) {
    if (q.isEmpty) return const [];
    final state = AppScope.read(context);
    if (!state.settings.searchHistoryEnabled) return const [];
    return [
      for (final e in state.searchHistory.entries)
        if (e.toLowerCase().contains(q.toLowerCase()) && e != q) e,
    ];
  }

  void _search(String query) {
    final q = query.trim();
    if (q.isEmpty || q == _query) return;
    final state = AppScope.read(context);
    _query = q;
    if (state.settings.searchHistoryEnabled) {
      state.searchHistory.record(q, state.prefs);
    }
    if (looksLikeYouTubeLink(q)) {
      _openLink(q, state.api);
      return;
    }
    _load();
  }

  Future<void> _openLink(String url, YouTubeApi api) async {
    var route = parseYouTubeLink(url);
    route ??= await api.resolveUrl(url);
    if (!mounted) return;
    if (route == null) {
      _load();
      return;
    }
    final videoId = route.videoId;
    final playlistId = route.playlistId;
    final channelId = route.channelId;
    if (videoId != null) {
      openWatchPage(
        context,
        VideoInfo(
          id: videoId,
          title: '',
          author: '',
          channelId: '',
          thumbnailUrl: null,
        ),
        startSeconds: route.startSeconds,
      );
    } else if (playlistId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlaylistPage(playlistId: playlistId),
        ),
      );
    } else if (channelId != null) {
      openChannelPage(context, channelId);
    }
  }

  void _searchFromHistory(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    _search(query);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await AppScope.read(context).api
          .search(_query, filter: _filter);
      if (!mounted) return;
      setState(() {
        _results = results;
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

  void _setFilter(SearchFilter filter) {
    _filter = filter;
    _load();
  }

  void _openVideo(VideoInfo video) => openWatchPage(context, video);

  void _openChannel(String channelId) => openChannelPage(context, channelId);

  List<VideoInfo> _visibleResults() {
    final state = AppScope.read(context);
    return visibleVideos(_results.videos, state.settings, state);
  }

  Widget _resultsView(Widget Function() builder) {
    final state = AppScope.read(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        state.hidden,
        state.history,
        state.settings,
      ]),
      builder: (context, _) => builder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ContentWidth(
      maxWidth: feedMaxWidth,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: SearchBar(
              controller: _controller,
              hintText: l10n.searchHint,
              leading: const Icon(Icons.search),
              trailing: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    tooltip: l10n.clear,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _controller.clear();
                      _query = '';
                    }),
                  ),
              ],
              elevation: const WidgetStatePropertyAll(0.0),
              side: WidgetStatePropertyAll(
                BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              onSubmitted: _search,
            ),
          ),
          if (_query.isNotEmpty)
            _FilterRow(filter: _filter, onChanged: _setFilter),
          Expanded(
            child: _query.isEmpty
                ? (_controller.text.trim().isNotEmpty
                      ? ListView(
                          children: _suggestionTiles(_controller.text.trim()),
                        )
                      : _SearchHistory(onSelect: _searchFromHistory))
                : _resultsView(
                    () => FeedStateView(
                      loading: _loading,
                      error: _error,
                      videos: _visibleResults(),
                      onRetry: _load,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_results.channels.isNotEmpty)
                            SizedBox(
                              height: 64,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                children: [
                                  for (final channel in _results.channels)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                          onTap: () => _openChannel(channel.id),
                                          child: SizedBox(
                                            width: 180,
                                            child: Row(
                                              children: [
                                                VideoThumbnail(
                                                  url: channel.thumbnailUrl,
                                                  width: 48,
                                                  height: 48,
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  placeholderIcon:
                                                      Icons.person_outline,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    channel.name,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          if (_results.playlists.isNotEmpty)
                            SizedBox(
                              height: 72,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                children: [
                                  for (final playlist in _results.playlists)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                          onTap: () => openPlaylistPage(
                                            context,
                                            playlist,
                                          ),
                                          child: SizedBox(
                                            width: 180,
                                            child: Row(
                                              children: [
                                                VideoThumbnail(
                                                  url: playlist.thumbnailUrl,
                                                  width: 48,
                                                  height: 48,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        playlist.title,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      Text(
                                                        l10n.videoCount(
                                                          playlist.videoCount,
                                                        ),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: VideoGrid(
                              videos: _visibleResults(),
                              onVideoTap: _openVideo,
                              onChannelTap: (v) {
                                if (v.channelId.isNotEmpty) {
                                  _openChannel(v.channelId);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchHistory extends StatelessWidget {
  const _SearchHistory({required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([state.searchHistory, state.settings]),
      builder: (context, _) {
        final enabled = state.settings.searchHistoryEnabled;
        final entries = state.searchHistory.entries;
        if (!enabled || entries.isEmpty) {
          return EmptyState(
            icon: Icons.search,
            title: enabled ? l10n.noSearchHistory : l10n.searchHistoryOff,
            hint: enabled
                ? l10n.noSearchHistoryHint
                : l10n.searchHistoryOffHint,
          );
        }

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final entry = entries[i];
            return ListTile(
              leading: const Icon(Icons.history),
              title: Text(entry),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.removeSearchEntry,
                onPressed: () => state.searchHistory.remove(entry, state.prefs),
              ),
              onTap: () => onSelect(entry),
            );
          },
        );
      },
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.filter, required this.onChanged});

  final SearchFilter filter;
  final ValueChanged<SearchFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ShaderMask(
      shaderCallback: (bounds) {
        final fade = (40 / bounds.width).clamp(0.0, 0.5);
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [Colors.white, Colors.transparent],
          stops: [1 - fade, 1],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Row(
          children: [
            _FilterMenu<SearchSort>(
              label: l10n.filterSort,
              value: switch (filter.sort) {
                SearchSort.relevance => l10n.sortRelevance,
                SearchSort.date => l10n.sortDate,
                SearchSort.views => l10n.sortViews,
                SearchSort.rating => l10n.sortRating,
              },
              active: filter.sort != SearchSort.relevance,
              items: {
                SearchSort.relevance: l10n.sortRelevance,
                SearchSort.date: l10n.sortDate,
                SearchSort.views: l10n.sortViews,
                SearchSort.rating: l10n.sortRating,
              },
              onChanged: (v) => onChanged(filter.copyWith(sort: v)),
              theme: theme,
            ),
            _FilterMenu<SearchType>(
              label: l10n.filterType,
              value: switch (filter.type) {
                SearchType.all => l10n.typeAll,
                SearchType.video => l10n.typeVideo,
                SearchType.channel => l10n.typeChannel,
                SearchType.playlist => l10n.typePlaylist,
                SearchType.live => l10n.typeLive,
              },
              active: filter.type != SearchType.all,
              items: {
                SearchType.all: l10n.typeAll,
                SearchType.video: l10n.typeVideo,
                SearchType.channel: l10n.typeChannel,
                SearchType.playlist: l10n.typePlaylist,
                SearchType.live: l10n.typeLive,
              },
              onChanged: (v) => onChanged(filter.copyWith(type: v)),
              theme: theme,
            ),
            _FilterMenu<UploadDate>(
              label: l10n.filterUploadDate,
              value: switch (filter.uploadDate) {
                UploadDate.any => l10n.uploadAny,
                UploadDate.hour => l10n.uploadHour,
                UploadDate.today => l10n.uploadToday,
                UploadDate.week => l10n.uploadWeek,
                UploadDate.month => l10n.uploadMonth,
                UploadDate.year => l10n.uploadYear,
              },
              active: filter.uploadDate != UploadDate.any,
              items: {
                UploadDate.any: l10n.uploadAny,
                UploadDate.hour: l10n.uploadHour,
                UploadDate.today: l10n.uploadToday,
                UploadDate.week: l10n.uploadWeek,
                UploadDate.month: l10n.uploadMonth,
                UploadDate.year: l10n.uploadYear,
              },
              onChanged: (v) => onChanged(filter.copyWith(uploadDate: v)),
              theme: theme,
            ),
            _FilterMenu<VideoDuration>(
              label: l10n.filterDuration,
              value: switch (filter.duration) {
                VideoDuration.any => l10n.durationAny,
                VideoDuration.short => l10n.durationShort,
                VideoDuration.medium => l10n.durationMedium,
                VideoDuration.long => l10n.durationLong,
              },
              active: filter.duration != VideoDuration.any,
              items: {
                VideoDuration.any: l10n.durationAny,
                VideoDuration.short: l10n.durationShort,
                VideoDuration.medium: l10n.durationMedium,
                VideoDuration.long: l10n.durationLong,
              },
              onChanged: (v) => onChanged(filter.copyWith(duration: v)),
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.active,
    required this.items,
    required this.onChanged,
    required this.theme,
  });

  final String label;
  final String value;
  final bool active;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: MenuAnchor(
        builder: (context, controller, child) => TextButton(
          style: TextButton.styleFrom(
            backgroundColor: active
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(0, 36),
          ),
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$label · $value'),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
        ),
        menuChildren: [
          for (final item in items.entries)
            MenuItemButton(
              onPressed: () => onChanged(item.key),
              child: Text(item.value),
            ),
        ],
      ),
    );
  }
}
