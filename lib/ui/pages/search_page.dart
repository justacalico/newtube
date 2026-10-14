import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import '../widgets/thumbnail.dart';
import '../widgets/video_grid.dart';
import 'channel_page.dart';
import 'playlist_page.dart';
import 'watch_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = SearchController();
  String _query = '';
  SearchResults _results = const SearchResults();
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

  Iterable<Widget> _suggestionTiles(
    BuildContext context,
    SearchController controller,
  ) {
    final q = controller.text.trim();
    final history = _searchHistoryMatches(q);
    return [
      for (final entry in history)
        ListTile(
          leading: const Icon(Icons.history, size: 18),
          title: Text(entry),
          onTap: () => _searchFromHistory(entry),
        ),
      for (final suggestion in _suggestions)
        if (!history.contains(suggestion))
          ListTile(
            leading: const Icon(Icons.search, size: 18),
            title: Text(suggestion),
            onTap: () {
              controller.text = suggestion;
              controller.selection = TextSelection.collapsed(
                offset: suggestion.length,
              );
              _search(suggestion);
            },
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
    _load();
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
      final results = await AppScope.read(context).api.search(_query);
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

  void _openVideo(VideoInfo video) => openWatchPage(context, video);

  void _openChannel(String channelId) => openChannelPage(context, channelId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SearchAnchor.bar(
            searchController: _controller,
            barHintText: l10n.searchHint,
            suggestionsBuilder: _suggestionTiles,
            barLeading: const Icon(Icons.search),
            onSubmitted: _search,
          ),
        ),
        Expanded(
          child: _query.isEmpty
              ? _SearchHistory(onSelect: _searchFromHistory)
              : FeedStateView(
                  loading: _loading,
                  error: _error,
                  videos: _results.videos,
                  onRetry: _load,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Text(
                          '${l10n.searchResultsFor}: $_query',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (_results.channels.isNotEmpty)
                        SizedBox(
                          height: 96,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: [
                              for (final channel in _results.channels)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
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
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                channel.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
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
                          height: 96,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: [
                              for (final playlist in _results.playlists)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () =>
                                          openPlaylistPage(context, playlist),
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
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    playlist.title,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                          videos: _results.videos,
                          onVideoTap: _openVideo,
                          onChannelTap: (v) => _openChannel(v.channelId),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  enabled ? l10n.noSearchHistory : l10n.searchHistoryOff,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  enabled
                      ? l10n.noSearchHistoryHint
                      : l10n.searchHistoryOffHint,
                ),
              ],
            ),
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
