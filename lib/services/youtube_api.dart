import '../models/video_info.dart';

abstract class YouTubeApi {
  Future<List<VideoInfo>> homeFeed();
  Future<SearchResults> search(String query);
  Future<VideoDetails> videoDetails(String videoId);
  Future<List<VideoInfo>> relatedVideos(String videoId);
  Future<ChannelInfo> channel(String channelId);
  Future<List<VideoInfo>> channelVideos(String channelId);
}
