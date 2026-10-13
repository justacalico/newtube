import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../services/player_controller.dart';
import '../../state/app_state.dart';
import '../../utils/debug_log.dart';
import '../../utils/format.dart';
import '../../utils/stream_picker.dart';
import '../shell/title_bar.dart';
import '../widgets/player_view.dart';
import '../widgets/subscribe_button.dart';
import '../widgets/thumbnail.dart';
import '../widgets/video_list_tile.dart';
import 'channel_page.dart';

void openWatchPage(BuildContext context, VideoInfo video) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => WatchPage(video: video)));
}

class WatchPage extends StatefulWidget {
  final VideoInfo video;

  const WatchPage({super.key, required this.video});

  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  PlayerController? _player;
  VideoDetails? _details;
  ChannelInfo? _channel;
  List<VideoInfo> _related = const [];
  PlayableStream? _currentStream;
  PlayableStream? _currentAudio;
  Object? _error;
  bool _fullscreen = false;
  bool _recorded = false;
  int _switches = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    debugLog('[watch] loading ${widget.video.id}');
    try {
      final state = AppScope.read(context);
      if (!_recorded) {
        _recorded = true;
        state.history.record(widget.video, state.prefs);
      }
      final details = await state.api.videoDetails(widget.video.id);
      debugLog('[watch] ${widget.video.id}: ${details.streams.length} streams');
      state.api
          .channel(details.info.channelId)
          .then((channel) {
            if (mounted) setState(() => _channel = channel);
          })
          .catchError((e) {
            debugLog('[watch] ${widget.video.id}: channel failed: $e');
          });
      state.api
          .relatedVideos(widget.video.id)
          .then((related) {
            if (mounted) setState(() => _related = related);
          })
          .catchError((e) {
            debugLog('[watch] ${widget.video.id}: related videos failed: $e');
          });
      if (!mounted) return;

      final player = state.createPlayer();
      final choice = pickDefaultStream(
        details.streams,
        desktop: isDesktopPlatform,
      );
      PlayableStream? current;
      PlayableStream? currentAudio;
      if (choice != null) {
        current = choice.stream;
        currentAudio = choice.audio;
        debugLog(
          '[watch] ${widget.video.id}: opening ${choice.stream.quality}'
          '${choice.audioUrl == null ? '' : ' + separate audio'}',
        );
        await player.open(choice.stream.url, audioUrl: choice.audioUrl);
        if (!state.settings.autoplay) {
          await player.pause();
        }
      } else {
        debugLog('[watch] ${widget.video.id}: no playable streams');
      }
      if (!mounted) {
        await player.dispose();
        return;
      }
      setState(() {
        _details = details;
        _player = player;
        _currentStream = current;
        _currentAudio = currentAudio;
      });
    } catch (e) {
      debugLog('[watch] ${widget.video.id}: load failed: $e');
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  void _selectStream(PlayableStream stream) {
    final choice = pairWithAudio(
      stream,
      _details?.streams ?? const [],
      audio: _currentAudio,
    );
    debugLog(
      '[watch] ${widget.video.id}: switching to ${stream.quality}'
      '${choice.audioUrl == null ? '' : ' + separate audio'}',
    );
    setState(() {
      _currentStream = stream;
      _currentAudio = choice.audio;
    });
    _switchTo(choice.stream.url, audioUrl: choice.audioUrl);
  }

  void _selectAudio(PlayableStream audio) {
    final current = _currentStream;
    if (current == null) return;
    if (!current.hasVideo) {
      debugLog('[watch] ${widget.video.id}: switching to ${audio.quality}');
      setState(() => _currentStream = audio);
      _switchTo(audio.url);
      return;
    }
    var video = current;
    if (video.hasAudio) {
      video = (_details?.streams ?? const []).firstWhere(
        (s) =>
            s.hasVideo && !s.hasAudio && streamPixels(s) == streamPixels(video),
        orElse: () => video,
      );
      if (video.hasAudio) return;
    }
    debugLog('[watch] ${widget.video.id}: switching audio to ${audio.quality}');
    setState(() {
      _currentStream = video;
      _currentAudio = audio;
    });
    _switchTo(video.url, audioUrl: audio.url);
  }

  Future<void> _switchTo(String url, {String? audioUrl}) async {
    final player = _player;
    if (player == null) return;
    final generation = ++_switches;
    final position = player.position;
    final wasPlaying = player.playing;
    try {
      await player.open(url, audioUrl: audioUrl);
      if (!mounted || generation != _switches) return;
      if (!wasPlaying) await player.pause();
      await player.seek(position);
    } catch (e) {
      debugLog('[watch] ${widget.video.id}: stream switch failed: $e');
    }
  }

  void _openFullscreen(PlayerController player) {
    setState(() => _fullscreen = true);
    Navigator.of(context, rootNavigator: true)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => _FullscreenPlayer(
              player: player,
              streams: _details?.streams ?? const [],
              current: _currentStream,
              currentAudio: _currentAudio,
              onQualitySelected: _selectStream,
              onAudioSelected: _selectAudio,
            ),
          ),
        )
        .whenComplete(() {
          if (mounted) setState(() => _fullscreen = false);
        });
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final player = _player;

    return Scaffold(
      appBar: AppBar(title: Text(widget.video.title)),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.errorLoading),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: _load, child: Text(l10n.retry)),
                ],
              ),
            )
          : player == null || _details == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _fullscreen
                      ? const ColoredBox(color: Colors.black)
                      : PlayerView(
                          player: player,
                          streams: _details!.streams,
                          current: _currentStream,
                          currentAudio: _currentAudio,
                          onQualitySelected: _selectStream,
                          onAudioSelected: _selectAudio,
                          onToggleFullscreen: () => _openFullscreen(player),
                        ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.video.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => openChannelPage(
                                  context,
                                  _details!.info.channelId,
                                ),
                                child: Row(
                                  children: [
                                    VideoThumbnail(
                                      url: _channel?.thumbnailUrl,
                                      width: 40,
                                      height: 40,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _details!.info.author,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          Text(
                                            '${formatViewCount(_details!.info.viewCount)} ${l10n.views}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SubscribeButton(
                              channel:
                                  _channel ??
                                  ChannelInfo(
                                    id: _details!.info.channelId,
                                    name: _details!.info.author,
                                  ),
                            ),
                          ],
                        ),
                        if (_details!.description.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            l10n.description,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(_details!.description),
                        ],
                        if (_related.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            l10n.relatedVideos,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          for (final v in _related)
                            VideoListTile(
                              video: v,
                              contentPadding: EdgeInsets.zero,
                              onTap: () => Navigator.of(context)
                                  .pushReplacement(
                                    MaterialPageRoute<void>(
                                      builder: (_) => WatchPage(video: v),
                                    ),
                                  ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FullscreenPlayer extends StatefulWidget {
  final PlayerController player;
  final List<PlayableStream> streams;
  final PlayableStream? current;
  final PlayableStream? currentAudio;
  final ValueChanged<PlayableStream> onQualitySelected;
  final ValueChanged<PlayableStream> onAudioSelected;

  const _FullscreenPlayer({
    required this.player,
    required this.streams,
    required this.current,
    required this.currentAudio,
    required this.onQualitySelected,
    required this.onAudioSelected,
  });

  @override
  State<_FullscreenPlayer> createState() => _FullscreenPlayerState();
}

class _FullscreenPlayerState extends State<_FullscreenPlayer> {
  late PlayableStream? _current = widget.current;
  late PlayableStream? _currentAudio = widget.currentAudio;

  void _selectStream(PlayableStream stream) {
    widget.onQualitySelected(stream);
    setState(() => _current = stream);
  }

  void _selectAudio(PlayableStream audio) {
    widget.onAudioSelected(audio);
    setState(() {
      _currentAudio = audio;
      if (_current?.hasVideo == false) _current = audio;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PlayerView(
          player: widget.player,
          streams: widget.streams,
          current: _current,
          currentAudio: _currentAudio,
          onQualitySelected: _selectStream,
          onAudioSelected: _selectAudio,
          onToggleFullscreen: () => Navigator.of(context).pop(),
          isFullscreen: true,
        ),
      ),
    );
  }
}
