import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../services/pip_actions.dart';
import '../../services/player_controller.dart';
import '../../services/sleep_timer.dart';
import '../../services/sponsor_block.dart';
import '../../state/app_state.dart';
import '../../state/playback_session.dart';
import '../../utils/captions.dart';
import '../../utils/chapters.dart';
import '../../utils/storyboard.dart';
import '../../utils/debug_log.dart';
import '../../utils/format.dart';
import 'live_badge.dart';

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
  final WidgetBuilder? endScreenBuilder;
  final List<CaptionTrack> captions;
  final CaptionTrack? selectedCaption;
  final ValueChanged<CaptionTrack?>? onCaptionSelected;
  final VoidCallback? onDismiss;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onPip;
  final bool audioOnly;
  final String? artworkUrl;
  final ValueChanged<bool>? onAudioOnlyChanged;
  final Storyboard? storyboard;
  final List<HeatMarker> heatmap;
  final bool live;

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
    this.endScreenBuilder,
    this.captions = const [],
    this.selectedCaption,
    this.onCaptionSelected,
    this.onDismiss,
    this.onNext,
    this.onPrevious,
    this.onPip,
    this.audioOnly = false,
    this.storyboard,
    this.heatmap = const [],
    this.live = false,
    this.artworkUrl,
    this.onAudioOnlyChanged,
  });

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  static const _rates = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  static const _hideDelay = Duration(seconds: 3);

  PlayerController get _player => widget.player;

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _completedSub;
  Timer? _hideTimer;
  bool _controlsVisible = true;
  bool _ended = false;
  List<CaptionCue> _cues = const [];
  CaptionTrack? _cuesTrack;
  Timer? _tapTimer;
  int _lastTapSide = 0;
  int _seekFlashSide = 0;
  Timer? _seekFlashTimer;
  double? _previewFraction;
  bool _statsVisible = false;
  bool _holding = false;
  double _heldRate = 1.0;
  int _dragSide = 0;
  double _dragDy = 0;
  double? _dragBase;
  double? _hudValue;
  bool _hudVolume = true;
  bool _volumePopup = false;

  @override
  void initState() {
    super.initState();
    _playingSub = _player.playingStream.listen(_onPlayingChanged);
    _completedSub = _player.completedStream.listen(_onCompleted);
    if (_player.playing) _scheduleHide();
    _loadCues();
  }

  @override
  void didUpdateWidget(PlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      _playingSub?.cancel();
      _playingSub = _player.playingStream.listen(_onPlayingChanged);
      _completedSub?.cancel();
      _completedSub = _player.completedStream.listen(_onCompleted);
    }
    if (oldWidget.selectedCaption != widget.selectedCaption) _loadCues();
  }

  void _loadCues() {
    final track = widget.selectedCaption;
    if (track == _cuesTrack) return;
    _cuesTrack = track;
    if (track == null) {
      if (_cues.isNotEmpty) setState(() => _cues = const []);
      return;
    }
    AppScope.read(context).api
        .captions(track)
        .then((cues) {
          if (mounted && widget.selectedCaption == track) {
            setState(() => _cues = cues);
          }
        })
        .catchError((Object e) {
          debugLog('[player] captions ${track.languageCode}: $e');
        });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekFlashTimer?.cancel();
    _tapTimer?.cancel();
    _playingSub?.cancel();
    _completedSub?.cancel();
    super.dispose();
  }

  void _onCompleted(bool done) {
    if (done && !_ended) setState(() => _ended = true);
  }

  void _onPlayingChanged(bool playing) {
    if (playing) {
      _scheduleHide();
      if (_ended) setState(() => _ended = false);
    } else {
      _hideTimer?.cancel();
      if (!_controlsVisible) setState(() => _controlsVisible = true);
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideDelay, () {
      if (mounted && _player.playing && _controlsVisible) {
        setState(() {
          _controlsVisible = false;
          _volumePopup = false;
        });
      }
    });
  }

  void _showControls() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _hideControls() {
    if (_player.playing && _controlsVisible) {
      setState(() {
        _controlsVisible = false;
        _volumePopup = false;
      });
    }
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideControls();
    } else {
      _showControls();
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
    final session = AppScope.read(context).playback;
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
        if (widget.captions.isNotEmpty && widget.onCaptionSelected != null)
          SubmenuButton(
            leadingIcon: const Icon(Icons.closed_caption),
            menuChildren: [
              MenuItemButton(
                onPressed: () => widget.onCaptionSelected!(null),
                leadingIcon: widget.selectedCaption == null
                    ? const Icon(Icons.check, size: 18)
                    : const SizedBox(width: 18),
                child: Text(l10n.captionsOff),
              ),
              for (final t in widget.captions)
                MenuItemButton(
                  onPressed: () => widget.onCaptionSelected!(t),
                  leadingIcon: t == widget.selectedCaption
                      ? const Icon(Icons.check, size: 18)
                      : const SizedBox(width: 18),
                  child: Text(t.name.isEmpty ? t.languageCode : t.name),
                ),
            ],
            child: Text(l10n.captions),
          ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.speed),
          menuChildren: [
            for (final r in _rates)
              MenuItemButton(
                onPressed: () => _setRate(r),
                leadingIcon: r == rate
                    ? const Icon(Icons.check, size: 18)
                    : const SizedBox(width: 18),
                child: Text(r == 1.0 ? l10n.speedNormal : '${r}x'),
              ),
          ],
          child: Text(l10n.playbackSpeed),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.aspect_ratio),
          menuChildren: [
            for (final entry in [
              (BoxFit.contain, l10n.fitContain),
              (BoxFit.cover, l10n.fitCover),
              (BoxFit.fill, l10n.fitFill),
            ])
              MenuItemButton(
                onPressed: () => _player.videoFit.value = entry.$1,
                leadingIcon: entry.$1 == _player.videoFit.value
                    ? const Icon(Icons.check, size: 18)
                    : const SizedBox(width: 18),
                child: Text(entry.$2),
              ),
          ],
          child: Text(l10n.videoFit),
        ),
        MenuItemButton(
          onPressed: () => setState(() => _statsVisible = !_statsVisible),
          leadingIcon: _statsVisible
              ? const Icon(Icons.check, size: 18)
              : const SizedBox(width: 18),
          child: Text(l10n.statsForNerds),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.repeat),
          menuChildren: [
            for (final entry in [
              (RepeatMode.off, l10n.repeatOff),
              (RepeatMode.all, l10n.repeatAll),
              (RepeatMode.one, l10n.repeatOne),
            ])
              MenuItemButton(
                onPressed: () => session.repeatMode = entry.$1,
                leadingIcon: entry.$1 == session.repeatMode
                    ? const Icon(Icons.check, size: 18)
                    : const SizedBox(width: 18),
                child: Text(entry.$2),
              ),
          ],
          child: Text(l10n.repeat),
        ),
        if (widget.onAudioOnlyChanged != null)
          MenuItemButton(
            onPressed: () => widget.onAudioOnlyChanged!(!widget.audioOnly),
            leadingIcon: widget.audioOnly
                ? const Icon(Icons.check, size: 18)
                : const SizedBox(width: 18),
            child: Text(l10n.audioOnly),
          ),
        MenuItemButton(
          onPressed: () => session.shuffle = !session.shuffle,
          leadingIcon: session.shuffle
              ? const Icon(Icons.check, size: 18)
              : const SizedBox(width: 18),
          child: Text(l10n.shuffle),
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

  void _seekPercent(double fraction) =>
      widget.player.seek(widget.player.duration * fraction);

  void _cycleCaption() {
    final onCaption = widget.onCaptionSelected;
    if (onCaption == null || widget.captions.isEmpty) return;
    final idx = widget.captions.indexWhere((t) => t == widget.selectedCaption);
    onCaption(
      idx + 1 >= widget.captions.length ? null : widget.captions[idx + 1],
    );
  }

  void _showShortcutsHelp() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.keyboardShortcuts),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (keys, label) in [
              ('Space / K', l10n.shortcutPlayPause),
              ('J / L', l10n.shortcutSeek),
              ('← / →', l10n.shortcutSeek),
              ('↑ / ↓', l10n.shortcutVolume),
              ('M', l10n.shortcutMute),
              ('F', l10n.shortcutFullscreen),
              ('N / P', l10n.shortcutNextPrev),
              ('0–9', l10n.shortcutPercent),
              ('Home / End', l10n.shortcutStartEnd),
              ('C', l10n.shortcutCaptions),
              ('I', l10n.shortcutPip),
              (', / .', l10n.shortcutSpeed),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        keys,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    Expanded(child: Text(label)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _togglePlayback() {
    _showControls();
    _player.playing ? _player.pause() : _player.play();
  }

  void _onTapUp(TapUpDetails details) {
    if (details.kind == PointerDeviceKind.mouse) {
      _togglePlayback();
      return;
    }
    final width = context.size?.width ?? 0;
    final side = details.localPosition.dx < width / 2 ? -1 : 1;
    if (_tapTimer?.isActive == true && side == _lastTapSide) {
      _tapTimer!.cancel();
      _tapTimer = Timer(
        const Duration(milliseconds: 300),
        () => _tapTimer = null,
      );
      _skipBy(Duration(seconds: 10 * side));
      _flashSeek(side);
      return;
    }
    _lastTapSide = side;
    _tapTimer?.cancel();
    _tapTimer = Timer(
      const Duration(milliseconds: 300),
      () => _tapTimer = null,
    );
    _toggleControls();
  }

  void _flashSeek(int side) {
    _seekFlashTimer?.cancel();
    setState(() => _seekFlashSide = side);
    _seekFlashTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _seekFlashSide = 0);
    });
  }

  void _onHoldStart(LongPressStartDetails details) {
    _heldRate = _player.rate;
    setState(() => _holding = true);
    _player.setRate(2.0);
  }

  void _onHoldEnd() {
    if (!_holding) return;
    setState(() => _holding = false);
    _player.setRate(_heldRate);
  }

  void _onVerticalDragStart(DragStartDetails details) {
    final width = context.size?.width ?? 0;
    final x = details.localPosition.dx;
    _dragDy = 0;
    _dragSide = x < width / 3 ? -1 : (x > width * 2 / 3 ? 1 : 0);
    if (_dragSide == 1) {
      _dragBase = _player.volume;
    } else if (_dragSide == -1) {
      _dragBase = null;
      final brightness = AppScope.read(context).brightness;
      if (brightness != null) {
        brightness.getBrightness().then((v) => _dragBase = v);
      }
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_dragSide == 0) {
      _dragDy += details.delta.dy;
      return;
    }
    final base = _dragBase;
    if (base == null) return;
    _dragDy += details.delta.dy;
    final height = context.size?.height ?? 300;
    final value = (base - _dragDy / (height * 0.7)).clamp(0.0, 1.0);
    if (_dragSide == 1) {
      _player.setVolume(value);
      setState(() {
        _hudValue = value;
        _hudVolume = true;
      });
    } else {
      AppScope.read(context).brightness?.setBrightness(value);
      setState(() {
        _hudValue = value;
        _hudVolume = false;
      });
    }
  }

  void _onVerticalDragEnd() {
    if (_dragSide == 0 && _dragDy > 60) _dismiss();
    _dragDy = 0;
    _dragBase = null;
    if (_hudValue != null) setState(() => _hudValue = null);
  }

  void _dismiss() {
    if (widget.isFullscreen) {
      widget.onToggleFullscreen();
    } else {
      widget.onDismiss?.call();
    }
  }

  void _toggleMute() {
    _showControls();
    _player.setMuted(!_player.muted);
  }

  void _changeVolume(double value) {
    _player.setMuted(false);
    _player.setVolume(value.clamp(0.0, 1.0));
  }

  Widget _volumeControls(bool wide, AppLocalizations l10n) {
    return StreamBuilder<bool>(
      stream: _player.mutedStream,
      initialData: _player.muted,
      builder: (context, mutedSnap) {
        final muted = mutedSnap.data ?? _player.muted;
        return StreamBuilder<double>(
          stream: _player.volumeStream,
          initialData: _player.volume,
          builder: (context, volumeSnap) {
            final volume = volumeSnap.data ?? _player.volume;
            final icon = muted || volume <= 0
                ? Icons.volume_off
                : volume < 0.5
                ? Icons.volume_down
                : Icons.volume_up;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(icon),
                  color: Colors.white,
                  visualDensity: VisualDensity.compact,
                  tooltip: wide
                      ? (muted ? l10n.unmute : l10n.mute)
                      : l10n.volume,
                  onPressed: wide
                      ? _toggleMute
                      : () => setState(() => _volumePopup = !_volumePopup),
                ),
                if (wide)
                  SizedBox(
                    width: 80,
                    child: Slider(
                      key: const ValueKey('volumeSlider'),
                      value: muted ? 0.0 : volume.clamp(0.0, 1.0),
                      onChanged: _changeVolume,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statsOverlay() {
    final l10n = AppLocalizations.of(context);
    String line(PlayableStream? s, String label) {
      if (s == null) return '';
      final parts = [
        label,
        s.quality,
        if (s.width != null && s.height != null) '${s.width}x${s.height}',
        ?s.container,
        ?s.mimeType,
        if (s.bitrate != null) '${s.bitrate! ~/ 1000}kbps',
      ];
      return parts.join(' · ');
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: StreamBuilder<Duration>(
          stream: _player.positionStream,
          initialData: _player.position,
          builder: (context, posSnap) => StreamBuilder<Duration>(
            stream: _player.bufferedStream,
            initialData: _player.buffered,
            builder: (context, bufSnap) {
              final pos = posSnap.data ?? Duration.zero;
              final buf = bufSnap.data ?? Duration.zero;
              final text = [
                line(widget.current, l10n.statsVideo),
                line(widget.currentAudio, l10n.statsAudio),
                '${l10n.statsPosition}: ${formatDuration(pos)} / ${formatDuration(_player.duration)} (${formatDuration(buf)} ${l10n.statsBuffered})',
                '${l10n.statsRate}: ${_player.rate}x · ${l10n.statsVolume}: ${(_player.volume * 100).round()}%',
              ].where((l) => l.isNotEmpty).join('\n');
              return Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _setRate(double rate) {
    _player.setRate(rate);
    AppScope.read(context).playback.lastRate = rate;
  }

  void _adjustVolume(double delta) {
    _showControls();
    _player.setVolume((_player.volume + delta).clamp(0.0, 1.0));
  }

  void _stepRate(int direction) {
    _showControls();
    var index = _rates.indexWhere((r) => r >= _player.rate - 0.001);
    if (index < 0) index = _rates.length - 1;
    _setRate(_rates[(index + direction).clamp(0, _rates.length - 1)]);
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
    final wide = MediaQuery.sizeOf(context).width >= 600;
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
        const SingleActivator(LogicalKeyboardKey.keyN): () =>
            widget.onNext?.call(),
        const SingleActivator(LogicalKeyboardKey.keyN, shift: true): () =>
            widget.onNext?.call(),
        const SingleActivator(LogicalKeyboardKey.keyP): () =>
            widget.onPrevious?.call(),
        const SingleActivator(LogicalKeyboardKey.keyP, shift: true): () =>
            widget.onPrevious?.call(),
        const SingleActivator(LogicalKeyboardKey.home): () =>
            widget.player.seek(Duration.zero),
        const SingleActivator(LogicalKeyboardKey.end): () =>
            widget.player.seek(widget.player.duration),
        const SingleActivator(LogicalKeyboardKey.keyI): () =>
            widget.onPip?.call(),
        const SingleActivator(LogicalKeyboardKey.keyC): _cycleCaption,
        const SingleActivator(LogicalKeyboardKey.escape): () {},
        const SingleActivator(LogicalKeyboardKey.slash, shift: true):
            _showShortcutsHelp,
        for (var i = 0; i <= 9; i++)
          SingleActivator(LogicalKeyboardKey(0x00000030 + i)): () =>
              _seekPercent(i / 10),
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
                Center(
                  child: widget.audioOnly && widget.artworkUrl != null
                      ? Image.network(
                          widget.artworkUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.music_note, size: 64),
                        )
                      : _player.buildView(context),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: _onTapUp,
                    onLongPressStart: _onHoldStart,
                    onLongPressEnd: (_) => _onHoldEnd(),
                    onLongPressCancel: _onHoldEnd,
                    onVerticalDragStart: _onVerticalDragStart,
                    onVerticalDragUpdate: _onVerticalDragUpdate,
                    onVerticalDragEnd: (_) => _onVerticalDragEnd(),
                    onVerticalDragCancel: _onVerticalDragEnd,
                  ),
                ),
                if (_seekFlashSide != 0)
                  Positioned(
                    left: _seekFlashSide < 0 ? 32 : null,
                    right: _seekFlashSide > 0 ? 32 : null,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _seekFlashSide < 0
                                    ? Icons.fast_rewind
                                    : Icons.fast_forward,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '10s',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_hudValue != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _hudVolume
                                    ? Icons.volume_up
                                    : Icons.brightness_6,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${(_hudValue! * 100).round()}%',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_holding)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: Colors.black54,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            '2x',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_volumePopup && !wide)
                  Positioned(
                    right: 8,
                    bottom: 56,
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [_volumeControls(true, l10n)],
                      ),
                    ),
                  ),
                if (widget.segmentSkipper != null)
                  Positioned(
                    right: 8,
                    bottom: 56,
                    child: ListenableBuilder(
                      listenable: widget.segmentSkipper!,
                      builder: (context, _) {
                        final skipper = widget.segmentSkipper!;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (skipper.highlight != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                  ),
                                  onPressed: skipper.jumpToHighlight,
                                  icon: const Icon(Icons.star, size: 18),
                                  label: Text(l10n.jumpToHighlight),
                                ),
                              ),
                            if (skipper.active != null)
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                ),
                                onPressed: skipper.skip,
                                icon: const Icon(Icons.skip_next, size: 18),
                                label: Text(l10n.skipSegment),
                              ),
                          ],
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
                  left: 16,
                  right: 16,
                  bottom: 52,
                  child: IgnorePointer(
                    child: StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      initialData: _player.position,
                      builder: (context, snapshot) {
                        final cue = captionCueAt(
                          _cues,
                          snapshot.data ?? Duration.zero,
                        );
                        if (cue == null) return const SizedBox.shrink();
                        return Center(
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Text(
                              cue.text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
                              _volumeControls(wide, l10n),
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
                                        child: widget.live
                                            ? const Row(
                                                children: [
                                                  LiveBadge(),
                                                  Spacer(),
                                                ],
                                              )
                                            : Row(
                                                children: [
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
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
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontSize: 10,
                                                                ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  Expanded(
                                                    child: LayoutBuilder(
                                                      builder: (context, sliderCons) {
                                                        return MouseRegion(
                                                          onHover: (e) => setState(
                                                            () => _previewFraction =
                                                                (e.localPosition.dx /
                                                                        sliderCons
                                                                            .maxWidth)
                                                                    .clamp(
                                                                      0.0,
                                                                      1.0,
                                                                    ),
                                                          ),
                                                          onExit: (_) => setState(
                                                            () =>
                                                                _previewFraction =
                                                                    null,
                                                          ),
                                                          child: Stack(
                                                            alignment: Alignment
                                                                .center,
                                                            children: [
                                                              StreamBuilder<
                                                                Duration
                                                              >(
                                                                stream: _player
                                                                    .bufferedStream,
                                                                initialData:
                                                                    _player
                                                                        .buffered,
                                                                builder: (context, bufSnap) {
                                                                  final buffered =
                                                                      bufSnap
                                                                          .data ??
                                                                      Duration
                                                                          .zero;
                                                                  return Slider(
                                                                    key:
                                                                        const ValueKey(
                                                                          'seekSlider',
                                                                        ),
                                                                    value: clamped
                                                                        .inMilliseconds
                                                                        .toDouble()
                                                                        .clamp(
                                                                          0,
                                                                          (total.inMilliseconds)
                                                                              .toDouble(),
                                                                        ),
                                                                    max: total
                                                                        .inMilliseconds
                                                                        .toDouble()
                                                                        .clamp(
                                                                          1,
                                                                          double
                                                                              .infinity,
                                                                        ),
                                                                    secondaryTrackValue:
                                                                        total >
                                                                            Duration.zero
                                                                        ? (buffered.inMilliseconds / total.inMilliseconds).clamp(
                                                                            0.0,
                                                                            1.0,
                                                                          )
                                                                        : null,
                                                                    onChanged:
                                                                        total ==
                                                                            Duration.zero
                                                                        ? null
                                                                        : (v) {
                                                                            setState(
                                                                              () => _previewFraction = (v / total.inMilliseconds).clamp(
                                                                                0.0,
                                                                                1.0,
                                                                              ),
                                                                            );
                                                                            _player.seek(
                                                                              Duration(
                                                                                milliseconds: v.round(),
                                                                              ),
                                                                            );
                                                                          },
                                                                  );
                                                                },
                                                              ),
                                                              if (total >
                                                                  Duration.zero)
                                                                Positioned.fill(
                                                                  child: IgnorePointer(
                                                                    child: LayoutBuilder(
                                                                      builder: (context, cons) => Stack(
                                                                        children: [
                                                                          for (final marker
                                                                              in widget.chapters)
                                                                            if (marker.start > Duration.zero &&
                                                                                marker.start < total)
                                                                              Positioned(
                                                                                left: 12 + (cons.maxWidth - 24) * (marker.start.inMilliseconds / total.inMilliseconds),
                                                                                top: (cons.maxHeight - 10) / 2,
                                                                                child: Container(width: 2, height: 10, color: Colors.white38),
                                                                              ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              if (total >
                                                                      Duration
                                                                          .zero &&
                                                                  widget
                                                                      .heatmap
                                                                      .isNotEmpty)
                                                                Positioned.fill(
                                                                  child: IgnorePointer(
                                                                    child: CustomPaint(
                                                                      painter: _HeatMapPainter(
                                                                        widget
                                                                            .heatmap,
                                                                        total,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              if (_previewFraction !=
                                                                      null &&
                                                                  widget.storyboard !=
                                                                      null &&
                                                                  total >
                                                                      Duration
                                                                          .zero)
                                                                Positioned(
                                                                  left: ((_previewFraction! * sliderCons.maxWidth) - widget.storyboard!.tileWidth / 2).clamp(
                                                                    0.0,
                                                                    sliderCons
                                                                            .maxWidth -
                                                                        widget
                                                                            .storyboard!
                                                                            .tileWidth,
                                                                  ),
                                                                  bottom: 24,
                                                                  child: IgnorePointer(
                                                                    child: _SeekPreview(
                                                                      board: widget
                                                                          .storyboard!,
                                                                      time: Duration(
                                                                        milliseconds:
                                                                            (_previewFraction! * total.inMilliseconds).round(),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        );
                                                      },
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
                if (_statsVisible)
                  Positioned(top: 8, left: 8, child: _statsOverlay()),
                if (_ended && widget.endScreenBuilder != null && !widget.live)
                  Positioned.fill(child: widget.endScreenBuilder!(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeekPreview extends StatelessWidget {
  final Storyboard board;
  final Duration time;

  const _SeekPreview({required this.board, required this.time});

  @override
  Widget build(BuildContext context) {
    final tile = storyboardTileAt(board, time);
    if (tile == null) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: board.tileWidth.toDouble(),
            height: board.tileHeight.toDouble(),
            child: ClipRect(
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Transform.translate(
                  offset: Offset(-tile.sourceRect.left, -tile.sourceRect.top),
                  child: Image.network(
                    tile.url,
                    fit: BoxFit.none,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined, size: 32),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              formatDuration(time),
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatMapPainter extends CustomPainter {
  final List<HeatMarker> markers;
  final Duration total;

  const _HeatMapPainter(this.markers, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    if (markers.isEmpty || total <= Duration.zero) return;
    const inset = 12.0;
    final width = (size.width - inset * 2).clamp(0.0, double.infinity);
    if (width <= 0) return;
    const maxHeight = 12.0;
    final center = size.height / 2;
    final paint = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.fill;

    final path = Path()..moveTo(inset, center + 1);
    final span = total.inMilliseconds;
    for (final marker in markers) {
      final x =
          inset + width * (marker.start.inMilliseconds / span).clamp(0.0, 1.0);
      path.lineTo(x, center + 1 - marker.intensity.clamp(0.0, 1.0) * maxHeight);
    }
    path
      ..lineTo(inset + width, center + 1)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HeatMapPainter old) =>
      old.markers != markers || old.total != total;
}
