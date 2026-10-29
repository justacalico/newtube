import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import '../widgets/content_width.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/thumbnail.dart';
import '../../utils/feed_filter.dart';
import '../layout.dart';
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
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final state = AppScope.read(context);
    final channels = state.subscriptions.channelsInGroup(_group);
    if (channels.isEmpty) {
      setState(() {
        _videos = const [];
        _loading = false;
      });
      return;
    }
    final generation = ++_loadGeneration;
    setState(() => _loading = true);
    final fetched = <VideoInfo>[];
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
                if (!mounted || generation != _loadGeneration) return;
                fetched.addAll([
                  for (final v in list)
                    if (v.author.isEmpty)
                      v.copyWith(author: channel.name)
                    else
                      v,
                ]);
                setState(() => _videos = [...fetched]);
              })
              .catchError((_) {}),
        );
      }
      if (running.isEmpty) break;
      await Future.wait(running, eagerError: false);
      running.clear();
      if (!mounted || generation != _loadGeneration) return;
      if (queue.isEmpty) setState(() => _loading = false);
    }
    if (!mounted || generation != _loadGeneration) return;
    setState(() => _loading = false);
  }

  void _openVideo(VideoInfo video) => openWatchPage(context, video);

  void _openChannel(String channelId) => openChannelPage(context, channelId);

  Future<void> _confirmUnsubscribe(ChannelInfo channel) async {
    final state = AppScope.read(context);
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsubscribe),
        content: Text(l10n.unsubscribeConfirm(channel.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.unsubscribe),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      state.subscriptions.unsubscribe(channel.id, state.prefs);
    }
  }

  Future<void> _assignGroup(BuildContext context, ChannelInfo channel) async {
    final state = AppScope.read(context);
    final group = await showDialog<String>(
      context: context,
      builder: (context) => _GroupNameDialog(
        channel: channel,
        initial: state.subscriptions.groupOf(channel.id),
      ),
    );
    if (group == null) return;
    state.subscriptions.setGroup(
      channel.id,
      group.isEmpty ? null : group,
      state.prefs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);

    return ContentWidth(
      maxWidth: feedMaxWidth,
      child: Column(
        children: [
          PageHeader(title: l10n.navSubscriptions),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                state.subscriptions,
                state.hidden,
                state.history,
                state.settings,
              ]),
              builder: (context, _) {
                final channels = state.subscriptions.channelsInGroup(_group);
                final groups = state.subscriptions.groups;
                if (_group != null && !groups.contains(_group)) _group = null;
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
                      height: 116,
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
                      child: _loading && _videos.isEmpty
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
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
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
                    IconButton(
                      tooltip: muted ? l10n.unmute : l10n.mute,
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: const Size(32, 32),
                      ),
                      onPressed: () => state.subscriptions.setMuted(
                        channel.id,
                        !muted,
                        state.prefs,
                      ),
                      icon: Icon(
                        muted
                            ? Icons.notifications_off_outlined
                            : Icons.notifications_active,
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: Theme.of(context).textTheme.bodySmall,
                        ),
                        onPressed: () => _confirmUnsubscribe(channel),
                        child: Text(
                          l10n.unsubscribe,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

class _GroupNameDialog extends StatefulWidget {
  final ChannelInfo channel;
  final String? initial;

  const _GroupNameDialog({required this.channel, this.initial});

  @override
  State<_GroupNameDialog> createState() => _GroupNameDialogState();
}

class _GroupNameDialogState extends State<_GroupNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text('${l10n.channelGroup}: ${widget.channel.name}'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.groupName,
          helperText: l10n.noGroup,
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
