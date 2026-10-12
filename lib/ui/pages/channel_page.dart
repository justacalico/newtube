import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../widgets/subscribe_button.dart';
import '../widgets/thumbnail.dart';
import '../widgets/video_grid.dart';
import 'watch_page.dart';

class ChannelPage extends StatefulWidget {
  final String channelId;

  const ChannelPage({super.key, required this.channelId});

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  ChannelInfo? _channel;
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
      final api = AppScope.read(context).api;
      final channel = await api.channel(widget.channelId);
      final videos = [
        for (final v in await api.channelVideos(widget.channelId))
          if (v.author.isEmpty) v.copyWith(author: channel.name) else v,
      ];
      if (!mounted) return;
      setState(() {
        _channel = channel;
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

  void _openVideo(VideoInfo video) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => WatchPage(video: video)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final channel = _channel;
    return Scaffold(
      appBar: AppBar(title: Text(channel?.name ?? '')),
      body: FeedStateView(
        loading: _loading,
        error: _error,
        videos: _videos,
        onRetry: _load,
        child: Column(
          children: [
            if (channel != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    VideoThumbnail(
                      url: channel.thumbnailUrl,
                      width: 64,
                      height: 64,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            channel.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (channel.subscribers != null)
                            Text(
                              '${formatViewCount(channel.subscribers!)} ${l10n.subscribers}',
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
              child: VideoGrid(videos: _videos, onVideoTap: _openVideo),
            ),
          ],
        ),
      ),
    );
  }
}
