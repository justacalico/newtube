import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../services/player_controller.dart';
import '../../services/sleep_timer.dart';
import '../../utils/chapters.dart';
import '../../utils/format.dart';

class PlayerView extends StatelessWidget {
  final PlayerController player;
  final List<PlayableStream> streams;
  final PlayableStream? current;
  final PlayableStream? currentAudio;
  final ValueChanged<PlayableStream> onQualitySelected;
  final ValueChanged<PlayableStream> onAudioSelected;
  final VoidCallback onToggleFullscreen;
  final bool isFullscreen;
  final SleepTimer? sleepTimer;
  final List<VideoChapter> chapters;

  const PlayerView({
    super.key,
    required this.player,
    required this.streams,
    required this.current,
    this.currentAudio,
    required this.onQualitySelected,
    required this.onAudioSelected,
    required this.onToggleFullscreen,
    this.isFullscreen = false,
    this.sleepTimer,
    this.chapters = const [],
  });

  static const _rates = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  List<PopupMenuEntry<PlayableStream>> _streamItems(
    Iterable<PlayableStream> list,
    PlayableStream? selected,
    String Function(PlayableStream) label,
  ) => [
    for (final s in list)
      PopupMenuItem(
        value: s,
        child: Row(
          children: [
            if (s == selected)
              const Icon(Icons.check, size: 18)
            else
              const SizedBox(width: 18),
            const SizedBox(width: 8),
            Text(label(s)),
          ],
        ),
      ),
  ];

  void _togglePlayback() => player.playing ? player.pause() : player.play();

  void _toggleMute() => player.setMuted(!player.muted);

  void _adjustVolume(double delta) =>
      player.setVolume((player.volume + delta).clamp(0.0, 1.0));

  void _stepRate(int direction) {
    var index = _rates.indexWhere((r) => r >= player.rate - 0.001);
    if (index < 0) index = _rates.length - 1;
    player.setRate(_rates[(index + direction).clamp(0, _rates.length - 1)]);
  }

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
        const SingleActivator(LogicalKeyboardKey.keyJ): () =>
            _skipBy(const Duration(seconds: -10)),
        const SingleActivator(LogicalKeyboardKey.keyL): () =>
            _skipBy(const Duration(seconds: 10)),
        const SingleActivator(LogicalKeyboardKey.space): _togglePlayback,
        const SingleActivator(LogicalKeyboardKey.keyK): _togglePlayback,
        const SingleActivator(LogicalKeyboardKey.keyM): _toggleMute,
        const SingleActivator(LogicalKeyboardKey.keyF): onToggleFullscreen,
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _adjustVolume(0.05),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _adjustVolume(-0.05),
        const SingleActivator(LogicalKeyboardKey.comma): () => _stepRate(-1),
        const SingleActivator(LogicalKeyboardKey.period): () => _stepRate(1),
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
                  onTap: _togglePlayback,
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
                              final chapter = chapterAt(chapters, clamped);
                              return Expanded(
                                child: Row(
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          formatDuration(clamped),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (chapter != null)
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 120,
                                            ),
                                            child: Text(
                                              chapter.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Expanded(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Slider(
                                            value: clamped.inMilliseconds
                                                .toDouble()
                                                .clamp(
                                                  0,
                                                  (total.inMilliseconds)
                                                      .toDouble(),
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
                                          if (total > Duration.zero)
                                            Positioned.fill(
                                              child: IgnorePointer(
                                                child: LayoutBuilder(
                                                  builder: (context, cons) => Stack(
                                                    children: [
                                                      for (final marker
                                                          in chapters)
                                                        if (marker.start >
                                                                Duration.zero &&
                                                            marker.start <
                                                                total)
                                                          Positioned(
                                                            left:
                                                                12 +
                                                                (cons.maxWidth -
                                                                        24) *
                                                                    (marker
                                                                            .start
                                                                            .inMilliseconds /
                                                                        total
                                                                            .inMilliseconds),
                                                            top:
                                                                (cons.maxHeight -
                                                                    10) /
                                                                2,
                                                            child: Container(
                                                              width: 2,
                                                              height: 10,
                                                              color: Colors
                                                                  .white38,
                                                            ),
                                                          ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
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
                      StreamBuilder<double>(
                        stream: player.rateStream,
                        initialData: player.rate,
                        builder: (context, snapshot) => PopupMenuButton<double>(
                          icon: const Icon(Icons.speed, color: Colors.white),
                          tooltip: l10n.playbackSpeed,
                          onSelected: player.setRate,
                          itemBuilder: (context) => [
                            for (final r in _rates)
                              PopupMenuItem(
                                value: r,
                                child: Row(
                                  children: [
                                    if (r == snapshot.data)
                                      const Icon(Icons.check, size: 18)
                                    else
                                      const SizedBox(width: 18),
                                    const SizedBox(width: 8),
                                    Text(r == 1.0 ? l10n.speedNormal : '${r}x'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (sleepTimer != null)
                        ListenableBuilder(
                          listenable: sleepTimer!,
                          builder: (context, _) {
                            final timer = sleepTimer!;
                            final left = timer.remaining;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (left != null)
                                  Text(
                                    formatDuration(left),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                PopupMenuButton<int>(
                                  icon: Icon(
                                    Icons.bedtime_outlined,
                                    color: timer.active
                                        ? Colors.amber
                                        : Colors.white,
                                  ),
                                  tooltip: l10n.sleepTimer,
                                  onSelected: (value) {
                                    if (value == 0) {
                                      timer.cancel();
                                    } else if (value < 0) {
                                      timer.startAtEndOfVideo();
                                    } else {
                                      timer.startAfter(
                                        Duration(minutes: value),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    for (final m in const [15, 30, 45, 60])
                                      PopupMenuItem(
                                        value: m,
                                        child: Text(l10n.sleepTimerMinutes(m)),
                                      ),
                                    PopupMenuItem(
                                      value: -1,
                                      child: Text(l10n.sleepTimerEndOfVideo),
                                    ),
                                    if (timer.active)
                                      PopupMenuItem(
                                        value: 0,
                                        child: Text(l10n.sleepTimerOff),
                                      ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      PopupMenuButton<PlayableStream>(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        tooltip: l10n.quality,
                        onSelected: onQualitySelected,
                        itemBuilder: (context) => _streamItems(
                          streams.where((s) => s.hasVideo),
                          current,
                          (s) => s.quality,
                        ),
                      ),
                      if (streams.any((s) => !s.hasVideo))
                        PopupMenuButton<PlayableStream>(
                          icon: const Icon(
                            Icons.audiotrack,
                            color: Colors.white,
                          ),
                          tooltip: l10n.audio,
                          onSelected: onAudioSelected,
                          itemBuilder: (context) => _streamItems(
                            streams.where((s) => !s.hasVideo),
                            currentAudio ??
                                (current?.hasVideo == false ? current : null),
                            (s) =>
                                s.audioTrackName ??
                                s.audioLanguage ??
                                s.quality,
                          ),
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
