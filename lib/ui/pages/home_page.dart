import 'package:flutter/material.dart';

import '../../models/video_info.dart';
import '../../state/app_state.dart';
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
    try {
      final videos = await AppScope.read(context).api.homeFeed();
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
      videos: _videos,
      onRetry: _load,
      child: VideoGrid(
        videos: _videos,
        onVideoTap: _openVideo,
        onChannelTap: _openChannel,
      ),
    );
  }
}
