import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import 'playlist_dialogs.dart';

typedef _VideoAction = ({IconData icon, String label, VoidCallback onTap});

List<_VideoAction> _actionsFor(
  BuildContext context,
  AppState state,
  AppLocalizations l10n,
  VideoInfo video, {
  required bool saved,
  required bool watched,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final url = 'https://www.youtube.com/watch?v=${video.id}';
  return [
    (
      icon: saved ? Icons.bookmark : Icons.bookmark_border,
      label: saved ? l10n.watchLaterRemove : l10n.watchLaterAdd,
      onTap: () => state.watchLater.toggle(video, state.prefs),
    ),
    (
      icon: Icons.playlist_play,
      label: l10n.playNext,
      onTap: () {
        state.playback.playNext(video);
        messenger.showSnackBar(SnackBar(content: Text(l10n.queuedNext)));
      },
    ),
    (
      icon: Icons.queue,
      label: l10n.addToQueue,
      onTap: () {
        state.playback.enqueue(video);
        messenger.showSnackBar(SnackBar(content: Text(l10n.queued)));
      },
    ),
    (
      icon: Icons.playlist_add,
      label: l10n.addToPlaylist,
      onTap: () => showPlaylistPicker(context, video),
    ),
    (
      icon: watched ? Icons.visibility_off : Icons.visibility,
      label: watched ? l10n.markUnwatched : l10n.markWatched,
      onTap: () => watched
          ? state.history.remove(video.id, state.prefs)
          : state.history.record(video, state.prefs),
    ),
    (
      icon: Icons.visibility_off_outlined,
      label: l10n.notInterested,
      onTap: () => state.hidden.hideVideo(video.id, state.prefs),
    ),
    (
      icon: Icons.person_off_outlined,
      label: l10n.dontRecommendChannel,
      onTap: () => state.hidden.hideChannel(video.channelId, state.prefs),
    ),
    if (state.share != null)
      (
        icon: Icons.share,
        label: l10n.share,
        onTap: () => state.share!.share(url),
      ),
    (
      icon: Icons.link,
      label: l10n.copyLink,
      onTap: () {
        Clipboard.setData(ClipboardData(text: url));
        messenger.showSnackBar(SnackBar(content: Text(l10n.copiedToClipboard)));
      },
    ),
    (
      icon: Icons.open_in_new,
      label: l10n.watchOnYouTube,
      onTap: () => state.launch(Uri.parse(url)),
    ),
  ];
}

class VideoActionsMenu extends StatelessWidget {
  final VideoInfo video;

  const VideoActionsMenu({super.key, required this.video});

  static void open(BuildContext context, VideoInfo video) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _VideoActionsSheet(video: video, parentContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = AppScope.read(context);
    return ListenableBuilder(
      listenable: Listenable.merge([state.watchLater, state.history]),
      builder: (context, _) {
        final actions = _actionsFor(
          context,
          state,
          l10n,
          video,
          saved: state.watchLater.contains(video.id),
          watched: state.history.contains(video.id),
        );
        return MenuAnchor(
          builder: (context, controller, child) => IconButton(
            tooltip: l10n.videoActions,
            icon: const Icon(Icons.more_vert, size: 20),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(36, 32),
            ),
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
          menuChildren: [
            for (final action in actions)
              MenuItemButton(
                leadingIcon: Icon(action.icon),
                onPressed: action.onTap,
                child: Text(action.label),
              ),
          ],
        );
      },
    );
  }
}

class _VideoActionsSheet extends StatelessWidget {
  final VideoInfo video;
  final BuildContext parentContext;

  const _VideoActionsSheet({required this.video, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = AppScope.read(context);
    void close() => Navigator.of(context).pop();
    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([state.watchLater, state.history]),
        builder: (context, _) {
          final actions = _actionsFor(
            parentContext,
            state,
            l10n,
            video,
            saved: state.watchLater.contains(video.id),
            watched: state.history.contains(video.id),
          );
          return ListView(
            shrinkWrap: true,
            children: [
              for (final action in actions)
                ListTile(
                  leading: Icon(action.icon),
                  title: Text(action.label),
                  onTap: () {
                    close();
                    action.onTap();
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
