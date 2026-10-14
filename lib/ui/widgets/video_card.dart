import 'package:flutter/material.dart';

import '../../state/app_state.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../utils/format.dart';
import 'thumbnail.dart';
import 'video_actions_menu.dart';
import 'live_badge.dart';
import 'watched_badge.dart';

class VideoCard extends StatelessWidget {
  final VideoInfo video;
  final VoidCallback onTap;
  final VoidCallback? onChannelTap;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
    this.onChannelTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final duration = formatDuration(video.duration);

    final meta = [
      if (video.viewCount > 0)
        '${formatViewCount(video.viewCount)} ${l10n.views}',
      if (video.uploaded != null && video.uploaded!.isNotEmpty) video.uploaded!,
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => VideoActionsMenu.open(context, video),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VideoThumbnail(
                    url: video.thumbnailUrl,
                    borderRadius: BorderRadius.zero,
                  ),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: WatchedBadge(videoId: video.id),
                  ),
                  if (video.isShort)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppLocalizations.of(context).shortsBadge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Builder(
                    builder: (context) {
                      final state = AppScope.read(context);
                      final pos = state.history.positionFor(video.id);
                      final total = video.duration;
                      if (pos == null ||
                          pos <= Duration.zero ||
                          total == null ||
                          total <= Duration.zero) {
                        return const SizedBox.shrink();
                      }
                      final frac = (pos.inMilliseconds / total.inMilliseconds)
                          .clamp(0.0, 1.0);
                      return Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: frac,
                          minHeight: 3,
                          backgroundColor: Colors.black54,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.error,
                          ),
                        ),
                      );
                    },
                  ),
                  if (video.isLive)
                    const Positioned(right: 6, bottom: 6, child: LiveBadge())
                  else if (video.isUpcoming)
                    const Positioned(
                      right: 6,
                      bottom: 6,
                      child: LiveBadge(upcoming: true),
                    )
                  else if (duration.isNotEmpty)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          duration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onChannelTap,
                    child: Text(
                      video.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (meta.isNotEmpty)
                        Expanded(
                          child: Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      VideoActionsMenu(video: video),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
