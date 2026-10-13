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
  final String? audioLanguage;
  final String? audioTrackName;
  final bool isDefaultAudio;

  const PlayableStream({
    required this.url,
    required this.quality,
    this.hasVideo = true,
    this.hasAudio = true,
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

  const SearchResults({this.videos = const [], this.channels = const []});
}
