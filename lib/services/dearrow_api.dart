import '../models/search_filter.dart';
import '../models/youtube_route.dart';
import '../models/video_info.dart';
import '../state/settings_store.dart';
import '../utils/debug_log.dart';
import 'dearrow.dart';
import 'youtube_api.dart';

class DeArrowApi implements YouTubeApi {
  final YouTubeApi inner;
  final DeArrowClient client;
  final SettingsStore settings;

  DeArrowApi({
    required this.inner,
    required this.client,
    required this.settings,
  });

  bool get _active => settings.deArrowTitles || settings.deArrowThumbnails;

  Future<VideoInfo> _apply(VideoInfo video) async {
    if (!_active) return video;
    try {
      final result = await client.branding(video.id);
      if (result == null) return video;
      return video.copyWith(
        title: settings.deArrowTitles && result.title != null
            ? result.title!
            : video.title,
        thumbnailUrl: settings.deArrowThumbnails && result.thumbnailUrl != null
            ? result.thumbnailUrl!
            : video.thumbnailUrl,
      );
    } catch (e) {
      debugLog('[dearrow] ${video.id}: branding failed: $e');
      return video;
    }
  }

  Future<List<VideoInfo>> _applyAll(List<VideoInfo> videos) async {
    if (!_active) return videos;
    return Future.wait(videos.map(_apply));
  }

  @override
  Future<List<VideoInfo>> homeFeed() => inner.homeFeed().then(_applyAll);

  @override
  Future<List<VideoInfo>> trending() => inner.trending().then(_applyAll);

  @override
  Future<List<String>> searchSuggestions(String query) =>
      inner.searchSuggestions(query);

  @override
  Future<YouTubeRoute?> resolveUrl(String url) => inner.resolveUrl(url);

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
  Future<CommentsResult> comments(
    String videoId, {
    String? continuation,
    CommentSort? sort,
  }) => inner.comments(videoId, continuation: continuation, sort: sort);

  @override
  Future<ChannelInfo> channel(String channelId) => inner.channel(channelId);

  @override
  Future<List<VideoInfo>> channelShorts(String channelId) =>
      inner.channelShorts(channelId);

  @override
  Future<List<PlaylistInfo>> channelPlaylists(String channelId) =>
      inner.channelPlaylists(channelId);

  @override
  Future<ChannelAbout> channelAbout(String channelId) =>
      inner.channelAbout(channelId);

  @override
  Future<List<VideoInfo>> channelSearch(String channelId, String query) =>
      inner.channelSearch(channelId, query);

  @override
  Future<String?> resolveChannel(String url) => inner.resolveChannel(url);

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

  @override
  Future<List<CaptionCue>> captions(CaptionTrack track) =>
      inner.captions(track);
}
