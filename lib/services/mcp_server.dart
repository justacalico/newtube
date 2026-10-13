import '../models/video_info.dart';
import 'mcp_server_stub.dart'
    if (dart.library.io) 'mcp_server_io.dart'
    as impl;
import 'youtube_api.dart';

abstract class McpServer {
  bool get running;
  String? get url;

  Future<void> start();
  Future<void> stop();
}

typedef McpServerFactory = McpServer Function({
  required YouTubeApi api,
  required String version,
  void Function(VideoInfo video)? onPlayVideo,
});

// coverage:ignore-start
McpServer createMcpServer({
  required YouTubeApi api,
  required String version,
  void Function(VideoInfo video)? onPlayVideo,
}) => impl.createMcpServer(
  api: api,
  version: version,
  onPlayVideo: onPlayVideo,
);
// coverage:ignore-end

class UnsupportedMcpServer implements McpServer {
  @override
  bool get running => false;
  @override
  String? get url => null;

  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
}
