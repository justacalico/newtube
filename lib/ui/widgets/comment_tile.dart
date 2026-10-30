import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../pages/channel_page.dart';
import 'thumbnail.dart';

class CommentTile extends StatelessWidget {
  final CommentInfo comment;
  final String? videoId;

  const CommentTile({super.key, required this.comment, this.videoId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final channelId = comment.channelId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VideoThumbnail(
            url: comment.avatarUrl,
            width: 32,
            height: 32,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    channelId == null
                        ? Text(
                            comment.author,
                            style: theme.textTheme.titleSmall,
                          )
                        : InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () => openChannelPage(context, channelId),
                            child: Text(
                              comment.author,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                    if (comment.published != null)
                      Text(
                        comment.published!,
                        style: theme.textTheme.bodySmall,
                      ),
                    if (comment.pinned)
                      Icon(
                        Icons.push_pin,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    if (comment.hearted)
                      Icon(
                        Icons.favorite,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    if (comment.isOwner)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.creator,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                SelectableText(comment.text),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.thumb_up_outlined, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      formatViewCount(comment.likeCount, l10n.localeName),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (comment.replyCount > 0) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.comment_outlined, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        l10n.replyCount(comment.replyCount),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
                if (comment.replyContinuation != null)
                  _Replies(comment: comment, videoId: videoId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Replies extends StatefulWidget {
  final CommentInfo comment;
  final String? videoId;

  const _Replies({required this.comment, this.videoId});

  @override
  State<_Replies> createState() => _RepliesState();
}

class _RepliesState extends State<_Replies> {
  List<CommentInfo>? _replies;
  var _loading = false;
  var _expanded = false;

  Future<void> _toggle() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }
    if (_replies != null) {
      setState(() => _expanded = true);
      return;
    }
    final videoId = widget.videoId;
    final token = widget.comment.replyContinuation;
    if (videoId == null || token == null) return;
    setState(() => _loading = true);
    try {
      final result = await AppScope.read(context).api
          .comments(videoId, continuation: token);
      if (!mounted) return;
      setState(() {
        _replies = result.comments;
        _loading = false;
        _expanded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          icon: _loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                ),
          label: Text(
            _expanded ? l10n.hideReplies : l10n.showReplies,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          onPressed: _toggle,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: [
                for (final reply in _replies ?? const <CommentInfo>[])
                  CommentTile(comment: reply, videoId: widget.videoId),
              ],
            ),
          ),
      ],
    );
  }
}
