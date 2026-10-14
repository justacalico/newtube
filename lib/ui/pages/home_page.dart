import 'package:flutter/material.dart';

import '../../models/video_info.dart';
import '../../services/home_feed.dart';
import '../../state/app_state.dart';
import '../../utils/feed_filter.dart';
import '../widgets/video_grid.dart';
import 'channel_page.dart';
import 'watch_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    final state = AppScope.read(context);
    try {
      final videos = await HomeFeed(
        api: state.api,
        history: state.history,
        subscriptions: state.subscriptions,
        searchHistory: state.searchHistory,
        watchLater: state.watchLater,
      ).fetch();
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
    return FeedStateView(
      loading: _loading,
      error: _error,
      videos: visibleVideos(
        _videos,
        AppScope.read(context).settings,
        AppScope.read(context),
      ),
      onRetry: _load,
      onRefresh: _load,
      child: VideoGrid(
        videos: visibleVideos(
          _videos,
          AppScope.read(context).settings,
          AppScope.read(context),
        ),
        onVideoTap: _openVideo,
        onChannelTap: _openChannel,
      ),
    );
  }
}
