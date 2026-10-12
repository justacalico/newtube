import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import '../widgets/thumbnail.dart';
import '../widgets/video_grid.dart';
import 'channel_page.dart';
import 'watch_page.dart';

class SearchPage extends StatefulWidget {
  final String query;

  const SearchPage({super.key, required this.query});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  SearchResults _results = const SearchResults();
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
      final results = await AppScope.read(context).api.search(widget.query);
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
    return Scaffold(
      appBar: AppBar(title: Text('${l10n.searchResultsFor}: ${widget.query}')),
      body: FeedStateView(
        loading: _loading,
        error: _error,
        videos: _results.videos,
        onRetry: _load,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                                    borderRadius: BorderRadius.circular(24),
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
    );
  }
}
