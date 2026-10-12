import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import 'video_card.dart';

class VideoGrid extends StatelessWidget {
  final List<VideoInfo> videos;
  final void Function(VideoInfo video) onVideoTap;
  final void Function(VideoInfo video)? onChannelTap;

  const VideoGrid({
    super.key,
    required this.videos,
    required this.onVideoTap,
    this.onChannelTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 320).floor().clamp(1, 5);
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 16 / 13,
          ),
          itemCount: videos.length,
          itemBuilder: (context, i) {
            final video = videos[i];
            return VideoCard(
              video: video,
              onTap: () => onVideoTap(video),
              onChannelTap: onChannelTap == null
                  ? null
                  : () => onChannelTap!(video),
            );
          },
        );
      },
    );
  }
}

class FeedStateView extends StatelessWidget {
  final bool loading;
  final Object? error;
  final List<VideoInfo> videos;
  final VoidCallback onRetry;
  final Widget child;

  const FeedStateView({
    super.key,
    required this.loading,
    required this.error,
    required this.videos,
    required this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.errorLoading),
            const SizedBox(height: 8),
            FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      );
    }
    if (videos.isEmpty) {
      return Center(child: Text(l10n.noVideos));
    }
    return child;
  }
}
