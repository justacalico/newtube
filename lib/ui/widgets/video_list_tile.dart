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

  const VideoListTile({
    super.key,
    required this.video,
    required this.onTap,
    this.contentPadding,
    this.selected = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
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
            Positioned(
              left: 2,
              bottom: 2,
              child: WatchedBadge(videoId: video.id),
            ),
          ],
        ),
      ),
      title: Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(video.author),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            trailing!
          else if (video.isLive)
            const LiveBadge()
          else if (video.isUpcoming)
            const LiveBadge(upcoming: true)
          else if (video.duration != null)
            Text(formatDuration(video.duration)),
          VideoActionsMenu(video: video),
        ],
      ),
      onTap: onTap,
      onLongPress: () => VideoActionsMenu.open(context, video),
    );
  }
}
