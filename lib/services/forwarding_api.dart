import '../models/search_filter.dart';
import '../models/youtube_route.dart';
import '../models/video_info.dart';
import 'youtube_api.dart';

class ForwardingYouTubeApi implements YouTubeApi {
  final YouTubeApi inner;

  const ForwardingYouTubeApi(this.inner);

  @override
  Future<List<VideoInfo>> homeFeed() => inner.homeFeed();

  @override
  Future<List<VideoInfo>> trending() => inner.trending();

  @override
  Future<SearchResults> search(String query, {SearchFilter? filter}) =>
      inner.search(query, filter: filter);

  @override
  Future<YouTubeRoute?> resolveUrl(String url) => inner.resolveUrl(url);

  @override
  Future<List<String>> searchSuggestions(String query) =>
      inner.searchSuggestions(query);

  @override
  Future<VideoDetails> videoDetails(String videoId) =>
      inner.videoDetails(videoId);

  @override
  Future<List<VideoInfo>> relatedVideos(String videoId) =>
      inner.relatedVideos(videoId);

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
  Future<PlaylistInfo> playlist(String playlistId, {String? continuation}) =>
      inner.playlist(playlistId, continuation: continuation);

  @override
  Future<String?> resolveChannel(String url) => inner.resolveChannel(url);

  @override
  Future<List<VideoInfo>> channelVideos(String channelId) =>
      inner.channelVideos(channelId);

  @override
  Future<List<CaptionCue>> captions(CaptionTrack track) =>
      inner.captions(track);
}
