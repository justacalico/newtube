import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../services/player_controller.dart';
import '../../utils/format.dart';

class PlayerView extends StatelessWidget {
  final PlayerController player;
  final List<PlayableStream> streams;
  final PlayableStream? current;
  final ValueChanged<PlayableStream> onQualitySelected;
  final VoidCallback onToggleFullscreen;
  final bool isFullscreen;

  const PlayerView({
    super.key,
    required this.player,
    required this.streams,
    required this.current,
    required this.onQualitySelected,
    required this.onToggleFullscreen,
    this.isFullscreen = false,
  });

  void _skipBy(Duration delta) {
    var target = player.position + delta;
    final total = player.duration;
    if (target < Duration.zero) target = Duration.zero;
    if (total > Duration.zero && target > total) target = total;
    player.seek(target);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _skipBy(const Duration(seconds: -5)),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _skipBy(const Duration(seconds: 5)),
      },
      child: Focus(
        autofocus: true,
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(child: player.buildView(context)),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => player.playing ? player.pause() : player.play(),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: StreamBuilder<bool>(
                  stream: player.bufferingStream,
                  initialData: player.buffering,
                  builder: (context, snapshot) => snapshot.data == true
                      ? const LinearProgressIndicator(minHeight: 3)
                      : const SizedBox(height: 3),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      StreamBuilder<bool>(
                        stream: player.playingStream,
                        initialData: player.playing,
                        builder: (context, snapshot) => IconButton(
                          icon: Icon(
                            snapshot.data == true
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          color: Colors.white,
                          onPressed: () => snapshot.data == true
                              ? player.pause()
                              : player.play(),
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
                              final clamped = pos > total ? total : pos;
                              return Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      formatDuration(clamped),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Expanded(
                                      child: Slider(
                                        value: clamped.inMilliseconds
                                            .toDouble()
                                            .clamp(
                                              0,
                                              (total.inMilliseconds).toDouble(),
                                            ),
                                        max: total.inMilliseconds
                                            .toDouble()
                                            .clamp(1, double.infinity),
                                        onChanged: total == Duration.zero
                                            ? null
                                            : (v) => player.seek(
                                                Duration(
                                                  milliseconds: v.round(),
                                                ),
                                              ),
                                      ),
                                    ),
                                    Text(
                                      formatDuration(total),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      PopupMenuButton<PlayableStream>(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        tooltip: l10n.quality,
                        onSelected: onQualitySelected,
                        itemBuilder: (context) => [
                          for (final s in streams)
                            PopupMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  if (s == current)
                                    const Icon(Icons.check, size: 18)
                                  else
                                    const SizedBox(width: 18),
                                  const SizedBox(width: 8),
                                  Text(s.hasVideo ? s.quality : l10n.audioOnly),
                                ],
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          isFullscreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                        ),
                        color: Colors.white,
                        tooltip: l10n.fullscreen,
                        onPressed: onToggleFullscreen,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
