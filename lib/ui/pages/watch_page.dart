import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../services/player_controller.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../utils/stream_picker.dart';
import '../shell/title_bar.dart';
import '../widgets/player_view.dart';
import '../widgets/subscribe_button.dart';
import 'channel_page.dart';

class WatchPage extends StatefulWidget {
  final VideoInfo video;

  const WatchPage({super.key, required this.video});

  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  PlayerController? _player;
  VideoDetails? _details;
  List<VideoInfo> _related = const [];
  PlayableStream? _currentStream;
  Object? _error;
  bool _fullscreen = false;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final state = AppScope.read(context);
      if (!_recorded) {
        _recorded = true;
        state.history.record(widget.video, state.prefs);
      }
      final details = await state.api.videoDetails(widget.video.id);
      state.api
          .relatedVideos(widget.video.id)
          .then((related) {
            if (mounted) setState(() => _related = related);
          })
          .catchError((_) {});
      if (!mounted) return;

      final player = state.createPlayer();
      final choice = pickDefaultStream(
        details.streams,
        desktop: isDesktopPlatform,
      );
      PlayableStream? current;
      if (choice != null) {
        current = choice.stream;
        await player.open(choice.stream.url, audioUrl: choice.audioUrl);
        if (!state.settings.autoplay) {
          await player.pause();
        }
      }
      if (!mounted) {
        await player.dispose();
        return;
      }
      setState(() {
        _details = details;
        _player = player;
        _currentStream = current;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  void _selectStream(PlayableStream stream) {
    final choice = pairWithAudio(stream, _details?.streams ?? const []);
    setState(() => _currentStream = stream);
    _player?.open(choice.stream.url, audioUrl: choice.audioUrl);
  }

  void _toggleFullscreen() => setState(() => _fullscreen = !_fullscreen);

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final player = _player;

    if (_fullscreen && player != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _toggleFullscreen();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: PlayerView(
              player: player,
              streams: _details?.streams ?? const [],
              current: _currentStream,
              onQualitySelected: _selectStream,
              onToggleFullscreen: _toggleFullscreen,
              isFullscreen: true,
            ),
          ),
        ),
      );
    }

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
                  child: PlayerView(
                    player: player,
                    streams: _details!.streams,
                    current: _currentStream,
                    onQualitySelected: _selectStream,
                    onToggleFullscreen: _toggleFullscreen,
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ChannelPage(
                                          channelId: _details!.info.channelId,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _details!.info.author,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
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
                            SubscribeButton(
                              channel: ChannelInfo(
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
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                v.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(v.author),
                              trailing: v.duration == null
                                  ? null
                                  : Text(formatDuration(v.duration)),
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
