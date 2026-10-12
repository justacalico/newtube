import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import '../widgets/thumbnail.dart';
import '../widgets/video_grid.dart';
import 'channel_page.dart';
import 'watch_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';
  SearchResults _results = const SearchResults();
  bool _loading = false;
  Object? _error;

  void _search(String query) {
    final q = query.trim();
    if (q.isEmpty || q == _query) return;
    _query = q;
    _load();
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

  void _openVideo(VideoInfo video) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => WatchPage(video: video)));
  }

  void _openChannel(String channelId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChannelPage(channelId: channelId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SearchBar(
            hintText: l10n.searchHint,
            leading: const Icon(Icons.search),
            onSubmitted: _search,
          ),
        ),
        Expanded(
          child: _query.isEmpty
              ? Center(
                  child: Icon(
                    Icons.search,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                )
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
