// coverage:ignore-file
import '../models/video_info.dart';
import 'mcp_server.dart';
import 'youtube_api.dart';

McpServer createMcpServer({
  required YouTubeApi api,
  required String version,
  void Function(VideoInfo video)? onPlayVideo,
}) => UnsupportedMcpServer();
