import 'package:flutter/material.dart';

import '../../models/video_info.dart';
import '../../state/app_state.dart';
import '../../utils/feed_filter.dart';
import '../widgets/video_grid.dart';
import 'channel_page.dart';
import 'watch_page.dart';

class TrendingPage extends StatefulWidget {
  const TrendingPage({super.key});

  @override
  State<TrendingPage> createState() => _TrendingPageState();
}

class _TrendingPageState extends State<TrendingPage> {
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
      final videos = await state.api.trending();
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
      videos: visibleVideos(_videos, AppScope.read(context).settings),
      onRetry: _load,
      onRefresh: _load,
      child: VideoGrid(
        videos: visibleVideos(_videos, AppScope.read(context).settings),
        onVideoTap: _openVideo,
        onChannelTap: _openChannel,
      ),
    );
  }
}
