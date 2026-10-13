import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../services/media_controls.dart';
import '../../services/pip_actions.dart';
import '../../services/player_controller.dart';
import '../../services/sleep_timer.dart';
import '../../services/sponsor_block.dart';
import '../../state/app_state.dart';
import '../../utils/chapters.dart';
import '../../utils/debug_log.dart';
import '../../utils/format.dart';
import '../../utils/stream_picker.dart';
import '../shell/title_bar.dart';
import '../widgets/comment_tile.dart';
import '../widgets/player_view.dart';
import '../widgets/subscribe_button.dart';
import '../widgets/thumbnail.dart';
import '../widgets/video_list_tile.dart';
import 'channel_page.dart';

void openWatchPage(
  BuildContext context,
  VideoInfo video, {
  PlaylistInfo? playlist,
  int? index,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => WatchPage(video: video, playlist: playlist, index: index),
    ),
  );
}

class WatchPage extends StatefulWidget {
  final VideoInfo video;
  final PlaylistInfo? playlist;
  final int? index;

  const WatchPage({super.key, required this.video, this.playlist, this.index});

  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  PlayerController? _player;
  SleepTimer? _sleepTimer;
  SegmentSkipper? _skipper;
  VideoDetails? _details;
  ChannelInfo? _channel;
  List<VideoInfo> _related = const [];
  PlayableStream? _currentStream;
  PlayableStream? _currentAudio;
  List<VideoChapter> _chapters = const [];
  List<CommentInfo> _comments = const [];
  String? _commentsToken;
  bool _loadingMoreComments = false;
  Object? _error;
  bool _fullscreen = false;
  bool _recorded = false;
  int _switches = 0;
  StreamSubscription<bool>? _completedSub;
  PipActions? _pipActions;
  MediaControls? _mediaControls;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.read(context);
    _pipActions = state.pipActions;
    _mediaControls = state.mediaControls;
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
      state.api
          .comments(widget.video.id)
          .then((result) {
            if (!mounted) return;
            setState(() {
              _comments = result.comments;
              _commentsToken = result.continuation;
            });
          })
          .catchError((e) {
            debugLog('[watch] ${widget.video.id}: comments failed: $e');
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
        try {
          await player.open(choice.stream.url, audioUrl: choice.audioUrl);
          if (!state.settings.autoplay) {
            await player.pause();
          }
        } catch (e) {
          await player.dispose();
          rethrow;
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
        _sleepTimer = SleepTimer(player);
        _chapters = parseChapters(details.description);
        _currentStream = current;
        _currentAudio = currentAudio;
      });
      _mediaControls
          ?.attach(
            player,
            title: details.info.title,
            artist: details.info.author,
            artworkUri: details.info.thumbnailUrl,
          )
          .catchError((Object e) {
            debugLog('[watch] ${widget.video.id}: media controls failed: $e');
          });
      _loadSegments(player);
      _completedSub = player.completedStream.listen((done) {
        if (done) _advancePlaylist();
      });
    } catch (e) {
      debugLog('[watch] ${widget.video.id}: load failed: $e');
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  void _advancePlaylist() {
    final playlist = widget.playlist;
    final index = widget.index;
    if (!mounted || playlist == null || index == null) return;
    final next = index + 1;
    if (next >= playlist.videos.length) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => WatchPage(
          video: playlist.videos[next],
          playlist: playlist,
          index: next,
        ),
      ),
    );
  }

  void _openPlaylistVideo(int index) {
    final playlist = widget.playlist;
    if (playlist == null || index == widget.index) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => WatchPage(
          video: playlist.videos[index],
          playlist: playlist,
          index: index,
        ),
      ),
    );
  }

  Future<void> _loadSegments(PlayerController player) async {
    final state = AppScope.read(context);
    final client = state.sponsorBlock;
    if (client == null || !state.settings.sponsorBlockEnabled) return;
    try {
      final segments = await client.segments(
        widget.video.id,
        state.settings.sponsorBlockCategories,
      );
      if (!mounted || _player != player || segments.isEmpty) return;
      setState(
        () => _skipper = SegmentSkipper(
          player: player,
          segments: segments,
          autoSkip: state.settings.sponsorBlockAutoSkip,
        ),
      );
    } catch (e) {
      debugLog('[watch] ${widget.video.id}: sponsorblock failed: $e');
    }
  }

  Future<void> _loadMoreComments() async {
    final token = _commentsToken;
    if (token == null || _loadingMoreComments) return;
    setState(() => _loadingMoreComments = true);
    try {
      final result = await AppScope.read(context).api
          .comments(widget.video.id, continuation: token);
      if (!mounted) return;
      setState(() {
        _comments = [..._comments, ...result.comments];
        _commentsToken = result.continuation;
        _loadingMoreComments = false;
      });
    } catch (e) {
      debugLog('[watch] ${widget.video.id}: comments paging failed: $e');
      if (mounted) setState(() => _loadingMoreComments = false);
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
    final rate = player.rate;
    try {
      await player.open(url, audioUrl: audioUrl);
      if (!mounted || generation != _switches) return;
      if (player.rate != rate) await player.setRate(rate);
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
              sleepTimer: _sleepTimer,
              chapters: _chapters,
              segmentSkipper: _skipper,
              pipActions: _pipActions,
            ),
          ),
        )
        .whenComplete(() {
          if (mounted) setState(() => _fullscreen = false);
        });
  }

  @override
  void dispose() {
    _completedSub?.cancel();
    _skipper?.dispose();
    _sleepTimer?.dispose();
    final player = _player;
    if (player != null) {
      player.dispose();
      _mediaControls?.detach(player);
    }
    _pipActions?.exitPip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = AppScope.read(context);
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
                          sleepTimer: _sleepTimer,
                          chapters: _chapters,
                          segmentSkipper: _skipper,
                          pipActions: _pipActions,
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
                            ListenableBuilder(
                              listenable: state.watchLater,
                              builder: (context, _) {
                                final saved = state.watchLater.contains(
                                  widget.video.id,
                                );
                                return IconButton(
                                  tooltip: saved
                                      ? l10n.watchLaterRemove
                                      : l10n.watchLaterAdd,
                                  icon: Icon(
                                    saved
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                  ),
                                  onPressed: () => state.watchLater.toggle(
                                    widget.video,
                                    state.prefs,
                                  ),
                                );
                              },
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
                        if (widget.playlist != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            l10n.playlistProgress(
                              widget.playlist!.title,
                              widget.index! + 1,
                              widget.playlist!.videos.length,
                            ),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          for (
                            var i = 0;
                            i < widget.playlist!.videos.length;
                            i++
                          )
                            VideoListTile(
                              video: widget.playlist!.videos[i],
                              contentPadding: EdgeInsets.zero,
                              selected: i == widget.index,
                              onTap: () => _openPlaylistVideo(i),
                            ),
                        ],
                        if (_comments.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            l10n.comments,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          for (final comment in _comments)
                            CommentTile(comment: comment),
                          if (_commentsToken != null)
                            Center(
                              child: _loadingMoreComments
                                  ? const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: _loadMoreComments,
                                      child: Text(l10n.loadMoreComments),
                                    ),
                            ),
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
  final SleepTimer? sleepTimer;
  final List<VideoChapter> chapters;
  final SegmentSkipper? segmentSkipper;
  final PipActions? pipActions;

  const _FullscreenPlayer({
    required this.player,
    required this.streams,
    required this.current,
    required this.currentAudio,
    required this.onQualitySelected,
    required this.onAudioSelected,
    this.sleepTimer,
    this.chapters = const [],
    this.segmentSkipper,
    this.pipActions,
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
          sleepTimer: widget.sleepTimer,
          chapters: widget.chapters,
          segmentSkipper: widget.segmentSkipper,
          pipActions: widget.pipActions,
        ),
      ),
    );
  }
}
