import 'package:flutter/material.dart';

import '../../models/video_info.dart';
import '../../utils/format.dart';
import 'thumbnail.dart';
import 'video_actions_menu.dart';
import 'live_badge.dart';
import 'watched_badge.dart';

class VideoListTile extends StatelessWidget {
  final VideoInfo video;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? contentPadding;
  final bool selected;
  final Widget? trailing;
  final bool showWatchedBadge;

  const VideoListTile({
    super.key,
    required this.video,
    required this.onTap,
    this.contentPadding,
    this.selected = false,
    this.trailing,
    this.showWatchedBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget? badge;
    if (video.isLive) {
      badge = const LiveBadge();
    } else if (video.isUpcoming) {
      badge = const LiveBadge(upcoming: true);
    } else if (formatDuration(video.duration).isNotEmpty) {
      badge = DurationBadge(duration: video.duration);
    }
    return ListTile(
      selected: selected,
      contentPadding: contentPadding,
      leading: SizedBox(
        width: 96,
        height: 54,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoThumbnail(url: video.thumbnailUrl, width: 96, height: 54),
            if (showWatchedBadge)
              Positioned(
                left: 4,
                top: 4,
                child: WatchedBadge(videoId: video.id, compact: true),
              ),
            if (badge != null) Positioned(right: 6, bottom: 6, child: badge),
          ],
        ),
      ),
      title: Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(video.author),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?trailing,
          VideoActionsMenu(video: video),
        ],
      ),
      onTap: onTap,
      onLongPress: () => VideoActionsMenu.open(context, video),
    );
  }
}
