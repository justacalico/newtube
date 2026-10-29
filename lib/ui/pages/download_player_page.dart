import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../state/downloads_store.dart';
import '../../services/player_controller.dart';
import '../widgets/player_view.dart';

class DownloadPlayerPage extends StatefulWidget {
  final DownloadEntry entry;

  const DownloadPlayerPage({super.key, required this.entry});

  @override
  State<DownloadPlayerPage> createState() => _DownloadPlayerPageState();
}

class _DownloadPlayerPageState extends State<DownloadPlayerPage> {
  late final PlayerController _player;

  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    final player = state.createPlayer();
    _player = player;
    player.open(Uri.file(widget.entry.path).toString()).then((_) {
      player.play();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: PlayerView(
              player: _player,
              streams: const [],
              current: null,
              onQualitySelected: (_) {},
              onAudioSelected: (_) {},
              onToggleFullscreen: () => Navigator.of(context).pop(),
              isFullscreen: true,
              title: widget.entry.video.title,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.entry.video.title)),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: PlayerView(
              player: _player,
              streams: const [],
              current: null,
              onQualitySelected: (_) {},
              onAudioSelected: (_) {},
              onToggleFullscreen: _openFullscreen,
              title: widget.entry.video.title,
            ),
          ),
        ],
      ),
    );
  }
}
