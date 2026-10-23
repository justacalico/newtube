import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../utils/relative_date.dart';
import '../../state/app_state.dart';
import '../widgets/content_width.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/video_list_tile.dart';
import 'watch_page.dart';

enum _WatchLaterSort { added, newest, longest }

class WatchLaterPage extends StatefulWidget {
  const WatchLaterPage({super.key});

  @override
  State<WatchLaterPage> createState() => _WatchLaterPageState();
}

class _WatchLaterPageState extends State<WatchLaterPage> {
  _WatchLaterSort _sort = _WatchLaterSort.added;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = AppScope.read(context);
    return ContentWidth(
      maxWidth: 720,
      child: Column(
        children: [
          PageHeader(title: l10n.navWatchLater),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([state.watchLater, state.history]),
              builder: (context, _) {
                var videos = state.watchLater.videos;
                if (videos.isEmpty) {
                  return EmptyState(
                    icon: Icons.watch_later_outlined,
                    title: l10n.watchLaterEmpty,
                  );
                }
                final ordered = switch (_sort) {
                  _WatchLaterSort.added => videos,
                  _WatchLaterSort.newest =>
                    [...videos]..sort((a, b) {
                      final ad = parseRelativeDate(a.uploaded) ?? DateTime(0);
                      final bd = parseRelativeDate(b.uploaded) ?? DateTime(0);
                      return bd.compareTo(ad);
                    }),
                  _WatchLaterSort.longest =>
                    [...videos]..sort(
                      (a, b) => (b.duration ?? Duration.zero).compareTo(
                        a.duration ?? Duration.zero,
                      ),
                    ),
                };
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          DropdownButton<_WatchLaterSort>(
                            value: _sort,
                            underline: const SizedBox.shrink(),
                            items: [
                              DropdownMenuItem(
                                value: _WatchLaterSort.added,
                                child: Text(l10n.sortAdded),
                              ),
                              DropdownMenuItem(
                                value: _WatchLaterSort.newest,
                                child: Text(l10n.sortNewest),
                              ),
                              DropdownMenuItem(
                                value: _WatchLaterSort.longest,
                                child: Text(l10n.sortLongest),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _sort = v ?? _sort),
                          ),
                          const Spacer(),
                          Text(
                            l10n.videoCount(videos.length),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _sort == _WatchLaterSort.added
                          ? ReorderableListView.builder(
                              itemCount: videos.length,
                              itemBuilder: (context, index) {
                                final video = videos[index];
                                return _WatchLaterTile(
                                  key: ValueKey(video.id),
                                  video: video,
                                  progress: _progress(state, video),
                                  onTap: () => openWatchPage(context, video),
                                );
                              },
                              onReorderItem: (from, to) =>
                                  state.watchLater.move(from, to, state.prefs),
                            )
                          : ListView.builder(
                              itemCount: ordered.length,
                              itemBuilder: (context, index) {
                                final video = ordered[index];
                                return _WatchLaterTile(
                                  key: ValueKey(video.id),
                                  video: video,
                                  progress: _progress(state, video),
                                  onTap: () => openWatchPage(context, video),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _progress(AppState state, VideoInfo video) {
    final pos = state.history.positionFor(video.id);
    final dur = video.duration;
    if (pos == null || dur == null || dur == Duration.zero) return 0;
    return (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
  }
}

class _WatchLaterTile extends StatelessWidget {
  final VideoInfo video;
  final double progress;
  final VoidCallback onTap;

  const _WatchLaterTile({
    super.key,
    required this.video,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      VideoListTile(video: video, onTap: onTap),
      if (progress > 0) LinearProgressIndicator(value: progress, minHeight: 2),
    ],
  );
}
