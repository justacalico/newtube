import 'media_controls_stub.dart'
    if (dart.library.io) 'media_controls_io.dart' as impl;
import 'player_controller.dart';

abstract class MediaControls {
  Future<void> attach(
    PlayerController player, {
    required String title,
    String? artist,
    String? artworkUri,
  });
  Future<void> detach();
}

// coverage:ignore-start
MediaControls? createMediaControls() => impl.createMediaControls();
// coverage:ignore-end
