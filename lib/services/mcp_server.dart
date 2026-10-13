import '../models/video_info.dart';
import 'mcp_server_stub.dart'
    if (dart.library.io) 'mcp_server_io.dart'
    as impl;
import 'youtube_api.dart';

const mcpDefaultPort = 8642;
const mcpEndpointPath = '/mcp';
const mcpDefaultUrl = 'http://127.0.0.1:$mcpDefaultPort$mcpEndpointPath';

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

Map<String, Object?> _idSchema(String key) => {
  'type': 'object',
  'properties': {
    key: {'type': 'string'},
  },
  'required': [key],
};

final mcpToolDefinitions = <Map<String, Object?>>[
  {
    'name': 'search',
    'description': 'Search YouTube videos and channels',
    'inputSchema': {
      'type': 'object',
      'properties': {
        'query': {'type': 'string'},
      },
      'required': ['query'],
    },
  },
  {
    'name': 'home_feed',
    'description': 'List the videos on the home feed',
    'inputSchema': {'type': 'object', 'properties': <String, Object?>{}},
  },
  {
    'name': 'video_details',
    'description': 'Get details and playable streams for a video',
    'inputSchema': _idSchema('video_id'),
  },
  {
    'name': 'related_videos',
    'description': 'List videos related to a video',
    'inputSchema': _idSchema('video_id'),
  },
  {
    'name': 'channel_info',
    'description': 'Get information about a channel',
    'inputSchema': _idSchema('channel_id'),
  },
  {
    'name': 'channel_videos',
    'description': 'List videos uploaded by a channel',
    'inputSchema': _idSchema('channel_id'),
  },
  {
    'name': 'play_video',
    'description': 'Open a video in NewTube and start playback',
    'inputSchema': _idSchema('video_id'),
  },
];
