import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';

Future<String?> promptPlaylistTitle(
  BuildContext context, {
  String? initialValue,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _PlaylistTitleDialog(initialValue: initialValue),
  );
}

class _PlaylistTitleDialog extends StatefulWidget {
  final String? initialValue;

  const _PlaylistTitleDialog({this.initialValue});

  @override
  State<_PlaylistTitleDialog> createState() => _PlaylistTitleDialogState();
}

class _PlaylistTitleDialogState extends State<_PlaylistTitleDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rename = widget.initialValue != null;
    return AlertDialog(
      title: Text(rename ? l10n.renamePlaylist : l10n.newPlaylist),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.playlistNameHint),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(rename ? l10n.rename : l10n.create),
        ),
      ],
    );
  }
}

Future<bool> confirmDeletePlaylist(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.deletePlaylist),
      content: Text(l10n.deletePlaylistConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<void> showPlaylistPicker(BuildContext context, VideoInfo video) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) {
      final state = AppScope.read(context);
      return AlertDialog(
        title: Text(l10n.addToPlaylist),
        content: SizedBox(
          width: double.maxFinite,
          child: ListenableBuilder(
            listenable: state.playlists,
            builder: (context, _) {
              return ListView(
                shrinkWrap: true,
                children: [
                  for (final playlist in state.playlists.playlists)
                    CheckboxListTile(
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(playlist.title),
                      subtitle: Text(l10n.videoCount(playlist.videos.length)),
                      value: state.playlists.containsVideo(
                        playlist.id,
                        video.id,
                      ),
                      onChanged: (checked) => checked == true
                          ? state.playlists.addVideo(
                              playlist.id,
                              video,
                              state.prefs,
                            )
                          : state.playlists.removeVideo(
                              playlist.id,
                              video.id,
                              state.prefs,
                            ),
                    ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.add),
                    title: Text(l10n.newPlaylist),
                    onTap: () async {
                      final title = await promptPlaylistTitle(context);
                      if (title == null || title.isEmpty) return;
                      final playlist = await state.playlists.create(
                        title,
                        state.prefs,
                      );
                      await state.playlists.addVideo(
                        playlist.id,
                        video,
                        state.prefs,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.done),
          ),
        ],
      );
    },
  );
}
