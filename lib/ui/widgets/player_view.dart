import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../services/pip_actions.dart';
import '../../services/player_controller.dart';
import '../../services/sleep_timer.dart';
import '../../services/sponsor_block.dart';
import '../../utils/chapters.dart';
import '../../utils/format.dart';

class PlayerView extends StatefulWidget {
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
  final SegmentSkipper? segmentSkipper;
  final PipActions? pipActions;

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
    this.segmentSkipper,
    this.pipActions,
  });

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  static const _rates = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  static const _hideDelay = Duration(seconds: 3);

  PlayerController get _player => widget.player;

  StreamSubscription<bool>? _playingSub;
  Timer? _hideTimer;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    _playingSub = _player.playingStream.listen(_onPlayingChanged);
    if (_player.playing) _scheduleHide();
  }

  @override
  void didUpdateWidget(PlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      _playingSub?.cancel();
      _playingSub = _player.playingStream.listen(_onPlayingChanged);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _playingSub?.cancel();
    super.dispose();
  }

  void _onPlayingChanged(bool playing) {
    if (playing) {
      _scheduleHide();
    } else {
      _hideTimer?.cancel();
      if (!_controlsVisible) setState(() => _controlsVisible = true);
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideDelay, () {
      if (mounted && _player.playing && _controlsVisible) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _showControls() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _hideControls() {
    if (_player.playing && _controlsVisible) {
      setState(() => _controlsVisible = false);
    }
  }

  List<Widget> _streamItems(
    Iterable<PlayableStream> list,
    PlayableStream? selected,
    String Function(PlayableStream) label,
    ValueChanged<PlayableStream> onSelected,
  ) => [
    for (final s in list)
      MenuItemButton(
        onPressed: () => onSelected(s),
        leadingIcon: s == selected
            ? const Icon(Icons.check, size: 18)
            : const SizedBox(width: 18),
        child: Text(label(s)),
      ),
  ];

  Widget _settingsMenu(AppLocalizations l10n, double rate) {
    final timer = widget.sleepTimer;
    final audioStreams = widget.streams.where((s) => !s.hasVideo);
    return MenuAnchor(
      builder: (context, controller, child) => IconButton(
        icon: const Icon(Icons.settings, color: Colors.white),
        tooltip: l10n.navSettings,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        SubmenuButton(
          leadingIcon: const Icon(Icons.video_settings),
          menuChildren: _streamItems(
            widget.streams.where((s) => s.hasVideo),
            widget.current,
            (s) => s.quality,
            widget.onQualitySelected,
          ),
          child: Text(l10n.quality),
        ),
        if (audioStreams.isNotEmpty)
          SubmenuButton(
            leadingIcon: const Icon(Icons.audiotrack),
            menuChildren: _streamItems(
              audioStreams,
              widget.currentAudio ??
                  (widget.current?.hasVideo == false ? widget.current : null),
              (s) => s.audioTrackName ?? s.audioLanguage ?? s.quality,
              widget.onAudioSelected,
            ),
            child: Text(l10n.audio),
          ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.speed),
          menuChildren: [
            for (final r in _rates)
              MenuItemButton(
                onPressed: () => _player.setRate(r),
                leadingIcon: r == rate
                    ? const Icon(Icons.check, size: 18)
                    : const SizedBox(width: 18),
                child: Text(r == 1.0 ? l10n.speedNormal : '${r}x'),
              ),
          ],
          child: Text(l10n.playbackSpeed),
        ),
        if (timer != null)
          SubmenuButton(
            leadingIcon: Icon(
              Icons.bedtime_outlined,
              color: timer.active ? Colors.amber : null,
            ),
            menuChildren: [
              for (final m in const [15, 30, 45, 60])
                MenuItemButton(
                  onPressed: () => timer.startAfter(Duration(minutes: m)),
                  child: Text(l10n.sleepTimerMinutes(m)),
                ),
              MenuItemButton(
                onPressed: timer.startAtEndOfVideo,
                child: Text(l10n.sleepTimerEndOfVideo),
              ),
              if (timer.active)
                MenuItemButton(
                  onPressed: timer.cancel,
                  child: Text(l10n.sleepTimerOff),
                ),
            ],
            child: Text(l10n.sleepTimer),
          ),
      ],
    );
  }

  void _togglePlayback() {
    _showControls();
    _player.playing ? _player.pause() : _player.play();
  }

  void _toggleMute() {
    _showControls();
    _player.setMuted(!_player.muted);
  }

  void _adjustVolume(double delta) {
    _showControls();
    _player.setVolume((_player.volume + delta).clamp(0.0, 1.0));
  }

  void _stepRate(int direction) {
    _showControls();
    var index = _rates.indexWhere((r) => r >= _player.rate - 0.001);
    if (index < 0) index = _rates.length - 1;
    _player.setRate(_rates[(index + direction).clamp(0, _rates.length - 1)]);
  }

  void _skipBy(Duration delta) {
    _showControls();
    var target = _player.position + delta;
    final total = _player.duration;
    if (target < Duration.zero) target = Duration.zero;
    if (total > Duration.zero && target > total) target = total;
    _player.seek(target);
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
        const SingleActivator(LogicalKeyboardKey.keyF): () {
          _showControls();
          widget.onToggleFullscreen();
        },
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _adjustVolume(0.05),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _adjustVolume(-0.05),
        const SingleActivator(LogicalKeyboardKey.comma): () => _stepRate(-1),
        const SingleActivator(LogicalKeyboardKey.period): () => _stepRate(1),
      },
      child: Focus(
        autofocus: true,
        child: MouseRegion(
          cursor: _controlsVisible
              ? MouseCursor.defer
              : SystemMouseCursors.none,
          onHover: (_) => _showControls(),
          onExit: (_) => _hideControls(),
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(child: _player.buildView(context)),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _togglePlayback,
                  ),
                ),
                if (widget.segmentSkipper != null)
                  Positioned(
                    right: 8,
                    bottom: 56,
                    child: ListenableBuilder(
                      listenable: widget.segmentSkipper!,
                      builder: (context, _) {
                        if (widget.segmentSkipper!.active == null) {
                          return const SizedBox.shrink();
                        }
                        return FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: widget.segmentSkipper!.skip,
                          icon: const Icon(Icons.skip_next, size: 18),
                          label: Text(l10n.skipSegment),
                        );
                      },
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: StreamBuilder<bool>(
                    stream: _player.bufferingStream,
                    initialData: _player.buffering,
                    builder: (context, snapshot) => snapshot.data == true
                        ? const LinearProgressIndicator(minHeight: 3)
                        : const SizedBox(height: 3),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    opacity: _controlsVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_controlsVisible,
                      child: Listener(
                        onPointerDown: (_) => _showControls(),
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              StreamBuilder<bool>(
                                stream: _player.playingStream,
                                initialData: _player.playing,
                                builder: (context, snapshot) => IconButton(
                                  icon: Icon(
                                    snapshot.data == true
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                  ),
                                  color: Colors.white,
                                  onPressed: () => snapshot.data == true
                                      ? _player.pause()
                                      : _player.play(),
                                ),
                              ),
                              StreamBuilder<Duration>(
                                stream: _player.durationStream,
                                initialData: _player.duration,
                                builder: (context, durationSnap) {
                                  final total =
                                      durationSnap.data ?? Duration.zero;
                                  return StreamBuilder<Duration>(
                                    stream: _player.positionStream,
                                    initialData: _player.position,
                                    builder: (context, posSnap) {
                                      final pos = posSnap.data ?? Duration.zero;
                                      final clamped = pos > total ? total : pos;
                                      final chapter = chapterAt(
                                        widget.chapters,
                                        clamped,
                                      );
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
                                                    constraints:
                                                        const BoxConstraints(
                                                          maxWidth: 120,
                                                        ),
                                                    child: Text(
                                                      chapter.title,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                                                    value: clamped
                                                        .inMilliseconds
                                                        .toDouble()
                                                        .clamp(
                                                          0,
                                                          (total.inMilliseconds)
                                                              .toDouble(),
                                                        ),
                                                    max: total.inMilliseconds
                                                        .toDouble()
                                                        .clamp(
                                                          1,
                                                          double.infinity,
                                                        ),
                                                    onChanged:
                                                        total == Duration.zero
                                                        ? null
                                                        : (v) => _player.seek(
                                                            Duration(
                                                              milliseconds: v
                                                                  .round(),
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
                                                                  in widget
                                                                      .chapters)
                                                                if (marker.start >
                                                                        Duration
                                                                            .zero &&
                                                                    marker.start <
                                                                        total)
                                                                  Positioned(
                                                                    left:
                                                                        12 +
                                                                        (cons.maxWidth -
                                                                                24) *
                                                                            (marker.start.inMilliseconds /
                                                                                total.inMilliseconds),
                                                                    top:
                                                                        (cons.maxHeight -
                                                                            10) /
                                                                        2,
                                                                    child: Container(
                                                                      width: 2,
                                                                      height:
                                                                          10,
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
                              if (widget.pipActions != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.picture_in_picture_alt_outlined,
                                    color: Colors.white,
                                  ),
                                  tooltip: l10n.pictureInPicture,
                                  onPressed: () =>
                                      widget.pipActions!.enterPip(),
                                ),
                              StreamBuilder<double>(
                                stream: _player.rateStream,
                                initialData: _player.rate,
                                builder: (context, snapshot) {
                                  final timer = widget.sleepTimer;
                                  if (timer == null) {
                                    return _settingsMenu(
                                      l10n,
                                      snapshot.data ?? _player.rate,
                                    );
                                  }
                                  return ListenableBuilder(
                                    listenable: timer,
                                    builder: (context, _) => Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (timer.remaining != null)
                                          Text(
                                            formatDuration(timer.remaining!),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        _settingsMenu(
                                          l10n,
                                          snapshot.data ?? _player.rate,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  widget.isFullscreen
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                ),
                                color: Colors.white,
                                tooltip: l10n.fullscreen,
                                onPressed: widget.onToggleFullscreen,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
