import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide RepeatMode;

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../services/media_controls.dart';
import '../../services/pip_actions.dart';
import '../../services/player_controller.dart';
import '../../services/sleep_timer.dart';
import '../../services/sponsor_block.dart';
import '../../state/app_state.dart';
import '../../state/playback_session.dart';
import '../../utils/chapters.dart';
import '../../utils/debug_log.dart';
import '../../utils/format.dart';
import '../../utils/storyboard.dart';
import '../../utils/stream_picker.dart';
import '../shell/title_bar.dart';
import '../widgets/comment_tile.dart';
import '../widgets/player_view.dart';
import '../widgets/playlist_dialogs.dart';
import '../widgets/subscribe_button.dart';
import '../widgets/thumbnail.dart';
import '../widgets/video_list_tile.dart';
import 'channel_page.dart';

final watchRouteObserver = RouteObserver<ModalRoute<void>>();

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

class _WatchPageState extends State<WatchPage>
    with WidgetsBindingObserver, RouteAware {
  late final AppState _state;
  final _random = Random();
  PlayerController? _player;
  SleepTimer? _sleepTimer;
  SegmentSkipper? _skipper;
  VideoDetails? _details;
  ChannelInfo? _channel;
  List<VideoInfo> _related = const [];
  PlayableStream? _currentStream;
  PlayableStream? _currentAudio;
  PlayableStream? _videoStream;
  bool _audioOnly = false;
  List<VideoChapter> _chapters = const [];
  CaptionTrack? _caption;
  List<CommentInfo> _comments = const [];
  String? _commentsToken;
  bool _loadingMoreComments = false;
  Object? _error;
  bool _fullscreen = false;
  bool _recorded = false;
  bool _sharedPlayer = false;
  int _switches = 0;
  StreamSubscription<bool>? _completedSub;
  PipActions? _pipActions;
  MediaControls? _mediaControls;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state = AppScope.read(context);
    _state.playback.addListener(_onSessionChanged);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final player = _player;
    if (player == null) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(player.setVideoEnabled(false));
      final pip = _pipActions;
      if (pip != null &&
          !pip.pipMode.value &&
          player.playing &&
          !isDesktopPlatform) {
        unawaited(pip.enterPip());
      }
    } else if (state == AppLifecycleState.resumed) {
      unawaited(player.setVideoEnabled(true));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.read(context);
    _pipActions = state.pipActions;
    _mediaControls = state.mediaControls;
    final route = ModalRoute.of(context);
    if (route != null) watchRouteObserver.subscribe(this, route);
  }

  void _onSessionChanged() {
    final player = _player;
    if (!mounted || player == null || !_sharedPlayer) return;
    if (identical(_state.playback.player, player)) return;
    _sharedPlayer = false;
    _completedSub?.cancel();
    _completedSub = null;
    _skipper?.dispose();
    _skipper = null;
    _sleepTimer = null;
    setState(() => _player = null);
    if (ModalRoute.of(context)?.isCurrent ?? true) _load();
  }

  @override
  void didPopNext() {
    if (_player == null && _details != null) _load();
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

      final session = state.playback;
      final shared = session.player;
      final PlayerController player;
      final PlayableStream? current;
      final PlayableStream? currentAudio;
      var adopted = false;
      if (shared != null &&
          !session.attached &&
          session.video?.id == widget.video.id) {
        adopted = true;
        player = shared;
        current = session.stream;
        currentAudio = session.audio;
        _audioOnly = session.audioOnly;
      } else {
        player = state.createPlayer();
        _audioOnly = state.settings.audioOnly;
        final choice = pickDefaultStream(
          details.streams,
          desktop: isDesktopPlatform,
          preferredQuality: state.settings.preferredQuality,
        );
        _videoStream = choice?.stream;
        final audioTrack = _audioOnly ? bestAudio(details.streams) : null;
        final open = audioTrack != null
            ? StreamChoice(audioTrack, null)
            : choice;
        PlayableStream? picked;
        PlayableStream? pickedAudio;
        if (open != null) {
          picked = open.stream;
          pickedAudio = open.audio;
          debugLog(
            '[watch] ${widget.video.id}: opening ${open.stream.quality}'
            '${open.audioUrl == null ? '' : ' + separate audio'}',
          );
          try {
            await player.open(open.stream.url, audioUrl: open.audioUrl);
            await player.setRate(
              session.lastRate ?? state.settings.defaultSpeed,
            );
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
        current = picked;
        currentAudio = pickedAudio;
      }
      setState(() {
        _details = details;
        _player = player;
        _sharedPlayer = true;
        _sleepTimer = adopted
            ? session.sleepTimer ?? SleepTimer(player)
            : SleepTimer(player);
        _chapters = parseChapters(details.description);
        _currentStream = current;
        _currentAudio = currentAudio;
        _caption = _initialCaption(details.captions);
      });
      session.attach(
        player,
        widget.video,
        playlist: widget.playlist,
        index: widget.index,
        stream: current,
        audio: currentAudio,
        sleepTimer: _sleepTimer,
      );
      _pipActions?.updatePlayback(
        player,
        url: current?.url,
        audioUrl: currentAudio?.url,
      );
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle == AppLifecycleState.paused ||
          lifecycle == AppLifecycleState.hidden) {
        unawaited(player.setVideoEnabled(false));
      }
      if (!adopted) {
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
      }
      _loadSegments(player);
      _completedSub = player.completedStream.listen((done) {
        if (!done) return;
        if (state.playback.repeatMode == RepeatMode.one) {
          _replay(player);
        } else if (state.settings.autoplay) {
          _openNext();
        }
      });
    } catch (e) {
      debugLog('[watch] ${widget.video.id}: load failed: $e');
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  CaptionTrack? _initialCaption(List<CaptionTrack> tracks) {
    if (tracks.isEmpty || !_state.settings.captionsEnabled) return null;
    final language = _state.settings.captionLanguage;
    for (final track in tracks) {
      if (track.languageCode == language) return track;
    }
    return tracks.first;
  }

  void _selectCaption(CaptionTrack? track) {
    setState(() => _caption = track);
    unawaited(_state.settings.setCaptionsEnabled(track != null, _state.prefs));
    unawaited(
      _state.settings.setCaptionLanguage(track?.languageCode, _state.prefs),
    );
  }

  int? get _nextPlaylistIndex {
    final playlist = widget.playlist;
    final index = widget.index;
    if (playlist == null || index == null) return null;
    final count = playlist.videos.length;
    if (_state.playback.shuffle && count > 1) {
      final next = _random.nextInt(count - 1);
      return next >= index ? next + 1 : next;
    }
    final next = index + 1;
    if (next < count) return next;
    return _state.playback.repeatMode == RepeatMode.all ? 0 : null;
  }

  VideoInfo? get _nextVideo {
    final i = _nextPlaylistIndex;
    if (i != null) return widget.playlist!.videos[i];
    return _related.firstOrNull;
  }

  void _replaceWith(Widget page) {
    if (_fullscreen) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openNext() {
    final next = _nextVideo;
    if (!mounted || next == null) return;
    final i = _nextPlaylistIndex;
    _replaceWith(
      i != null
          ? WatchPage(video: next, playlist: widget.playlist, index: i)
          : WatchPage(video: next),
    );
  }

  void _replay(PlayerController player) {
    unawaited(player.seek(Duration.zero).then((_) => player.play()));
  }

  Widget _endScreen(BuildContext context, PlayerController player) {
    return _EndScreen(
      thumbnailUrl: widget.video.thumbnailUrl,
      onReplay: () => _replay(player),
      onNext: _nextVideo == null ? null : _openNext,
    );
  }

  void _openPlaylistVideo(int index) {
    final playlist = widget.playlist;
    if (playlist == null || index == widget.index) return;
    _replaceWith(
      WatchPage(
        video: playlist.videos[index],
        playlist: playlist,
        index: index,
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

  void _setAudioOnly(bool enabled) {
    if (_player == null || _audioOnly == enabled) return;
    final streams = _details?.streams ?? const <PlayableStream>[];
    if (enabled) {
      final audio = bestAudio(streams, container: _currentStream?.container);
      if (audio == null) return;
      if (_currentStream?.hasVideo == true) _videoStream = _currentStream;
      setState(() {
        _audioOnly = true;
        _currentStream = audio;
        _currentAudio = null;
      });
      _state.playback.audioOnly = true;
      _state.playback.updateStream(audio, null);
      _switchTo(audio.url);
      return;
    }
    final video =
        _videoStream ??
        pickDefaultStream(
          streams,
          desktop: isDesktopPlatform,
          preferredQuality: _state.settings.preferredQuality,
        )?.stream;
    if (video == null) return;
    final choice = pairWithAudio(video, streams, audio: _currentAudio);
    setState(() {
      _audioOnly = false;
      _currentStream = video;
      _currentAudio = choice.audio;
    });
    _state.playback.audioOnly = false;
    _state.playback.updateStream(video, choice.audio);
    _switchTo(video.url, audioUrl: choice.audioUrl);
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
    _state.playback.updateStream(stream, choice.audio);
    _switchTo(choice.stream.url, audioUrl: choice.audioUrl);
  }

  void _selectAudio(PlayableStream audio) {
    final current = _currentStream;
    if (current == null) return;
    if (!current.hasVideo) {
      debugLog('[watch] ${widget.video.id}: switching to ${audio.quality}');
      setState(() {
        _currentStream = audio;
        _currentAudio = null;
      });
      _state.playback.updateStream(audio, null);
      _switchTo(audio.url);
      return;
    }
    var video = current;
    if (video.hasAudio) {
      final sameRes = (_details?.streams ?? const <PlayableStream>[]).where(
        (s) =>
            s.hasVideo && !s.hasAudio && streamPixels(s) == streamPixels(video),
      );
      video = sameRes.firstWhere(
        (s) => sameContainer(s, audio),
        orElse: () => sameRes.firstOrNull ?? video,
      );
      if (video.hasAudio) return;
    }
    debugLog('[watch] ${widget.video.id}: switching audio to ${audio.quality}');
    setState(() {
      _currentStream = video;
      _currentAudio = audio;
    });
    _state.playback.updateStream(video, audio);
    _switchTo(video.url, audioUrl: audio.url);
  }

  Future<void> _switchTo(String url, {String? audioUrl}) async {
    final player = _player;
    if (player == null) return;
    _pipActions?.updatePlayback(player, url: url, audioUrl: audioUrl);
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
              endScreenBuilder: (context) => _endScreen(context, player),
              captions: _details?.captions ?? const [],
              selectedCaption: _caption,
              onCaptionSelected: _selectCaption,
              audioOnly: _audioOnly,
              artworkUrl: widget.video.thumbnailUrl,
              onAudioOnlyChanged: _setAudioOnly,
              storyboard: bestStoryboard(_details?.storyboards ?? const []),
              heatmap: _details?.heatmap ?? const [],
            ),
          ),
        )
        .whenComplete(() {
          if (mounted) setState(() => _fullscreen = false);
        });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    watchRouteObserver.unsubscribe(this);
    _state.playback.removeListener(_onSessionChanged);
    _completedSub?.cancel();
    _skipper?.dispose();
    final player = _player;
    if (player != null) _state.playback.release(player);
    _pipActions?.exitPip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pip = _pipActions;
    if (pip == null) return _buildPage();
    return ListenableBuilder(
      listenable: pip.pipMode,
      builder: (context, _) =>
          pip.pipMode.value ? _PipSurface(player: _player) : _buildPage(),
    );
  }

  Widget _buildPage() {
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
          : SingleChildScrollView(
              child: Column(
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
                            endScreenBuilder: (context) =>
                                _endScreen(context, player),
                            captions: _details!.captions,
                            selectedCaption: _caption,
                            onCaptionSelected: _selectCaption,
                            audioOnly: _audioOnly,
                            artworkUrl: widget.video.thumbnailUrl,
                            onAudioOnlyChanged: _setAudioOnly,
                            onDismiss: () => Navigator.of(context).pop(),
                            storyboard: bestStoryboard(_details!.storyboards),
                          ),
                  ),
                  Padding(
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
                            IconButton(
                              tooltip: l10n.addToPlaylist,
                              icon: const Icon(Icons.playlist_add),
                              onPressed: () =>
                                  showPlaylistPicker(context, widget.video),
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
                        if (_chapters.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(
                              l10n.chapters,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            subtitle: Text(
                              chapterAt(_chapters, player.position)?.title ??
                                  '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            children: [
                              for (final chapter in _chapters)
                                ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Text(
                                    formatDuration(chapter.start),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  title: Text(
                                    chapter.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => player.seek(chapter.start),
                                ),
                            ],
                          ),
                        ],
                        if (widget.playlist != null &&
                            widget.index != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.playlistProgress(
                                    widget.playlist!.title,
                                    widget.index! + 1,
                                    widget.playlist!.videos.length,
                                  ),
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              ListenableBuilder(
                                listenable: _state.playback,
                                builder: (context, _) {
                                  final session = _state.playback;
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: switch (session.repeatMode) {
                                          RepeatMode.off => l10n.repeatOff,
                                          RepeatMode.all => l10n.repeatAll,
                                          RepeatMode.one => l10n.repeatOne,
                                        },
                                        icon: Icon(switch (session.repeatMode) {
                                          RepeatMode.off => Icons.repeat,
                                          RepeatMode.all => Icons.repeat_on,
                                          RepeatMode.one => Icons.repeat_one_on,
                                        }),
                                        onPressed: () => session.repeatMode =
                                            RepeatMode.values[(session
                                                        .repeatMode
                                                        .index +
                                                    1) %
                                                RepeatMode.values.length],
                                      ),
                                      IconButton(
                                        tooltip: l10n.shuffle,
                                        icon: Icon(
                                          session.shuffle
                                              ? Icons.shuffle_on
                                              : Icons.shuffle,
                                        ),
                                        onPressed: () =>
                                            session.shuffle = !session.shuffle,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
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
                              onTap: () => _replaceWith(WatchPage(video: v)),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
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
  final WidgetBuilder? endScreenBuilder;
  final List<CaptionTrack> captions;
  final CaptionTrack? selectedCaption;
  final ValueChanged<CaptionTrack?>? onCaptionSelected;
  final bool audioOnly;
  final String? artworkUrl;
  final ValueChanged<bool>? onAudioOnlyChanged;
  final Storyboard? storyboard;
  final List<HeatMarker> heatmap;

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
    this.endScreenBuilder,
    this.captions = const [],
    this.selectedCaption,
    this.onCaptionSelected,
    this.audioOnly = false,
    this.artworkUrl,
    this.onAudioOnlyChanged,
    this.storyboard,
    this.heatmap = const [],
  });

  @override
  State<_FullscreenPlayer> createState() => _FullscreenPlayerState();
}

class _FullscreenPlayerState extends State<_FullscreenPlayer> {
  late PlayableStream? _current = widget.current;
  late PlayableStream? _currentAudio = widget.currentAudio;
  late CaptionTrack? _caption = widget.selectedCaption;

  void _selectCaption(CaptionTrack? track) {
    widget.onCaptionSelected?.call(track);
    setState(() => _caption = track);
  }

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
    final pip = widget.pipActions;
    if (pip == null) return _buildPlayer();
    return ListenableBuilder(
      listenable: pip.pipMode,
      builder: (context, _) => pip.pipMode.value
          ? _PipSurface(player: widget.player)
          : _buildPlayer(),
    );
  }

  Widget _buildPlayer() {
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
          endScreenBuilder: widget.endScreenBuilder,
          captions: widget.captions,
          selectedCaption: _caption,
          onCaptionSelected: _selectCaption,
          audioOnly: widget.audioOnly,
          artworkUrl: widget.artworkUrl,
          onAudioOnlyChanged: widget.onAudioOnlyChanged,
          storyboard: widget.storyboard,
          heatmap: widget.heatmap,
        ),
      ),
    );
  }
}

class _EndScreen extends StatelessWidget {
  final String? thumbnailUrl;
  final VoidCallback onReplay;
  final VoidCallback? onNext;

  const _EndScreen({this.thumbnailUrl, required this.onReplay, this.onNext});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        VideoThumbnail(url: thumbnailUrl, borderRadius: BorderRadius.zero),
        const ColoredBox(color: Colors.black54),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EndButton(
                icon: Icons.replay,
                label: l10n.replay,
                onPressed: onReplay,
              ),
              const SizedBox(width: 32),
              _EndButton(
                icon: Icons.skip_next,
                label: l10n.nextVideo,
                onPressed: onNext,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EndButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _EndButton({required this.icon, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      iconSize: 40,
      color: Colors.white,
      disabledColor: Colors.white38,
      padding: const EdgeInsets.all(12),
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: onPressed == null ? Colors.white38 : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PipSurface extends StatelessWidget {
  final PlayerController? player;

  const _PipSurface({this.player});

  @override
  Widget build(BuildContext context) {
    final player = this.player;
    return Scaffold(
      backgroundColor: Colors.black,
      body: player == null
          ? const SizedBox.shrink()
          : Center(child: player.buildView(context)),
    );
  }
}
