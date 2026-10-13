import 'package:flutter/material.dart';

import '../../models/video_info.dart';
import '../../utils/format.dart';
import 'thumbnail.dart';

class VideoListTile extends StatelessWidget {
  final VideoInfo video;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? contentPadding;
  final bool selected;

  const VideoListTile({
    super.key,
    required this.video,
    required this.onTap,
    this.contentPadding,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      contentPadding: contentPadding,
      leading: VideoThumbnail(url: video.thumbnailUrl, width: 96, height: 54),
      title: Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(video.author),
      trailing: video.duration == null
          ? null
          : Text(formatDuration(video.duration)),
      onTap: onTap,
    );
  }
}
