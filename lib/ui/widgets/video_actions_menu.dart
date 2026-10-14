import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      listenable: Listenable.merge([
        state.watchLater,
        state.history,
        state.hidden,
      ]),
      builder: (context, _) {
        final saved = state.watchLater.contains(video.id);
        final watched = state.history.contains(video.id);
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
              leadingIcon: const Icon(Icons.playlist_play),
              onPressed: () {
                state.playback.playNext(video);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.queuedNext)));
              },
              child: Text(l10n.playNext),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.queue),
              onPressed: () {
                state.playback.enqueue(video);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.queued)));
              },
              child: Text(l10n.addToQueue),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.playlist_add),
              onPressed: () => showPlaylistPicker(context, video),
              child: Text(l10n.addToPlaylist),
            ),
            MenuItemButton(
              leadingIcon: Icon(
                watched ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => watched
                  ? state.history.remove(video.id, state.prefs)
                  : state.history.record(video, state.prefs),
              child: Text(watched ? l10n.markUnwatched : l10n.markWatched),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.visibility_off_outlined),
              onPressed: () => state.hidden.hideVideo(video.id, state.prefs),
              child: Text(l10n.notInterested),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.person_off_outlined),
              onPressed: () =>
                  state.hidden.hideChannel(video.channelId, state.prefs),
              child: Text(l10n.dontRecommendChannel),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.share),
              onPressed: () => state.share?.share(
                'https://www.youtube.com/watch?v=${video.id}',
              ),
              child: Text(l10n.share),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.link),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(
                    text: 'https://www.youtube.com/watch?v=${video.id}',
                  ),
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.copiedToClipboard)));
              },
              child: Text(l10n.copyLink),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.open_in_new),
              onPressed: () => state.launch(
                Uri.parse('https://www.youtube.com/watch?v=${video.id}'),
              ),
              child: Text(l10n.watchOnYouTube),
            ),
          ],
        );
      },
    );
  }
}
