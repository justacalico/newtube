import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import '../widgets/content_width.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/thumbnail.dart';
import '../../utils/feed_filter.dart';
import '../widgets/video_grid.dart';
import 'channel_page.dart';
import 'watch_page.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  List<VideoInfo> _videos = const [];
  String? _group;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final state = AppScope.read(context);
    final channels = state.subscriptions.channels;
    if (channels.isEmpty) return;
    setState(() {
      _loading = true;
      _videos = const [];
    });
    const limit = 4;
    final queue = [...channels];
    final running = <Future<void>>[];
    while (queue.isNotEmpty || running.isNotEmpty) {
      while (queue.isNotEmpty && running.length < limit) {
        final channel = queue.removeAt(0);
        running.add(
          state.api
              .channelVideos(channel.id)
              .then((list) {
                if (!mounted) return;
                setState(
                  () => _videos = [
                    ..._videos,
                    for (final v in list)
                      if (v.author.isEmpty)
                        v.copyWith(author: channel.name)
                      else
                        v,
                  ],
                );
              })
              .catchError((_) {}),
        );
      }
      if (running.isEmpty) break;
      await Future.wait(running, eagerError: false);
      running.clear();
      if (!mounted) return;
      if (queue.isEmpty) setState(() => _loading = false);
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _openVideo(VideoInfo video) => openWatchPage(context, video);

  void _openChannel(String channelId) => openChannelPage(context, channelId);

  void _assignGroup(BuildContext context, ChannelInfo channel) {
    final state = AppScope.read(context);
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: state.subscriptions.groupOf(channel.id) ?? '',
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.channelGroup}: ${channel.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.groupName,
            helperText: l10n.noGroup,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              state.subscriptions.setGroup(
                channel.id,
                controller.text.trim().isEmpty ? null : controller.text.trim(),
                state.prefs,
              );
              Navigator.of(context).pop();
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);

    return ContentWidth(
      maxWidth: 1280,
      child: Column(
        children: [
          PageHeader(title: l10n.navSubscriptions),
          Expanded(
            child: ListenableBuilder(
              listenable: state.subscriptions,
              builder: (context, _) {
                final channels = state.subscriptions.channelsInGroup(_group);
                final groups = state.subscriptions.groups;
                if (channels.isEmpty) {
                  return EmptyState(
                    icon: Icons.subscriptions_outlined,
                    title: l10n.noSubscriptions,
                    hint: l10n.noSubscriptionsHint,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (groups.isNotEmpty)
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(l10n.allChannels),
                                selected: _group == null,
                                onSelected: (_) => setState(() {
                                  _group = null;
                                  _loadVideos();
                                }),
                              ),
                            ),
                            for (final g in groups)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(g),
                                  selected: _group == g,
                                  onSelected: (sel) => setState(() {
                                    _group = sel ? g : null;
                                    _loadVideos();
                                  }),
                                ),
                              ),
                          ],
                        ),
                      ),
                    SizedBox(
                      height: 112,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        children: [
                          for (final channel in channels) _channelItem(channel),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l10n.latestFromSubscriptions,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : RefreshIndicator(
                              onRefresh: _loadVideos,
                              child: VideoGrid(
                                videos: visibleVideos(
                                  _videos,
                                  state.settings,
                                  state,
                                ),
                                onVideoTap: _openVideo,
                              ),
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

  Widget _channelItem(ChannelInfo channel) {
    final state = AppScope.read(context);
    final l10n = AppLocalizations.of(context);
    final muted = state.subscriptions.isMuted(channel.id);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openChannel(channel.id),
          onLongPress: () => _assignGroup(context, channel),
          child: SizedBox(
            width: 112,
            child: Column(
              children: [
                VideoThumbnail(
                  url: channel.thumbnailUrl,
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(24),
                  placeholderIcon: Icons.person_outline,
                ),
                const SizedBox(height: 4),
                Text(
                  channel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => state.subscriptions.setMuted(
                        channel.id,
                        !muted,
                        state.prefs,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          muted
                              ? Icons.notifications_off_outlined
                              : Icons.notifications_active,
                          size: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => state.subscriptions.unsubscribe(
                          channel.id,
                          state.prefs,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          child: Text(
                            l10n.unsubscribe,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
