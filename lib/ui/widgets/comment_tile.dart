import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../pages/channel_page.dart';
import 'thumbnail.dart';

class CommentTile extends StatelessWidget {
  final CommentInfo comment;

  const CommentTile({super.key, required this.comment});

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
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.text),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.thumb_up_outlined, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${comment.likeCount}',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
