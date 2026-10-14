import 'package:flutter/material.dart';

import '../../models/video_info.dart';
import '../../services/home_feed.dart';
import '../../state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/feed_filter.dart';
import '../widgets/video_card.dart';
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
      videos: visibleVideos(_videos, AppScope.read(context).settings),
      onRetry: _load,
      child: ListenableBuilder(
        listenable: AppScope.read(context).history,
        builder: (context, _) {
          final state = AppScope.read(context);
          final inProgress = state.history.inProgress;
          final l10n = AppLocalizations.of(context);
          return Column(
            children: [
              if (inProgress.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.continueWatching,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                SizedBox(
                  height: 112,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final video in inProgress.take(10))
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 160,
                            child: VideoCard(
                              video: video,
                              onTap: () => _openVideo(video),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: VideoGrid(
                  videos: visibleVideos(_videos, state.settings),
                  onVideoTap: _openVideo,
                  onChannelTap: _openChannel,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
