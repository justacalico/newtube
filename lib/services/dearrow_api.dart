import '../models/search_filter.dart';
import '../models/video_info.dart';
import '../state/settings_store.dart';
import '../utils/debug_log.dart';
import 'dearrow.dart';
import 'forwarding_api.dart';
import 'youtube_api.dart';

class DeArrowApi extends ForwardingYouTubeApi {
  final DeArrowClient client;
  final SettingsStore settings;

  DeArrowApi({
    required YouTubeApi inner,
    required this.client,
    required this.settings,
  }) : super(inner);

  bool get _active => settings.deArrowTitles || settings.deArrowThumbnails;

  Future<VideoInfo> _apply(VideoInfo video) async {
    if (!_active) return video;
    try {
      final result = await client.branding(video.id);
      if (result == null) return video;
      return video.copyWith(
        title: settings.deArrowTitles && result.title != null
            ? result.title!
            : null,
        thumbnailUrl: settings.deArrowThumbnails && result.thumbnailUrl != null
            ? result.thumbnailUrl!
            : null,
      );
    } on DeArrowException catch (e) {
      debugLog('[dearrow] ${video.id}: $e');
      return video;
    }
  }

  Future<List<VideoInfo>> _applyAll(List<VideoInfo> videos) async {
    if (!_active) return videos;
    const batchSize = 8;
    final out = <VideoInfo>[];
    for (var i = 0; i < videos.length; i += batchSize) {
      final end = i + batchSize > videos.length ? videos.length : i + batchSize;
      out.addAll(
        await Future.wait([for (final v in videos.sublist(i, end)) _apply(v)]),
      );
    }
    return out;
  }

  @override
  Future<List<VideoInfo>> homeFeed() => inner.homeFeed().then(_applyAll);

  @override
  Future<List<VideoInfo>> trending() => inner.trending().then(_applyAll);

  @override
  Future<SearchResults> search(String query, {SearchFilter? filter}) async {
    final results = await inner.search(query, filter: filter);
    return SearchResults(
      videos: await _applyAll(results.videos),
      channels: results.channels,
      playlists: results.playlists,
    );
  }

  @override
  Future<VideoDetails> videoDetails(String videoId) async {
    final details = await inner.videoDetails(videoId);
    return VideoDetails(
      info: await _apply(details.info),
      description: details.description,
      streams: details.streams,
      captions: details.captions,
    );
  }

  @override
  Future<List<VideoInfo>> relatedVideos(String videoId) =>
      inner.relatedVideos(videoId).then(_applyAll);

  @override
  Future<List<PlaylistInfo>> channelPlaylists(String channelId) async {
    final playlists = await inner.channelPlaylists(channelId);
    return [
      for (final p in playlists)
        PlaylistInfo(
          id: p.id,
          title: p.title,
          author: p.author,
          thumbnailUrl: p.thumbnailUrl,
          videoCount: p.videoCount,
          videos: await _applyAll(p.videos),
          continuation: p.continuation,
        ),
    ];
  }

  @override
  Future<List<VideoInfo>> channelShorts(String channelId) =>
      inner.channelShorts(channelId).then(_applyAll);

  @override
  Future<PlaylistInfo> playlist(
    String playlistId, {
    String? continuation,
  }) async {
    final playlist = await inner.playlist(
      playlistId,
      continuation: continuation,
    );
    return PlaylistInfo(
      id: playlist.id,
      title: playlist.title,
      author: playlist.author,
      thumbnailUrl: playlist.thumbnailUrl,
      videoCount: playlist.videoCount,
      videos: await _applyAll(playlist.videos),
      continuation: playlist.continuation,
    );
  }

  @override
  Future<List<VideoInfo>> channelVideos(String channelId) =>
      inner.channelVideos(channelId).then(_applyAll);
}
