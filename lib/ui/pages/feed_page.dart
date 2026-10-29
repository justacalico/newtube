import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import '../../utils/feed_filter.dart';
import '../layout.dart';
import '../widgets/content_width.dart';
import '../widgets/page_header.dart';
import '../widgets/video_grid.dart';
import 'channel_page.dart';
import 'watch_page.dart';

class FeedPage extends StatefulWidget {
  final String title;
  final Future<List<VideoInfo>> Function(AppState state) fetch;

  const FeedPage({super.key, required this.title, required this.fetch});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<VideoInfo> _videos = const [];
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
      final videos = await widget.fetch(AppScope.read(context));
      if (!mounted) return;
      setState(() {
        _videos = videos;
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

  void _openChannel(VideoInfo video) {
    if (video.channelId.isEmpty) return;
    openChannelPage(context, video.channelId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = AppScope.read(context);
    return ContentWidth(
      maxWidth: feedMaxWidth,
      child: Column(
        children: [
          PageHeader(
            title: widget.title,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.refreshFeed,
                onPressed: _load,
              ),
            ],
          ),
          Expanded(
            child: FeedStateView(
              loading: _loading,
              error: _error,
              videos: _videos,
              onRetry: _load,
              onRefresh: _load,
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  state.history,
                  state.hidden,
                  state.settings,
                ]),
                builder: (context, _) => VideoGrid(
                  videos: visibleVideos(_videos, state.settings, state),
                  onVideoTap: _openVideo,
                  onChannelTap: _openChannel,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
