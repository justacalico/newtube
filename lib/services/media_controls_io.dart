// coverage:ignore-file
import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';

import 'media_controls.dart';
import 'player_controller.dart';

class _PlaybackHandler extends BaseAudioHandler {
  PlayerController? _player;
  final _subscriptions = <StreamSubscription<Object?>>[];

  void setPlayer(PlayerController player, MediaItem item) {
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
    _player = player;
    mediaItem.add(item);
    _subscriptions.add(
      player.playingStream.listen((playing) => _publish(playing)),
    );
    _subscriptions.add(
      player.positionStream.listen((_) => _publish(player.playing)),
    );
    _publish(player.playing);
  }

  void clearPlayer() {
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
    _player = null;
  }

  void _publish(bool playing) {
    final player = _player;
    if (player == null) return;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.pause,
          MediaControl.play,
          MediaControl.stop,
        ],
        playing: playing,
        processingState: AudioProcessingState.ready,
        updatePosition: player.position,
        speed: player.rate,
      ),
    );
  }

  @override
  Future<void> play() => _player?.play() ?? Future.value();

  @override
  Future<void> pause() => _player?.pause() ?? Future.value();

  @override
  Future<void> stop() async {
    await _player?.pause();
    clearPlayer();
  }

  @override
  Future<void> seek(Duration position) => _player?.seek(position) ?? Future.value();
}

class _AudioServiceControls implements MediaControls {
  _PlaybackHandler? _handler;

  @override
  Future<void> attach(
    PlayerController player, {
    required String title,
    String? artist,
    String? artworkUri,
  }) async {
    final handler =
        _handler ??= await AudioService.init(
          builder: _PlaybackHandler.new,
          config: AudioServiceConfig(
            androidNotificationChannelId: 'gitlab.httpanimations.newtube.audio',
            androidNotificationChannelName: 'Playback',
            androidNotificationOngoing: true,
            androidStopForegroundOnPause: false,
          ),
        );
    handler.setPlayer(
      player,
      MediaItem(
        id: artworkUri ?? '',
        title: title,
        artist: artist,
        artUri: artworkUri == null ? null : Uri.parse(artworkUri),
      ),
    );
  }

  @override
  Future<void> detach() async {
    _handler?.clearPlayer();
    await _handler?.stop();
  }
}

MediaControls? createMediaControls() {
  if (Platform.isAndroid || Platform.isIOS) return _AudioServiceControls();
  return null;
}
