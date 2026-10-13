class VideoInfo {
  final String id;
  final String title;
  final String author;
  final String channelId;
  final String? thumbnailUrl;
  final Duration? duration;
  final int viewCount;
  final String? uploaded;

  const VideoInfo({
    required this.id,
    required this.title,
    required this.author,
    required this.channelId,
    this.thumbnailUrl,
    this.duration,
    this.viewCount = 0,
    this.uploaded,
  });

  VideoInfo copyWith({
    String? id,
    String? title,
    String? author,
    String? channelId,
    String? thumbnailUrl,
    Duration? duration,
    int? viewCount,
    String? uploaded,
  }) => VideoInfo(
    id: id ?? this.id,
    title: title ?? this.title,
    author: author ?? this.author,
    channelId: channelId ?? this.channelId,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    duration: duration ?? this.duration,
    viewCount: viewCount ?? this.viewCount,
    uploaded: uploaded ?? this.uploaded,
  );
}

class VideoChapter {
  final Duration start;
  final String title;

  const VideoChapter({required this.start, required this.title});
}

class ChannelInfo {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final int? subscribers;

  const ChannelInfo({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.subscribers,
  });
}

class PlayableStream {
  final String url;
  final String quality;
  final bool hasVideo;
  final bool hasAudio;
  final String? container;
  final String? audioLanguage;
  final String? audioTrackName;
  final bool isDefaultAudio;

  const PlayableStream({
    required this.url,
    required this.quality,
    this.hasVideo = true,
    this.hasAudio = true,
    this.container,
    this.audioLanguage,
    this.audioTrackName,
    this.isDefaultAudio = true,
  });
}

class VideoDetails {
  final VideoInfo info;
  final String description;
  final List<PlayableStream> streams;

  const VideoDetails({
    required this.info,
    required this.description,
    required this.streams,
  });
}

class SearchResults {
  final List<VideoInfo> videos;
  final List<ChannelInfo> channels;
  final List<PlaylistInfo> playlists;

  const SearchResults({
    this.videos = const [],
    this.channels = const [],
    this.playlists = const [],
  });
}

class CommentInfo {
  final String author;
  final String? channelId;
  final String text;
  final int likeCount;
  final String? published;
  final String? avatarUrl;
  final int replyCount;
  final bool pinned;
  final bool hearted;

  const CommentInfo({
    required this.author,
    this.channelId,
    required this.text,
    this.likeCount = 0,
    this.published,
    this.avatarUrl,
    this.replyCount = 0,
    this.pinned = false,
    this.hearted = false,
  });
}

class CommentsResult {
  final List<CommentInfo> comments;
  final String? continuation;

  const CommentsResult({this.comments = const [], this.continuation});
}

class PlaylistInfo {
  final String id;
  final String title;
  final String author;
  final String? thumbnailUrl;
  final int videoCount;
  final List<VideoInfo> videos;

  const PlaylistInfo({
    required this.id,
    required this.title,
    this.author = '',
    this.thumbnailUrl,
    this.videoCount = 0,
    this.videos = const [],
  });
}
