import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../widgets/video_list_tile.dart';
import 'watch_page.dart';

class WatchLaterPage extends StatelessWidget {
  const WatchLaterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = AppScope.read(context);
    return ListenableBuilder(
      listenable: state.watchLater,
      builder: (context, _) {
        final videos = state.watchLater.videos;
        if (videos.isEmpty) {
          return Center(child: Text(l10n.watchLaterEmpty));
        }
        return ListView.builder(
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return VideoListTile(
              video: video,
              onTap: () => openWatchPage(context, video),
            );
          },
        );
      },
    );
  }
}
