import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import '../widgets/thumbnail.dart';
import '../../utils/feed_filter.dart';
import '../widgets/video_grid.dart';
import 'channel_page.dart';
import 'watch_page.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  List<VideoInfo> _videos = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final state = AppScope.read(context);
    final channels = state.subscriptions.channels;
    if (channels.isEmpty) return;
    setState(() => _loading = true);
    final videos = <VideoInfo>[];
    for (final channel in channels) {
      try {
        videos.addAll([
          for (final v in await state.api.channelVideos(channel.id))
            if (v.author.isEmpty) v.copyWith(author: channel.name) else v,
        ]);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _videos = videos;
      _loading = false;
    });
  }

  void _openVideo(VideoInfo video) => openWatchPage(context, video);

  void _openChannel(String channelId) => openChannelPage(context, channelId);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: state.subscriptions,
      builder: (context, _) {
        final channels = state.subscriptions.channels;
        if (channels.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.noSubscriptions,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(l10n.noSubscriptionsHint),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 104,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: [
                  for (final channel in channels)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _openChannel(channel.id),
                          child: SizedBox(
                            width: 88,
                            child: Column(
                              children: [
                                VideoThumbnail(
                                  url: channel.thumbnailUrl,
                                  width: 48,
                                  height: 48,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  channel.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => state.subscriptions
                                      .unsubscribe(channel.id, state.prefs),
                                  child: Text(
                                    l10n.unsubscribe,
                                    style: const TextStyle(fontSize: 11),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.latestFromSubscriptions,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadVideos,
                      child: VideoGrid(
                        videos: visibleVideos(_videos, state.settings, state),
                        onVideoTap: _openVideo,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
