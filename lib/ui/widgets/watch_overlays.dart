import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../services/player_controller.dart';
import '../../state/app_state.dart';
import 'thumbnail.dart';

class EndScreen extends StatelessWidget {
  final String? thumbnailUrl;
  final VoidCallback onReplay;
  final VoidCallback? onNext;

  const EndScreen({
    super.key,
    this.thumbnailUrl,
    required this.onReplay,
    this.onNext,
  });

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
              EndButton(
                icon: Icons.replay,
                label: l10n.replay,
                onPressed: onReplay,
              ),
              const SizedBox(width: 32),
              EndButton(
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

class EndButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const EndButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

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

class PipSurface extends StatelessWidget {
  final PlayerController? player;

  const PipSurface({super.key, this.player});

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

class ShareMenu extends StatelessWidget {
  final VideoInfo video;
  final PlayerController? player;

  const ShareMenu({super.key, required this.video, this.player});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = AppScope.read(context);
    final url = 'https://www.youtube.com/watch?v=${video.id}';

    void copy(String text) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.copiedToClipboard)));
    }

    return MenuAnchor(
      builder: (context, controller, child) => IconButton(
        tooltip: l10n.share,
        icon: const Icon(Icons.share),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.share),
          onPressed: () => state.share?.share(url),
          child: Text(l10n.share),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.link),
          onPressed: () => copy(url),
          child: Text(l10n.copyLink),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.schedule),
          onPressed: () =>
              copy('$url&t=${(player?.position ?? Duration.zero).inSeconds}s'),
          child: Text(l10n.copyLinkAtTime),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.open_in_new),
          onPressed: () => state.launch(Uri.parse(url)),
          child: Text(l10n.watchOnYouTube),
        ),
      ],
    );
  }
}

class AutoplayCountdown extends StatelessWidget {
  final String? thumbnailUrl;
  final String title;
  final VoidCallback onCancel;
  final VoidCallback onPlayNow;

  const AutoplayCountdown({
    super.key,
    this.thumbnailUrl,
    required this.title,
    required this.onCancel,
    required this.onPlayNow,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        VideoThumbnail(url: thumbnailUrl),
        Container(color: Colors.black54),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.upNext,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(onPressed: onCancel, child: Text(l10n.cancel)),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: onPlayNow,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(l10n.playNow),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
