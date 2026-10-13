import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import 'playlist_dialogs.dart';

class VideoActionsMenu extends StatelessWidget {
  final VideoInfo video;

  const VideoActionsMenu({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = AppScope.read(context);
    return ListenableBuilder(
      listenable: state.watchLater,
      builder: (context, _) {
        final saved = state.watchLater.contains(video.id);
        return MenuAnchor(
          builder: (context, controller, child) => IconButton(
            tooltip: l10n.videoActions,
            icon: const Icon(Icons.more_vert),
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
          menuChildren: [
            MenuItemButton(
              leadingIcon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
              onPressed: () => state.watchLater.toggle(video, state.prefs),
              child: Text(saved ? l10n.watchLaterRemove : l10n.watchLaterAdd),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.playlist_add),
              onPressed: () => showPlaylistPicker(context, video),
              child: Text(l10n.addToPlaylist),
            ),
          ],
        );
      },
    );
  }
}
