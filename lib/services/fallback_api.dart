import '../models/search_filter.dart';
import '../models/video_info.dart';
import '../models/youtube_route.dart';
import '../utils/debug_log.dart';
import 'youtube_api.dart';

class FallbackApi implements YouTubeApi {
  final YouTubeApi primary;
  final YouTubeApi fallback;

  const FallbackApi(this.primary, this.fallback);

  Future<T> _try<T>(Future<T> Function(YouTubeApi api) call) async {
    try {
      return await call(primary);
    } catch (e) {
      debugLog('[api] primary failed, falling back: $e');
      return call(fallback);
    }
  }

  @override
  Future<List<VideoInfo>> homeFeed() => _try((a) => a.homeFeed());

  @override
  Future<List<VideoInfo>> trending() => _try((a) => a.trending());

  @override
  Future<SearchResults> search(String query, {SearchFilter? filter}) =>
      _try((a) => a.search(query, filter: filter));

  @override
  Future<YouTubeRoute?> resolveUrl(String url) =>
      _try((a) => a.resolveUrl(url));

  @override
  Future<List<String>> searchSuggestions(String query) =>
      _try((a) => a.searchSuggestions(query));

  @override
  Future<VideoDetails> videoDetails(String videoId) =>
      _try((a) => a.videoDetails(videoId));

  @override
  Future<List<VideoInfo>> relatedVideos(String videoId) =>
      _try((a) => a.relatedVideos(videoId));

  @override
  Future<CommentsResult> comments(
    String videoId, {
    String? continuation,
    CommentSort? sort,
  }) =>
      _try((a) => a.comments(videoId, continuation: continuation, sort: sort));

  @override
  Future<ChannelInfo> channel(String channelId) =>
      _try((a) => a.channel(channelId));

  @override
  Future<List<VideoInfo>> channelShorts(String channelId) =>
      _try((a) => a.channelShorts(channelId));

  @override
  Future<List<PlaylistInfo>> channelPlaylists(String channelId) =>
      _try((a) => a.channelPlaylists(channelId));

  @override
  Future<ChannelAbout> channelAbout(String channelId) =>
      _try((a) => a.channelAbout(channelId));

  @override
  Future<List<VideoInfo>> channelSearch(String channelId, String query) =>
      _try((a) => a.channelSearch(channelId, query));

  @override
  Future<PlaylistInfo> playlist(String playlistId, {String? continuation}) =>
      _try((a) => a.playlist(playlistId, continuation: continuation));

  @override
  Future<String?> resolveChannel(String url) =>
      _try((a) => a.resolveChannel(url));

  @override
  Future<List<VideoInfo>> channelVideos(String channelId) =>
      _try((a) => a.channelVideos(channelId));

  @override
  Future<List<CaptionCue>> captions(CaptionTrack track) =>
      _try((a) => a.captions(track));
}
