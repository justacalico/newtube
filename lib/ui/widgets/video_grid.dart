import 'package:flutter/material.dart';

import '../shell/title_bar.dart' show isDesktopPlatform;

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import 'cors_notice.dart';
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
  final Future<void> Function()? onRefresh;

  const FeedStateView({
    super.key,
    required this.loading,
    required this.error,
    required this.videos,
    required this.onRetry,
    required this.child,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final refresh = onRefresh;
    Widget scrollable(Widget inner) => RefreshIndicator(
      onRefresh: refresh ?? () async {},
      child: inner is ScrollView
          ? inner
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [inner],
            ),
    );
    if (error != null) {
      if (AppScope.read(context).isWeb) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) CorsNotice.show(context);
        });
      }
      if (refresh != null) {
        return scrollable(
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.errorLoading),
                const SizedBox(height: 8),
                FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
                if (AppScope.read(context).isWeb)
                  TextButton(
                    onPressed: () => CorsNotice.show(context),
                    child: Text(l10n.corsNoticeTitle),
                  ),
              ],
            ),
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.errorLoading),
            const SizedBox(height: 8),
            FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
            if (AppScope.read(context).isWeb)
              TextButton(
                onPressed: () => CorsNotice.show(context),
                child: Text(l10n.corsNoticeTitle),
              ),
          ],
        ),
      );
    }
    if (videos.isEmpty) {
      final empty = Center(child: Text(l10n.noVideos));
      return refresh != null ? scrollable(empty) : empty;
    }
    if (refresh == null) return child;
    return Column(
      children: [
        if (isDesktopPlatform)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.refreshFeed,
              onPressed: () => refresh(),
            ),
          ),
        Expanded(
          child: RefreshIndicator(onRefresh: refresh, child: child),
        ),
      ],
    );
  }
}
