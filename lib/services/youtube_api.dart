import '../models/search_filter.dart';
import '../models/youtube_route.dart';
import '../models/video_info.dart';

abstract class YouTubeApi {
  Future<List<VideoInfo>> homeFeed();
  Future<List<VideoInfo>> trending();
  Future<SearchResults> search(String query, {SearchFilter? filter});
  Future<YouTubeRoute?> resolveUrl(String url);
  Future<List<String>> searchSuggestions(String query);
  Future<VideoDetails> videoDetails(String videoId);
  Future<List<VideoInfo>> relatedVideos(String videoId);
  Future<CommentsResult> comments(
    String videoId, {
    String? continuation,
    CommentSort? sort,
  });
  Future<ChannelInfo> channel(String channelId);
  Future<PlaylistInfo> playlist(String playlistId);
  Future<String?> resolveChannel(String url);
  Future<List<VideoInfo>> channelVideos(String channelId);
  Future<List<CaptionCue>> captions(CaptionTrack track);
}
