import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../state/playback_session.dart';
import 'thumbnail.dart';

class MiniPlayer extends StatelessWidget {
  final PlaybackSession session;
  final VoidCallback onExpand;

  const MiniPlayer({super.key, required this.session, required this.onExpand});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final player = session.player;
        final video = session.video;
        if (player == null || video == null || session.attached) {
          return const SizedBox.shrink();
        }
        final l10n = AppLocalizations.of(context);
        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: InkWell(
            onTap: onExpand,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 62,
                  child: Row(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: VideoThumbnail(
                          url: video.thumbnailUrl,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              video.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (session.queue.isNotEmpty)
                        IconButton(
                          tooltip: l10n.playNext,
                          icon: const Icon(Icons.skip_next),
                          onPressed: () {
                            final next = session.takeNext();
                            if (next != null) {
                              AppScope.read(context).requestWatch(next);
                            }
                          },
                        ),
                      StreamBuilder<bool>(
                        stream: player.playingStream,
                        initialData: player.playing,
                        builder: (context, snapshot) => IconButton(
                          tooltip: snapshot.data == true
                              ? l10n.pause
                              : l10n.play,
                          icon: Icon(
                            snapshot.data == true
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          onPressed: () => snapshot.data == true
                              ? player.pause()
                              : player.play(),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.close,
                        icon: const Icon(Icons.close),
                        onPressed: session.stop,
                      ),
                    ],
                  ),
                ),
                StreamBuilder<Duration>(
                  stream: player.durationStream,
                  initialData: player.duration,
                  builder: (context, durationSnap) {
                    final total = durationSnap.data ?? Duration.zero;
                    return StreamBuilder<Duration>(
                      stream: player.positionStream,
                      initialData: player.position,
                      builder: (context, posSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        return LinearProgressIndicator(
                          value: total > Duration.zero
                              ? (pos.inMilliseconds / total.inMilliseconds)
                                    .clamp(0.0, 1.0)
                              : 0,
                          minHeight: 2,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
