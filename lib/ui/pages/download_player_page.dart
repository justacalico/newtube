import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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
  PlayerController? _player;

  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    final player = state.createPlayer();
    _player = player;
    player.open('file://${widget.entry.path}').then((_) => player.play());
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
      appBar: AppBar(title: Text(widget.entry.video.title)),
      body: player == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: PlayerView(
                    player: player,
                    streams: const [],
                    current: null,
                    onQualitySelected: (_) {},
                    onAudioSelected: (_) {},
                    onToggleFullscreen: () {},
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    l10n.downloads,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
    );
  }
}
