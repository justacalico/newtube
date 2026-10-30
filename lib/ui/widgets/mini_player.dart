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
        final theme = Theme.of(context);
        return Semantics(
          label: video.title,
          child: Material(
            color: theme.colorScheme.surfaceContainerHigh,
            child: InkWell(
              onTap: onExpand,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      height: 62,
                      child: Row(
                        children: [
                          Expanded(
                            child: Dismissible(
                              key: const Key('mini_player'),
                              direction: DismissDirection.horizontal,
                              dismissThresholds: const {
                                DismissDirection.horizontal: 0.4,
                              },
                              onDismissed: (_) => session.stop(),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: session.audioOnly
                                            ? VideoThumbnail(
                                                url: video.thumbnailUrl,
                                                borderRadius: BorderRadius.zero,
                                              )
                                            : FittedBox(
                                                fit: BoxFit.cover,
                                                child: SizedBox(
                                                  width: 320,
                                                  height: 180,
                                                  child: player.buildView(
                                                    context,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          video.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        Text(
                                          video.author,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (session.hasPrevious)
                            IconButton(
                              tooltip: l10n.previousVideo,
                              icon: const Icon(Icons.skip_previous),
                              onPressed: () {
                                final prev = session.takePrevious();
                                if (prev != null) {
                                  AppScope.read(context).requestWatch(prev);
                                }
                              },
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
                          return Stack(
                            children: [
                              StreamBuilder<Duration>(
                                stream: player.bufferedStream,
                                initialData: player.buffered,
                                builder: (context, bufSnap) {
                                  final buf = bufSnap.data ?? Duration.zero;
                                  return LinearProgressIndicator(
                                    value: total > Duration.zero
                                        ? (buf.inMilliseconds /
                                                  total.inMilliseconds)
                                              .clamp(0.0, 1.0)
                                        : 0,
                                    minHeight: 3,
                                    color: theme.colorScheme.outline,
                                    backgroundColor: Colors.transparent,
                                  );
                                },
                              ),
                              LinearProgressIndicator(
                                value: total > Duration.zero
                                    ? (pos.inMilliseconds /
                                              total.inMilliseconds)
                                          .clamp(0.0, 1.0)
                                    : 0,
                                minHeight: 3,
                                backgroundColor: Colors.transparent,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
