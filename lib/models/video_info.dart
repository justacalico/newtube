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

  const PlayableStream({
    required this.url,
    required this.quality,
    this.hasVideo = true,
    this.hasAudio = true,
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
